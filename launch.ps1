# MCP stdout is reserved exclusively for the Python JSON-RPC stream.
$ErrorActionPreference = 'Stop'
$pythonExe = Join-Path $env:LOCALAPPDATA 'WebglobeMailConnector\.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $pythonExe)) {
    [Console]::Error.WriteLine('Webglobe Mail: extract plugin ZIP and run NASTAVIT-UCET.cmd first.')
    exit 1
}
# Inherit stdin/stdout directly; no PowerShell pipeline or JSON re-encoding.
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName = $pythonExe
$start.Arguments = '"' + (Join-Path $PSScriptRoot 'server.py') + '"'
$start.WorkingDirectory = $PSScriptRoot
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.EnvironmentVariables['PYTHONIOENCODING'] = 'utf-8'
$process = New-Object Diagnostics.Process
$process.StartInfo = $start
[void]$process.Start()
try { $process.WaitForExit(); exit $process.ExitCode }
finally { if (-not $process.HasExited) { $process.Kill() }; $process.Dispose() }

