$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$root = Get-VisuSicRoot
$flutter = Get-VisuSicFlutter
$dart = Join-Path (Split-Path -Parent $flutter) "dart.bat"
$app = Join-Path $root "apps/visusic"

Invoke-VisuSicCommand $flutter @("pub", "get") $root
Invoke-VisuSicCommand $flutter @("gen-l10n") $app

$members = @(
    "apps/visusic",
    "packages/visusic_audio",
    "packages/visusic_core",
    "packages/visusic_platform",
    "packages/visusic_render",
    "packages/visusic_widgets_builtin"
)

foreach ($member in $members) {
    Invoke-VisuSicCommand $flutter @("analyze") (Join-Path $root $member)
}

$dartPackages = @(
    "packages/visusic_audio",
    "packages/visusic_core",
    "packages/visusic_platform"
)

foreach ($package in $dartPackages) {
    Invoke-VisuSicCommand $dart @("test") (Join-Path $root $package)
}

$flutterPackages = @(
    "packages/visusic_render",
    "packages/visusic_widgets_builtin",
    "apps/visusic"
)

foreach ($package in $flutterPackages) {
    Invoke-VisuSicCommand $flutter @("test") (Join-Path $root $package)
}

Write-Host "All VisuSic checks passed." -ForegroundColor Green
