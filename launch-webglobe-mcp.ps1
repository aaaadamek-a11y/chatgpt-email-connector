# Webglobe Mail Connector MCP launcher (Windows desktop/local MCP clients only).
# Original author: Mgr. Peter Adámek | AI konzultant
# https://ai-konzultant.sk/
# The launcher does not handle passwords; they remain in the Windows Credential Manager.
$ErrorActionPreference = 'Stop'
try {
    $localRoot = Join-Path $env:LOCALAPPDATA 'WebglobeMailConnector'
    $pythonExecutable = Join-Path $localRoot '.venv\Scripts\python.exe'
    $serverEntry = Join-Path $localRoot 'smtp_server.py'
    if (-not (Test-Path -LiteralPath $pythonExecutable -PathType Leaf) -or
        -not (Test-Path -LiteralPath $serverEntry -PathType Leaf)) {
        [Console]::Error.WriteLine('Webglobe MCP runtime is not configured. Run the installed Webglobe Mail - Nastavenie shortcut.')
        exit 2
    }
    # stdout belongs exclusively to the MCP JSON-RPC process.
    & $pythonExecutable $serverEntry
    exit $LASTEXITCODE
} catch {
    [Console]::Error.WriteLine('Cannot start the local Webglobe MCP server. Check the local installation.')
    exit 3
}
