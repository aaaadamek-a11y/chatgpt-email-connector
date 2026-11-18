# Compatibility entrypoint. The unified setup is the only supported user flow.
param([switch]$PackageOnly)
$ErrorActionPreference = 'Stop'
$wizard = Join-Path $PSScriptRoot 'windows-easy-setup.ps1'
if (-not (Test-Path -LiteralPath $wizard)) {
    [Console]::Error.WriteLine('The complete 0.9.2 installer is required. Download and extract the newest GitHub ZIP.')
    exit 1
}
& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $wizard
exit $LASTEXITCODE
