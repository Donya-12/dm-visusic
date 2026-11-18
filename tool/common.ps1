Set-StrictMode -Version Latest

function Get-VisuSicRoot {
    return Split-Path -Parent $PSScriptRoot
}

function Get-VisuSicFlutter {
    $localFlutter = Join-Path (Get-VisuSicRoot) ".tooling/flutter/bin/flutter.bat"
    if (Test-Path -LiteralPath $localFlutter) {
        return $localFlutter
    }

    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw "Flutter was not found. Install Flutter 3.50.0 or place it at .tooling/flutter."
    }

    return $command.Source
}

function Invoke-VisuSicCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory = (Get-VisuSicRoot)
    )

    Write-Host "> $FilePath $($Arguments -join ' ')" -ForegroundColor Cyan
    Push-Location -LiteralPath $WorkingDirectory
    try {
        & $FilePath @Arguments
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    if ($exitCode -ne 0) {
        throw "Command failed with exit code ${exitCode}: $FilePath $($Arguments -join ' ')"
    }
}
