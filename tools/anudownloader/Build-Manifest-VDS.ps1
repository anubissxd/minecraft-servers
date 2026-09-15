# Build-Manifest-VDS.ps1 - maintainer-side tool.
# Builds a pack manifest straight from the running server on the VDS, so the
# server is the single source of truth and no maintainer's local game folder
# can leak stale or broken files into what players download.
#
# What ships, and where it lands on the player's side:
#   <server>/mods/                      -> mods/
#   <server>/config/                    -> config/          (seeded once, see below)
#   <server>/client-extra/mods/         -> mods/            client-only mods the
#                                                           server must not load
#   <server>/client-extra/resourcepacks -> resourcepacks/
#   <server>/datapacks/                 -> datapacks/
#
# config/ is written by AnuDownloader only when the file is missing, because the
# game rewrites those files itself - see Test-AnuSeedOnlyPath in AnuDownloader.ps1.
#
# Usage:
#   .\Build-Manifest-VDS.ps1 -ServerPath "/root/servers/multiverse-superheroes" `
#       -Tag "mvsh-pack" -PackName "Multiverse Superheroes" -Version "2.0.0" `
#       -ManifestOut "..\..\distribution\mvsh\manifest.json"

param(
    [Parameter(Mandatory=$true)][string]$ServerPath,
    [Parameter(Mandatory=$true)][string]$Tag,
    [Parameter(Mandatory=$true)][string]$PackName,
    [Parameter(Mandatory=$true)][string]$ManifestOut,
    [string]$Version = (Get-Date -Format "yyyy.MM.dd-HHmm"),
    [string]$Repo = "anubissxd/minecraft-servers",
    [string]$SshHost = "root@31.58.91.7",
    [string]$SshKey = "$env:USERPROFILE\.ssh\id_ed25519"
)

$ErrorActionPreference = "Stop"

# source folder on the server -> folder the player gets it in
#
# world/datapacks holds hand-written Palladium power overrides that the server
# applies to its own world. Players get them through Forge's global_packs, so
# the same definitions are loaded in single player too and stay in sync with
# the server. Auto-generated datapacks there (visual_creative_tab_editor_*)
# are deliberately left out - the mods regenerate those themselves.
$FolderMap = [ordered]@{
    "mods"                              = "mods"
    "config"                            = "config"
    "datapacks"                         = "datapacks"
    "client-extra/mods"                 = "mods"
    "client-extra/resourcepacks"        = "resourcepacks"
    "world/datapacks/anubis_customs"    = "global_packs/required_data/anubis_customs"
}

function Invoke-Ssh([string]$command) {
    & ssh -o BatchMode=yes -i $SshKey $SshHost $command
}

function Get-AssetName([string]$relPath) {
    # GitHub rewrites characters it dislikes in an asset's name (a space or an
    # apostrophe becomes a dot), so the name must be sanitised here - otherwise
    # the manifest records a URL that never existed and the download 404s.
    # Mod filenames really do contain spaces, apostrophes and parentheses.
    ($relPath -replace '/', '__') -replace '[^A-Za-z0-9._+-]', '_'
}

Write-Host "Sunucu taraniyor: $SshHost`:$ServerPath"

# Single SSH round trip: each line is "<sha256>\t<player-side path>\t<path on server>",
# so nothing below needs to ask the server where a file came from.
$findParts = @()
foreach ($src in $FolderMap.Keys) {
    $dest = $FolderMap[$src]
    $findParts += "if [ -d '$ServerPath/$src' ]; then find '$ServerPath/$src' -type f | while IFS= read -r f; do h=`$(sha256sum `"`$f`" | cut -d' ' -f1); rel=`"`${f#$ServerPath/$src/}`"; printf '%s\t$dest/%s\t%s\n' `"`$h`" `"`$rel`" `"`$f`"; done; fi"
}
$lines = Invoke-Ssh ($findParts -join "; ")

# Runtime scratch the server writes but players must never receive. spark's
# tmp/ in particular holds profiler dumps, some of them zero bytes - and the
# GitHub asset API rejects an empty file outright, which aborts the whole build.
$ExcludedPrefixes = @("config/spark/tmp/")

$scanned = @()
$skipped = 0
foreach ($line in $lines) {
    if (-not $line) { continue }
    $parts = $line -split "`t"
    if ($parts.Count -lt 3) { continue }
    $rel = $parts[1].Trim() -replace '\\', '/'
    $excluded = $false
    foreach ($p in $ExcludedPrefixes) { if ($rel.StartsWith($p)) { $excluded = $true } }
    # e3b0c442... is the sha256 of empty input: an empty file, which GitHub
    # refuses to host as a release asset.
    if ($parts[0].Trim().ToLower() -eq "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855") { $excluded = $true }
    if ($excluded) { $skipped++; continue }
    $scanned += [pscustomobject]@{
        Hash       = $parts[0].Trim().ToLower()
        RelPath    = $rel
        RemotePath = $parts[2].Trim()
    }
}
if ($skipped -gt 0) { Write-Host "$skipped dosya elendi (runtime cop / bos dosya)." }
Write-Host "Sunucuda $($scanned.Count) dosya bulundu."
if ($scanned.Count -eq 0) { throw "Sunucudan dosya listesi alinamadi - yol dogru mu?" }

