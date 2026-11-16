param([switch]$PackageOnly)
$ErrorActionPreference = 'Stop'
try {
    Add-Type -AssemblyName System.Windows.Forms
    $appDir = Join-Path $env:LOCALAPPDATA 'WebglobeMailConnector'
    $uvDir = Join-Path $appDir 'runtime'
    $uvExe = Join-Path $uvDir 'uv.exe'
    $pythonExe = Join-Path $appDir '.venv\Scripts\python.exe'
    if ($PackageOnly) {
        if (-not (Test-Path -LiteralPath $pythonExe)) { throw 'Najprv spustite NASTAVIT.cmd.' }
        if ([IO.Path]::GetFullPath($PSScriptRoot) -ne [IO.Path]::GetFullPath($appDir)) {
            Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'package_local.py') -Destination (Join-Path $appDir 'package_local.py') -Force
        }
        & $pythonExe (Join-Path $appDir 'package_local.py')
        if ($LASTEXITCODE -ne 0) { throw 'Doplnok sa nepodarilo pripravit.' }
        $guideSource = Join-Path $PSScriptRoot 'windows-connect.ps1'
        $guideTarget = Join-Path $appDir 'windows-connect.ps1'
        if ([IO.Path]::GetFullPath($guideSource) -ne [IO.Path]::GetFullPath($guideTarget)) {
            Copy-Item -LiteralPath $guideSource -Destination $guideTarget -Force
        }
        & powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $guideTarget
        exit 0
    }
    $answer = [System.Windows.Forms.MessageBox]::Show(
        'Nastavenie pripravi konektor do vasho pouzivatelskeho profilu. Pri prvom spusteni stiahne uv od Astral, Python a kniznice z internetu. Nevyzaduje spravcu. Pokracovat?',
        'Webglobe Mail Connector', 'YesNo', 'Information')
    if ($answer -ne 'Yes') { exit 0 }
    New-Item -ItemType Directory -Force -Path $appDir | Out-Null
    foreach ($name in @('server.py', 'pop3_reader.py', 'account_setup.py', 'requirements.txt', 'windows-setup.ps1', 'package_local.py', 'windows-connect.ps1')) {
        $source = Join-Path $PSScriptRoot $name
        $target = Join-Path $appDir $name
        if ([IO.Path]::GetFullPath($source) -ne [IO.Path]::GetFullPath($target)) {
            Copy-Item -LiteralPath $source -Destination $target -Force
        }
    }
    if (-not (Test-Path -LiteralPath $uvExe)) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $installer = Join-Path $appDir 'uv-install.ps1'
        Invoke-WebRequest -UseBasicParsing -Uri 'https://astral.sh/uv/0.13.0/install.ps1' -OutFile $installer
        $env:UV_UNMANAGED_INSTALL = $uvDir
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $uvExe)) { throw 'Nepodarilo sa stiahnut uv.' }
        Remove-Item -LiteralPath $installer
    }
    if (-not (Test-Path -LiteralPath $pythonExe)) {
        & $uvExe venv --python 3.12 (Join-Path $appDir '.venv')
        if ($LASTEXITCODE -ne 0) { throw 'Nepodarilo sa pripravit Python.' }
    }
    & $uvExe pip install --python $pythonExe -r (Join-Path $appDir 'requirements.txt')
    if ($LASTEXITCODE -ne 0) { throw 'Nepodarilo sa pripravit kniznice.' }

    # Generic local MCP configuration: no email address or password is included.
    $config = @{mcpServers = @{'webglobe-mail' = @{command = $pythonExe; args = @((Join-Path $appDir 'server.py'))}}}
    $configPath = Join-Path $appDir 'mcp-local.json'
    [IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
    $launcher = '@echo off' + "`r`n" + '"' + $pythonExe + '" "' + (Join-Path $appDir 'server.py') + '"' + "`r`n"
    [IO.File]::WriteAllText((Join-Path $appDir 'SPUSTIT-MCP.cmd'), $launcher, [Text.Encoding]::Default)
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Webglobe - nastavenie.lnk'))
    $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $appDir 'windows-setup.ps1') + '"'
    $shortcut.WorkingDirectory = $appDir
    $shortcut.Save()
    $connectShortcut = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Webglobe - pripojit do aplikacie.lnk'))
    $connectShortcut.TargetPath = $shortcut.TargetPath
    $connectShortcut.Arguments = '-NoProfile -STA -ExecutionPolicy Bypass -File "' + (Join-Path $appDir 'windows-connect.ps1') + '"'
    $connectShortcut.WorkingDirectory = $appDir
    $connectShortcut.Save()




    & $pythonExe (Join-Path $appDir 'package_local.py')
    if ($LASTEXITCODE -ne 0) { throw 'Kontrola spustenia konektora zlyhala.' }

    $form = New-Object Windows.Forms.Form
    $form.Text = 'Webglobe Mail Connector - nastavenie'
    $form.ClientSize = New-Object Drawing.Size(500,395)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $protocolLabel = New-Object Windows.Forms.Label
    $protocolLabel.Text = 'Protokol (IMAP: 993 TLS / POP3: 995 TLS)'
    $protocolLabel.SetBounds(20,15,460,20); $form.Controls.Add($protocolLabel)
    $protocolBox = New-Object Windows.Forms.ComboBox
    $protocolBox.DropDownStyle = 'DropDownList'
    [void]$protocolBox.Items.Add('IMAP'); [void]$protocolBox.Items.Add('POP3')
    $protocolBox.SetBounds(20,37,460,24); $protocolBox.SelectedIndex = 0
    $form.Controls.Add($protocolBox)
    $fields = @{}
    $labels = @('Server (z nastaveni poskytovatela)', 'Cela e-mailova adresa', 'Heslo schranky')
    for ($i=0; $i -lt 3; $i++) {
        $label = New-Object Windows.Forms.Label
        $label.Text = $labels[$i]; $label.Location = New-Object Drawing.Point(20,(85+$i*65))
        $label.Size = New-Object Drawing.Size(460,20); $form.Controls.Add($label)
        $box = New-Object Windows.Forms.TextBox
        $box.Location = New-Object Drawing.Point(20,(107+$i*65)); $box.Size = New-Object Drawing.Size(460,24)
        if ($i -eq 2) { $box.UseSystemPasswordChar = $true }
        $fields[$i] = $box; $form.Controls.Add($box)
    }
    $accountPath = Join-Path $env:USERPROFILE '.config\webglobe-mail-connector\account.json'
    if (Test-Path -LiteralPath $accountPath) {
        try {
            $savedAccount = Get-Content -Raw -LiteralPath $accountPath | ConvertFrom-Json
            $fields[0].Text = $savedAccount.host; $fields[1].Text = $savedAccount.user
        } catch { }
    } elseif (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'firma.json')) {
        try { $fields[0].Text = (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'firma.json') | ConvertFrom-Json).imap_server } catch { }
    }
    if ($savedAccount -and $savedAccount.protocol -eq 'POP3') { $protocolBox.SelectedItem = 'POP3' }
    $protocolBox.Add_SelectedIndexChanged({
        if ($savedAccount -and $savedAccount.protocol -eq [string]$protocolBox.SelectedItem) {
            $fields[0].Text = $savedAccount.host
        } elseif ([string]$protocolBox.SelectedItem -eq 'IMAP') {
            $fields[0].Text = 'imap.nameserver.sk'
        } else { $fields[0].Clear() }
    })
    $note = New-Object Windows.Forms.Label
    $note.Text = 'Heslo: Windows Credential Manager. POP3: iba INBOX, vyzaduje UIDL a TOP. Odoslana posta je dostupna iba cez IMAP.'
    $note.Location = New-Object Drawing.Point(20,283); $note.Size = New-Object Drawing.Size(460,45)
    $form.Controls.Add($note)
    $button = New-Object Windows.Forms.Button
    $button.Text = 'Ulozit a overit spojenie'; $button.Location = New-Object Drawing.Point(20,343)
    $button.Size = New-Object Drawing.Size(220,32); $form.Controls.Add($button)
    $button.Add_Click({
        $button.Enabled = $false
        try {
            $payload = @{protocol=[string]$protocolBox.SelectedItem; host=$fields[0].Text.Trim(); user=$fields[1].Text.Trim(); password=$fields[2].Text} | ConvertTo-Json -Compress
            $info = New-Object Diagnostics.ProcessStartInfo
            $info.FileName = $pythonExe
            $info.Arguments = '"' + (Join-Path $appDir 'account_setup.py') + '"'
            $info.UseShellExecute = $false; $info.CreateNoWindow = $true
            $info.RedirectStandardInput = $true; $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
            $info.EnvironmentVariables['PYTHONIOENCODING'] = 'utf-8'
            $process = New-Object Diagnostics.Process; $process.StartInfo = $info
            [void]$process.Start()
            $encodedPayload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload))
            $process.StandardInput.WriteLine($encodedPayload); $process.StandardInput.Close()
            $encodedPayload = $null
            $payload = $null; $fields[2].Clear()
            if (-not $process.WaitForExit(45000)) { $process.Kill(); throw 'Spojenie trvalo prilis dlho. Skontrolujte server a siet.' }
            if ($process.ExitCode -ne 0) { throw 'Nepodarilo sa ulozit alebo overit ucet. Skontrolujte server, protokol a heslo. POP3 vyzaduje UIDL a TOP.' }
            [Windows.Forms.MessageBox]::Show('Ucet je ulozeny a spojenie overene. Teraz importujte povodny ZIP doplnku do klienta s podporou lokalnych doplnkov. Rucne MCP polia nevyplnajte. Heslo uz do aplikacie nezadavajte.', 'Hotovo') | Out-Null
            $form.Close()
        } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Nastavenie sa nepodarilo') | Out-Null }
        finally { $button.Enabled = $true }
    })
    [void]$form.ShowDialog()
} catch {
    [Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Webglobe - chyba') | Out-Null
    exit 1
}

