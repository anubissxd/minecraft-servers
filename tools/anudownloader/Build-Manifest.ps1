# Build-Manifest.ps1 - maintainer-side tool.
# Scans a mods folder, uploads new/changed .jar files as GitHub Release assets,
# and writes manifest.json that AnuDownloader.ps1 consumes.
#
# Usage:
#   .\Build-Manifest.ps1 -ModsFolder "C:\...\Medieval Fantasy\mods" -Repo "anubissxd/minecraft-servers" -Tag "medieval-fantasy-pack" -PackName "Medieval Fantasy" -Version "1.0.0"

param(
    [Parameter(Mandatory=$true)][string]$ModsFolder,
    [string]$Repo = "anubissxd/minecraft-servers",
    [string]$Tag = "medieval-fantasy-pack",
    [string]$PackName = "Medieval Fantasy",
    [string]$Version = (Get-Date -Format "yyyy.MM.dd-HHmm"),
    [string]$ManifestOut = (Join-Path $PSScriptRoot "..\..\distribution\medieval-fantasy\manifest.json")
)

function Get-FileSha256($path) {
    (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower()
}

Write-Host "Mevcut release kontrol ediliyor: $Tag"
$releaseExists = $true
gh release view $Tag --repo $Repo *> $null
if ($LASTEXITCODE -ne 0) {
    $releaseExists = $false
    Write-Host "Release yok, oluşturuluyor..."
    gh release create $Tag --repo $Repo --title "$PackName Pack Files" --notes "AnuDownloader tarafından kullanılan mod dosyaları. Elle indirmeyin." | Out-Null
}

$oldManifest = $null
if (Test-Path $ManifestOut) {
    try { $oldManifest = Get-Content $ManifestOut -Raw | ConvertFrom-Json } catch { $oldManifest = $null }
}
$oldByName = @{}
if ($oldManifest) {
    foreach ($f in $oldManifest.files) { $oldByName[$f.filename] = $f }
}

$jars = Get-ChildItem -Path $ModsFolder -Filter *.jar -File
Write-Host "Toplam $($jars.Count) jar bulundu."

$newFiles = @()
$toUpload = @()

foreach ($jar in $jars) {
    $hash = Get-FileSha256 $jar.FullName
    $existing = $oldByName[$jar.Name]
    if ($existing -and $existing.sha256 -eq $hash) {
        # değişmemiş, tekrar yükleme
        $newFiles += $existing
    } else {
        $toUpload += @{ jar = $jar; hash = $hash }
    }
}

Write-Host "$($toUpload.Count) dosya yeni/değişmiş, GitHub Release'e yüklenecek."

$i = 0
foreach ($item in $toUpload) {
    $i++
    $jar = $item.jar
    Write-Host "[$i/$($toUpload.Count)] Yükleniyor: $($jar.Name)"
    gh release upload $Tag $jar.FullName --repo $Repo --clobber | Out-Null
    $url = "https://github.com/$Repo/releases/download/$Tag/$($jar.Name)"
    $newFiles += @{
        filename = $jar.Name
        sha256   = $item.hash
        size     = $jar.Length
        url      = $url
    }
}

$manifest = @{
    pack_name = $PackName
    version   = $Version
    generated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    files     = $newFiles
}

$manifestDir = Split-Path $ManifestOut -Parent
if (-not (Test-Path $manifestDir)) { New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null }
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $ManifestOut -Encoding UTF8

Write-Host ""
Write-Host "Manifest yazildi: $ManifestOut"
Write-Host "Toplam dosya: $($newFiles.Count)  Yeni yuklenen: $($toUpload.Count)"
Write-Host ""
Write-Host "Simdi manifest.json'u git'e commit+push etmen gerekiyor."
