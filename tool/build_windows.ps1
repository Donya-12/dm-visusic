$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$root = Get-VisuSicRoot
$flutter = Get-VisuSicFlutter
$app = Join-Path $root "apps/visusic"
$release = Join-Path $app "build/windows/x64/runner/Release"
$artifacts = Join-Path $root "artifacts"
$portable = Join-Path $artifacts "visusic-windows-x64-portable"
$archive = Join-Path $artifacts "visusic-windows-x64-portable.zip"

Invoke-VisuSicCommand $flutter @("pub", "get") $root
Invoke-VisuSicCommand $flutter @("gen-l10n") $app
Invoke-VisuSicCommand $flutter @("build", "windows", "--release") $app

$executable = Join-Path $release "VisuSic.exe"
if (-not (Test-Path -LiteralPath $executable)) {
    throw "Expected Windows executable was not produced: $executable"
}

if (Test-Path -LiteralPath $portable) {
    Remove-Item -LiteralPath $portable -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $portable | Out-Null
Copy-Item -Path (Join-Path $release "*") -Destination $portable -Recurse -Force
Copy-Item -LiteralPath (Join-Path $root "LICENSE") -Destination $portable
Copy-Item -LiteralPath (Join-Path $root "THIRD-PARTY.md") -Destination $portable

New-Item -ItemType Directory -Force -Path $artifacts | Out-Null
Compress-Archive -Path (Join-Path $portable "*") -DestinationPath $archive -Force
$hash = (Get-FileHash -Algorithm SHA256 $archive).Hash.ToLowerInvariant()
Set-Content -LiteralPath "$archive.sha256" -Value "$hash  visusic-windows-x64-portable.zip" -Encoding ascii

Write-Host "Portable archive: $archive" -ForegroundColor Green
Write-Host "SHA-256: $hash" -ForegroundColor Green
