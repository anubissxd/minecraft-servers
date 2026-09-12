# AnuDownloader - incremental modpack updater/installer
# Shows a list of available modpacks, lets the user pick a target mods folder,
# and only downloads files that are new or changed vs what's already there.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ConfigDir   = Join-Path $env:APPDATA "AnuDownloader"
$ConfigFile  = Join-Path $ConfigDir "config.json"
$IndexUrl    = "https://raw.githubusercontent.com/anubissxd/minecraft-servers/main/distribution/index.json"

if (-not (Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir | Out-Null }

function Load-Config {
    if (Test-Path $ConfigFile) {
        try { return Get-Content $ConfigFile -Raw | ConvertFrom-Json } catch { return $null }
    }
    return $null
}

function Save-Config($cfg) {
    $cfg | ConvertTo-Json -Depth 5 | Set-Content -Path $ConfigFile -Encoding UTF8
}

function Get-FileSha256($path) {
    (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower()
}

$cfg = Load-Config
if (-not $cfg) { $cfg = @{ folders = @{} } }
if (-not $cfg.folders) { $cfg | Add-Member -NotePropertyName folders -NotePropertyValue @{} -Force }

# ---------- Main window ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "AnuDownloader"
$form.Size = New-Object System.Drawing.Size(680, 480)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$lblPacks = New-Object System.Windows.Forms.Label
$lblPacks.Text = "Mod Paketleri:"
$lblPacks.Location = New-Object System.Drawing.Point(10, 10)
$lblPacks.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($lblPacks)

$lstPacks = New-Object System.Windows.Forms.ListBox
$lstPacks.Location = New-Object System.Drawing.Point(10, 32)
$lstPacks.Size = New-Object System.Drawing.Size(200, 380)
$form.Controls.Add($lstPacks)

$lblDesc = New-Object System.Windows.Forms.Label
$lblDesc.Location = New-Object System.Drawing.Point(220, 10)
$lblDesc.Size = New-Object System.Drawing.Size(440, 40)
$form.Controls.Add($lblDesc)

$lblFolder = New-Object System.Windows.Forms.Label
$lblFolder.Text = "Mods klasoru:"
$lblFolder.Location = New-Object System.Drawing.Point(220, 55)
$lblFolder.Size = New-Object System.Drawing.Size(90, 20)
$form.Controls.Add($lblFolder)

$txtFolder = New-Object System.Windows.Forms.TextBox
$txtFolder.Location = New-Object System.Drawing.Point(220, 76)
$txtFolder.Size = New-Object System.Drawing.Size(330, 20)
$txtFolder.ReadOnly = $true
$form.Controls.Add($txtFolder)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Sec..."
$btnBrowse.Location = New-Object System.Drawing.Point(560, 74)
$btnBrowse.Size = New-Object System.Drawing.Size(90, 24)
$form.Controls.Add($btnBrowse)

$lstLog = New-Object System.Windows.Forms.ListBox
$lstLog.Location = New-Object System.Drawing.Point(220, 106)
$lstLog.Size = New-Object System.Drawing.Size(430, 260)
$lstLog.Font = New-Object System.Drawing.Font("Consolas", 8)
$form.Controls.Add($lstLog)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(220, 372)
$progress.Size = New-Object System.Drawing.Size(430, 20)
$form.Controls.Add($progress)

$btnUpdate = New-Object System.Windows.Forms.Button
$btnUpdate.Text = "Kur / Guncelle"
$btnUpdate.Location = New-Object System.Drawing.Point(220, 398)
$btnUpdate.Size = New-Object System.Drawing.Size(430, 32)
$btnUpdate.Enabled = $false
$form.Controls.Add($btnUpdate)

function Log($msg) {
    $lstLog.Items.Add($msg) | Out-Null
    $lstLog.TopIndex = $lstLog.Items.Count - 1
    [System.Windows.Forms.Application]::DoEvents()
}

$script:packs = @()
$script:selectedPack = $null

try {
    $index = Invoke-RestMethod -Uri $IndexUrl -Headers @{ "Cache-Control" = "no-cache" }
    $script:packs = $index.packs
    foreach ($p in $script:packs) {
        $lstPacks.Items.Add($p.name) | Out-Null
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Paket listesi indirilemedi:`n$($_.Exception.Message)", "AnuDownloader") | Out-Null
}

$lstPacks.Add_SelectedIndexChanged({
    if ($lstPacks.SelectedIndex -lt 0) { return }
    $script:selectedPack = $script:packs[$lstPacks.SelectedIndex]
    $lblDesc.Text = $script:selectedPack.description
    $btnUpdate.Enabled = $true

    $saved = $cfg.folders.($script:selectedPack.id)
    if ($saved -and (Test-Path $saved)) {
        $txtFolder.Text = $saved
    } else {
        $txtFolder.Text = ""
    }
})

$btnBrowse.Add_Click({
    if (-not $script:selectedPack) { return }
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "$($script:selectedPack.name) icin 'mods' klasorunu sec (Modrinth, CurseForge veya TLauncher)"
    if ($dlg.ShowDialog() -eq "OK") {
        $txtFolder.Text = $dlg.SelectedPath
    }
})

$btnUpdate.Add_Click({
    $lstLog.Items.Clear()
    $progress.Value = 0

    if (-not $script:selectedPack) { return }
    if ([string]::IsNullOrWhiteSpace($txtFolder.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Once mods klasorunu sec.", "AnuDownloader") | Out-Null
        return
    }
    $modsFolder = $txtFolder.Text
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

    Log "Versiyon: $($manifest.version)  Dosya sayisi: $($manifest.files.Count)"

    $toDownload = @()
    foreach ($f in $manifest.files) {
        $localPath = Join-Path $modsFolder $f.filename
        if (-not (Test-Path -LiteralPath $localPath)) {
            $toDownload += $f
            continue
        }
        $localHash = Get-FileSha256 $localPath
        if ($localHash -ne $f.sha256) {
            $toDownload += $f
        }
    }

    $manifestNames = $manifest.files | ForEach-Object { $_.filename }
    $localJars = Get-ChildItem -Path $modsFolder -Filter *.jar -File -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
    $extra = $localJars | Where-Object { $manifestNames -notcontains $_ }

    if ($toDownload.Count -eq 0) {
        Log "Her sey guncel, indirilecek dosya yok."
    } else {
        Log "$($toDownload.Count) dosya indirilecek."
        $progress.Maximum = $toDownload.Count
        $i = 0
        foreach ($f in $toDownload) {
            $i++
            $dest = Join-Path $modsFolder $f.filename
            Log "[$i/$($toDownload.Count)] $($f.filename) indiriliyor..."
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
        Log ""
        Log "Not: pakette olmayan $($extra.Count) ekstra dosya var (dokunulmadi):"
        foreach ($e in $extra) { Log "  - $e" }
    }

    $cfg.folders | Add-Member -NotePropertyName $script:selectedPack.id -NotePropertyValue $modsFolder -Force
    Save-Config $cfg
    [System.Windows.Forms.MessageBox]::Show("Islem bitti.", "AnuDownloader") | Out-Null
})

[void]$form.ShowDialog()