# A client-extra mod and a server mod could in principle collide on the same
# name; the server copy wins so players always match what the server runs.
$byPath = [ordered]@{}
foreach ($f in $scanned) { if (-not $byPath.Contains($f.RelPath)) { $byPath[$f.RelPath] = $f } }

$oldByPath = @{}
if (Test-Path $ManifestOut) {
    try {
        $old = Get-Content $ManifestOut -Raw | ConvertFrom-Json
        foreach ($f in $old.files) { $oldByPath[$f.path] = $f }
    } catch { }
}

gh release view $Tag --repo $Repo *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Release yok, olusturuluyor: $Tag"
    gh release create $Tag --repo $Repo --title "$PackName Pack Files" --notes "AnuDownloader tarafindan kullanilan paket dosyalari. Elle indirmeyin." | Out-Null
    # Right after a release+tag deletion GitHub can reject the recreate; without
    # this check every upload below fails quietly and the manifest ends up
    # pointing at URLs that 404.
    gh release view $Tag --repo $Repo *> $null
    if ($LASTEXITCODE -ne 0) { throw "Release olusturulamadi: $Tag - birkac saniye sonra tekrar dene." }
}

$newFiles = @()
$toUpload = @()
foreach ($rel in $byPath.Keys) {
    $item = $byPath[$rel]
    $existing = $oldByPath[$rel]
    if ($existing -and $existing.sha256 -eq $item.Hash) { $newFiles += $existing }
    else { $toUpload += $item }
}
Write-Host "$($toUpload.Count) dosya yeni/degismis, sunucudan cekilip Release'e yuklenecek."

$tmpDir = Join-Path $env:TEMP "anu_vds_build"
if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

if ($toUpload.Count -gt 0) {
    # Pull everything in one archive rather than one scp per file: Windows scp
    # mangles backslash-escaped spaces into path separators, and mod filenames
    # are full of spaces and apostrophes. tar -T reads one path per line, so the
    # quoting problem disappears entirely - and 250 transfers become one.
    Write-Host "Degisen dosyalar sunucuda arsivleniyor..."
    $listFile = Join-Path $tmpDir "_paths.txt"
    ($toUpload | ForEach-Object { $_.RemotePath }) -join "`n" | Set-Content -Path $listFile -Encoding UTF8 -NoNewline

    & scp -o BatchMode=yes -i $SshKey $listFile "$SshHost`:/tmp/anu_paths.txt" | Out-Null
    & ssh -o BatchMode=yes -i $SshKey $SshHost "sed -i 's/\r$//' /tmp/anu_paths.txt; tar czf /tmp/anu_batch.tar.gz -T /tmp/anu_paths.txt 2>/dev/null; echo done" | Out-Null

    $tarLocal = Join-Path $tmpDir "batch.tar.gz"
    & scp -o BatchMode=yes -i $SshKey "$SshHost`:/tmp/anu_batch.tar.gz" $tarLocal | Out-Null
    & ssh -o BatchMode=yes -i $SshKey $SshHost "rm -f /tmp/anu_batch.tar.gz /tmp/anu_paths.txt" | Out-Null
    if (-not (Test-Path $tarLocal)) { throw "Arsiv sunucudan cekilemedi." }

    $extractDir = Join-Path $tmpDir "x"
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    & tar xzf $tarLocal -C $extractDir
    Remove-Item $tarLocal -Force

    $i = 0
    foreach ($item in $toUpload) {
        $i++
        $assetName = Get-AssetName $item.RelPath
        # tar stored the absolute path with its leading slash stripped
        $extracted = Join-Path $extractDir ($item.RemotePath.TrimStart('/') -replace '/', '\')
        if (-not (Test-Path -LiteralPath $extracted)) { Write-Host "[$i/$($toUpload.Count)] ATLANDI: $($item.RelPath)"; continue }
        $staged = Join-Path $tmpDir $assetName
        Copy-Item -LiteralPath $extracted -Destination $staged -Force
        Write-Host "[$i/$($toUpload.Count)] $($item.RelPath)"
        $uploadOut = gh release upload $Tag $staged --repo $Repo --clobber 2>&1
        if ($LASTEXITCODE -ne 0) {
            Remove-Item -LiteralPath $staged -Force -ErrorAction SilentlyContinue
            throw "Yukleme basarisiz: $($item.RelPath) - $uploadOut"
        }
        $newFiles += [pscustomobject]@{
            path     = $item.RelPath
            filename = Split-Path $item.RelPath -Leaf
            sha256   = $item.Hash
            size     = (Get-Item -LiteralPath $staged).Length
            url      = "https://github.com/$Repo/releases/download/$Tag/$assetName"
        }
        Remove-Item -LiteralPath $staged -Force
    }
}
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

$manifest = [pscustomobject]@{
    pack_name = $PackName
    version   = $Version
    generated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    source    = "vds:$ServerPath"
    files     = $newFiles
}
$dir = Split-Path $ManifestOut -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $ManifestOut -Encoding UTF8

Write-Host ""
Write-Host "Manifest yazildi: $ManifestOut"
Write-Host "Toplam dosya: $($newFiles.Count)  Yeni yuklenen: $($toUpload.Count)"
Write-Host "Simdi manifest.json'u commit+push et ve index.json'daki SHA'yi guncelle."
