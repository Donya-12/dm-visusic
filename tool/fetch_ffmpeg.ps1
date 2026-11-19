$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$targetDir = Join-Path $root "tool/ffmpeg"
$archive = Join-Path $root "build/ffmpeg.zip"
$url = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip"

if (Test-Path -LiteralPath (Join-Path $targetDir "ffmpeg.exe")) {
    Write-Host "FFmpeg is already present in tool/ffmpeg."
    exit 0
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $root "build") | Out-Null

Write-Host "Downloading FFmpeg (LGPL build)..."
curl.exe -L --fail --retry 3 -o $archive $url
if ($LASTEXITCODE -ne 0) {
    throw "FFmpeg download failed with exit code $LASTEXITCODE"
}

$extractDir = Join-Path $root "build/ffmpeg-extract"
if (Test-Path -LiteralPath $extractDir) {
    Remove-Item -LiteralPath $extractDir -Recurse -Force
}
Expand-Archive -LiteralPath $archive -DestinationPath $extractDir -Force
$bin = Get-ChildItem -LiteralPath $extractDir -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
if ($null -eq $bin) {
    throw "ffmpeg.exe was not found in the downloaded archive."
}
Copy-Item -LiteralPath $bin.FullName -Destination (Join-Path $targetDir "ffmpeg.exe") -Force
Remove-Item -LiteralPath $archive -Force
Remove-Item -LiteralPath $extractDir -Recurse -Force

Write-Host "FFmpeg installed to $targetDir"
