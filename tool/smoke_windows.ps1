$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$root = Get-VisuSicRoot
$portable = Join-Path $root "artifacts/visusic-windows-x64-portable"
$executable = Join-Path $portable "VisuSic.exe"

if (-not (Test-Path -LiteralPath $executable)) {
    throw "Portable application not found. Run tool/build_windows.ps1 first."
}

$process = Start-Process -FilePath $executable -WorkingDirectory $portable -PassThru
try {
    Start-Sleep -Seconds 8
    $process.Refresh()
    if ($process.HasExited) {
        throw "VisuSic exited during startup with code $($process.ExitCode)."
    }

    Write-Host "VisuSic started successfully from the portable folder." -ForegroundColor Green
}
finally {
    if (-not $process.HasExited) {
        $null = $process.CloseMainWindow()
        if (-not $process.WaitForExit(5000)) {
            $process.Kill()
            $process.WaitForExit()
        }
    }
    $process.Dispose()
}
