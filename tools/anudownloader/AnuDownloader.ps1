# AnuDownloader - incremental modpack installer/updater
# Shows available modpacks as banner tiles, auto-detects installed launchers
# (Modrinth / CurseForge / TLauncher) across any drive, and only downloads
# files that are new or changed vs what's already on disk.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ConfigDir  = Join-Path $env:APPDATA "AnuDownloader"
$ConfigFile = Join-Path $ConfigDir "config.json"
$IndexUrl   = "https://raw.githubusercontent.com/anubissxd/minecraft-servers/main/distribution/index.json"
$CacheDir   = Join-Path $ConfigDir "cache"

foreach ($d in @($ConfigDir, $CacheDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Load-Config {
    if (Test-Path $ConfigFile) {
        try { return Get-Content $ConfigFile -Raw | ConvertFrom-Json } catch { return $null }
    }
    return $null
}
function Save-Config($cfg) {
    $cfg | ConvertTo-Json -Depth 6 | Set-Content -Path $ConfigFile -Encoding UTF8
}
function Get-FileSha256($path) {
    (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower()
}

$cfg = Load-Config
if (-not $cfg) { $cfg = [PSCustomObject]@{ targets = @{} } }
if (-not ($cfg.PSObject.Properties.Name -contains 'targets')) {
    $cfg | Add-Member -NotePropertyName targets -NotePropertyValue @{} -Force
}

# ---------- Launcher auto-detection ----------
function Get-FixedDrives {
    Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Za-z]:\\$' } | ForEach-Object { $_.Root }
}

function Find-LauncherTargets([string]$folderName) {
    $results = @()

    # Modrinth App - always under the current user's APPDATA (which already
    # resolves to whichever drive the user profile lives on)
    $mr = Join-Path $env:APPDATA "ModrinthApp\profiles\$folderName\mods"
    if (Test-Path $mr) {
        $results += [PSCustomObject]@{ Launcher = "Modrinth"; Path = $mr }
    }

    # TLauncher - normally reuses the vanilla .minecraft folder directly
    $tl = Join-Path $env:APPDATA ".minecraft\mods"
    if (Test-Path $tl) {
        $results += [PSCustomObject]@{ Launcher = "TLauncher / Vanilla (.minecraft)"; Path = $tl }
    }

    # CurseForge - install root is user-configurable, can be on any drive.
    # Try the common default first, then sweep top-level folders on every
    # fixed drive for a "curseforge\minecraft\Instances" layout.
    $cfCandidates = @()
    $cfCandidates += (Join-Path $env:USERPROFILE "curseforge\minecraft\Instances\$folderName\mods")

    foreach ($drive in (Get-FixedDrives)) {
        $patterns = @(
            (Join-Path $drive "curseforge\minecraft\Instances\$folderName\mods"),
            (Join-Path $drive "CurseForge\minecraft\Instances\$folderName\mods"),
            (Join-Path $drive "Games\curseforge\minecraft\Instances\$folderName\mods"),
            (Join-Path $drive "Users\$env:USERNAME\curseforge\minecraft\Instances\$folderName\mods")
        )
        $cfCandidates += $patterns
    }

    foreach ($c in ($cfCandidates | Select-Object -Unique)) {
        if (Test-Path $c) {
            $results += [PSCustomObject]@{ Launcher = "CurseForge"; Path = $c }
        }
    }

    return $results | Sort-Object Path -Unique
}

# ---------- Image caching (banners) ----------
function Get-CachedImage([string]$url) {
    if ([string]::IsNullOrWhiteSpace($url)) { return $null }
    $name = [System.IO.Path]::GetFileName(([uri]$url).AbsolutePath)
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($url))).Replace("-","")
    $local = Join-Path $CacheDir "$hash-$name"
    if (-not (Test-Path $local)) {
        try { Invoke-WebRequest -Uri $url -OutFile $local -UseBasicParsing } catch { return $null }
    }
    try { return [System.Drawing.Image]::FromFile($local) } catch { return $null }
}

# ================= UI =================
$form = New-Object System.Windows.Forms.Form
$form.Text = "AnuDownloader"
$form.Size = New-Object System.Drawing.Size(760, 620)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(24,24,27)

$headerLabel = New-Object System.Windows.Forms.Label
$headerLabel.Text = "AnuDownloader"
$headerLabel.ForeColor = [System.Drawing.Color]::White
$headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$headerLabel.Location = New-Object System.Drawing.Point(20, 15)
$headerLabel.AutoSize = $true
$form.Controls.Add($headerLabel)

$subLabel = New-Object System.Windows.Forms.Label
$subLabel.Text = "Bir mod paketi sec"
$subLabel.ForeColor = [System.Drawing.Color]::FromArgb(180,180,180)
$subLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subLabel.Location = New-Object System.Drawing.Point(22, 48)
$subLabel.AutoSize = $true
$form.Controls.Add($subLabel)

