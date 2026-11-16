# MCP stdout is reserved for Python JSON-RPC messages.
$ErrorActionPreference = 'Stop'
$pythonExe = Join-Path $env:LOCALAPPDATA 'WebglobeMailConnector\.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $pythonExe)) {
    [Console]::Error.WriteLine('Webglobe Mail: extract plugin ZIP and run NASTAVIT-UCET.cmd first.')
    exit 1
}
$entry = Join-Path $PSScriptRoot 'smtp_server.py'
if (-not (Test-Path -LiteralPath $entry)) { [Console]::Error.WriteLine('SMTP MCP entrypoint missing. Install the complete 0.7.0 plugin.'); exit 1 }
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName = $pythonExe
$start.Arguments = '"' + $entry + '"'
$start.WorkingDirectory = $PSScriptRoot
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.EnvironmentVariables['PYTHONIOENCODING'] = 'utf-8'
$process = New-Object Diagnostics.Process
$process.StartInfo = $start
[void]$process.Start()
try { $process.WaitForExit(); exit $process.ExitCode }
finally { if (-not $process.HasExited) { $process.Kill() }; $process.Dispose() }