$panelPacks = New-Object System.Windows.Forms.FlowLayoutPanel
$panelPacks.Location = New-Object System.Drawing.Point(20, 75)
$panelPacks.Size = New-Object System.Drawing.Size(710, 200)
$panelPacks.BackColor = [System.Drawing.Color]::FromArgb(24,24,27)
$panelPacks.AutoScroll = $true
$form.Controls.Add($panelPacks)

$grpTarget = New-Object System.Windows.Forms.GroupBox
$grpTarget.Text = "Kurulum Hedefi"
$grpTarget.ForeColor = [System.Drawing.Color]::White
$grpTarget.Location = New-Object System.Drawing.Point(20, 290)
$grpTarget.Size = New-Object System.Drawing.Size(710, 150)
$form.Controls.Add($grpTarget)

$panelTargets = New-Object System.Windows.Forms.FlowLayoutPanel
$panelTargets.Location = New-Object System.Drawing.Point(10, 22)
$panelTargets.Size = New-Object System.Drawing.Size(690, 90)
$panelTargets.FlowDirection = "TopDown"
$panelTargets.AutoScroll = $true
$grpTarget.Controls.Add($panelTargets)

$btnOther = New-Object System.Windows.Forms.Button
$btnOther.Text = "Diger (klasor sec)..."
$btnOther.Location = New-Object System.Drawing.Point(10, 116)
$btnOther.Size = New-Object System.Drawing.Size(180, 26)
$grpTarget.Controls.Add($btnOther)

$txtChosen = New-Object System.Windows.Forms.Label
$txtChosen.Location = New-Object System.Drawing.Point(200, 120)
$txtChosen.Size = New-Object System.Drawing.Size(490, 20)
$txtChosen.ForeColor = [System.Drawing.Color]::FromArgb(150,220,150)
$grpTarget.Controls.Add($txtChosen)

$lstLog = New-Object System.Windows.Forms.ListBox
$lstLog.Location = New-Object System.Drawing.Point(20, 450)
$lstLog.Size = New-Object System.Drawing.Size(710, 90)
$lstLog.Font = New-Object System.Drawing.Font("Consolas", 8)
$form.Controls.Add($lstLog)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20, 548)
$progress.Size = New-Object System.Drawing.Size(710, 18)
$form.Controls.Add($progress)

$btnUpdate = New-Object System.Windows.Forms.Button
$btnUpdate.Text = "Kur / Guncelle"
$btnUpdate.Location = New-Object System.Drawing.Point(20, 572)
$btnUpdate.Size = New-Object System.Drawing.Size(710, 32)
$btnUpdate.Enabled = $false
$btnUpdate.BackColor = [System.Drawing.Color]::FromArgb(46,125,50)
$btnUpdate.ForeColor = [System.Drawing.Color]::White
$btnUpdate.FlatStyle = "Flat"
$form.Controls.Add($btnUpdate)

function Log($msg) {
    $lstLog.Items.Add($msg) | Out-Null
    $lstLog.TopIndex = $lstLog.Items.Count - 1
    [System.Windows.Forms.Application]::DoEvents()
}

$script:packs = @()
$script:selectedPack = $null
$script:selectedTarget = $null
$script:targetButtons = @()

function Select-PackTile($tile, $pack) {
    foreach ($t in $panelPacks.Controls) {
        if ($t -is [System.Windows.Forms.Panel]) { $t.BackColor = [System.Drawing.Color]::FromArgb(40,40,45) }
    }
    $tile.BackColor = [System.Drawing.Color]::FromArgb(60,90,60)
    $script:selectedPack = $pack

    $panelTargets.Controls.Clear()
    $script:targetButtons = @()
    $script:selectedTarget = $null
    $txtChosen.Text = ""
    $btnUpdate.Enabled = $false

    $found = Find-LauncherTargets $pack.folder_name
    if ($found.Count -eq 0) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = "Otomatik kurulum bulunamadi. 'Diger' ile klasor sec."
        $lbl.ForeColor = [System.Drawing.Color]::Gray
        $lbl.AutoSize = $true
        $panelTargets.Controls.Add($lbl)
    } else {
        foreach ($f in $found) {
            $rb = New-Object System.Windows.Forms.RadioButton
            $rb.Text = "$($f.Launcher):  $($f.Path)"
            $rb.AutoSize = $true
            $rb.Tag = $f.Path
            $rb.Add_CheckedChanged({
                if ($this.Checked) {
                    $script:selectedTarget = $this.Tag
                    $txtChosen.Text = "Secili: $($this.Tag)"
                    $btnUpdate.Enabled = $true
                }
            })
            $panelTargets.Controls.Add($rb)
            $script:targetButtons += $rb
        }
        $script:targetButtons[0].Checked = $true
    }
}

$btnOther.Add_Click({
    if (-not $script:selectedPack) {
        [System.Windows.Forms.MessageBox]::Show("Once bir paket sec.", "AnuDownloader") | Out-Null
        return
    }
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "$($script:selectedPack.name) icin 'mods' klasorunu sec"
    if ($dlg.ShowDialog() -eq "OK") {
        foreach ($rb in $script:targetButtons) { $rb.Checked = $false }
        $script:selectedTarget = $dlg.SelectedPath
        $txtChosen.Text = "Secili: $($dlg.SelectedPath)"
        $btnUpdate.Enabled = $true
    }
})

Log "Paket listesi indiriliyor..."
try {
    $index = Invoke-RestMethod -Uri $IndexUrl -Headers @{ "Cache-Control" = "no-cache" }
    $script:packs = $index.packs
} catch {
    [System.Windows.Forms.MessageBox]::Show("Paket listesi indirilemedi:`n$($_.Exception.Message)", "AnuDownloader") | Out-Null
}

foreach ($pack in $script:packs) {
    $tile = New-Object System.Windows.Forms.Panel
    $tile.Size = New-Object System.Drawing.Size(220, 190)
    $tile.BackColor = [System.Drawing.Color]::FromArgb(40,40,45)
    $tile.Margin = New-Object System.Windows.Forms.Padding(8)
    $tile.Cursor = [System.Windows.Forms.Cursors]::Hand

    $pic = New-Object System.Windows.Forms.PictureBox
    $pic.Size = New-Object System.Drawing.Size(200, 120)
    $pic.Location = New-Object System.Drawing.Point(10, 10)
    $pic.SizeMode = "Zoom"
    $pic.BackColor = [System.Drawing.Color]::FromArgb(60,60,65)
    $img = Get-CachedImage $pack.banner_url
    if ($img) { $pic.Image = $img }
    $tile.Controls.Add($pic)

    $lblName = New-Object System.Windows.Forms.Label
    $lblName.Text = $pack.name
    $lblName.ForeColor = [System.Drawing.Color]::White
    $lblName.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $lblName.Location = New-Object System.Drawing.Point(10, 135)
    $lblName.Size = New-Object System.Drawing.Size(200, 22)
    $tile.Controls.Add($lblName)

    $lblDesc = New-Object System.Windows.Forms.Label
    $lblDesc.Text = $pack.description
    $lblDesc.ForeColor = [System.Drawing.Color]::FromArgb(170,170,170)
    $lblDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $lblDesc.Location = New-Object System.Drawing.Point(10, 158)
    $lblDesc.Size = New-Object System.Drawing.Size(200, 28)
    $tile.Controls.Add($lblDesc)

    $clickHandler = { Select-PackTile $tile $pack }.GetNewClosure()
    $tile.Add_Click($clickHandler)
    $pic.Add_Click($clickHandler)
    $lblName.Add_Click($clickHandler)
    $lblDesc.Add_Click($clickHandler)

    $panelPacks.Controls.Add($tile)
}

$btnUpdate.Add_Click({
    $lstLog.Items.Clear()
    $progress.Value = 0

    if (-not $script:selectedPack -or -not $script:selectedTarget) { return }
    $modsFolder = $script:selectedTarget
    if (-not (Test-Path $modsFolder)) {
        New-Item -ItemType Directory -Path $modsFolder -Force | Out-Null
    }

    Log "Manifest indiriliyor: $($script:selectedPack.name)"
    try {
        $manifest = Invoke-RestMethod -Uri $script:selectedPack.manifest_url -Headers @{ "Cache-Control" = "no-cache" }
    } catch {
        Log "HATA: Manifest indirilemedi - $($_.Exception.Message)"
        return
    }
    Log "Dosya sayisi: $($manifest.files.Count)"

    $toDownload = @()
    foreach ($f in $manifest.files) {
        $localPath = Join-Path $modsFolder $f.filename
        if (-not (Test-Path -LiteralPath $localPath)) {
            $toDownload += $f; continue
        }
        if ((Get-FileSha256 $localPath) -ne $f.sha256) { $toDownload += $f }
    }

    $manifestNames = $manifest.files | ForEach-Object { $_.filename }
    $localJars = Get-ChildItem -Path $modsFolder -Filter *.jar -File -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
    $extra = $localJars | Where-Object { $manifestNames -notcontains $_ }

    if ($toDownload.Count -eq 0) {
        Log "Her sey guncel."
    } else {
        Log "$($toDownload.Count) dosya indirilecek."
        $progress.Maximum = $toDownload.Count
        $i = 0
        foreach ($f in $toDownload) {
            $i++
            $dest = Join-Path $modsFolder $f.filename
            Log "[$i/$($toDownload.Count)] $($f.filename)"
            try {
                Invoke-WebRequest -Uri $f.url -OutFile $dest -UseBasicParsing
                $progress.Value = $i
            } catch {
                Log "  HATA: $($_.Exception.Message)"
            }
        }
        Log "Guncelleme tamamlandi."
    }

    if ($extra.Count -gt 0) {
        Log "Not: pakette olmayan $($extra.Count) ekstra dosya var (dokunulmadi)."
    }

    $cfg.targets | Add-Member -NotePropertyName $script:selectedPack.id -NotePropertyValue $modsFolder -Force
    Save-Config $cfg
    [System.Windows.Forms.MessageBox]::Show("Islem bitti.", "AnuDownloader") | Out-Null
})

[void]$form.ShowDialog()
