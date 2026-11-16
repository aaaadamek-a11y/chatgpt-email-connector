# Webglobe Mail Connector — one-window Windows setup.
# Credentials only enter the local form and travel to Python on stdin, never argv/logs.
$ErrorActionPreference = 'Stop'
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $appDir = Join-Path $env:LOCALAPPDATA 'WebglobeMailConnector'
    $sourceDir = $PSScriptRoot
    $pythonExe = Join-Path $appDir '.venv\Scripts\python.exe'
    $uvDir = Join-Path $appDir 'runtime'
    $uvExe = Join-Path $uvDir 'uv.exe'
    $accountPath = Join-Path $env:USERPROFILE '.config\webglobe-mail-connector\account.json'
    $sendingPath = Join-Path $env:USERPROFILE '.config\webglobe-mail-connector\sending.json'

    $savedAccount = $null; $savedSending = $null
    if (Test-Path -LiteralPath $accountPath) {
        try { $savedAccount = Get-Content -Raw -LiteralPath $accountPath | ConvertFrom-Json } catch { }
    }
    if (Test-Path -LiteralPath $sendingPath) {
        try { $savedSending = Get-Content -Raw -LiteralPath $sendingPath | ConvertFrom-Json } catch { }
    }

    function Install-LocalComponents {
        New-Item -ItemType Directory -Force -Path $appDir | Out-Null
        $names = @('server.py','pop3_reader.py','account_setup.py','requirements.txt',
            'smtp_sender.py','smtp_server.py','sending_setup.py','send_confirmation.py',
            'smtp_package_local.py','windows-easy-setup.ps1','NASTAVIT.cmd',
            'NASTAVIT-UCET.cmd','NASTAVIT-ODOSIELANIE.cmd','windows-smtp-setup.ps1')
        foreach ($name in $names) {
            $src = Join-Path $sourceDir $name
            if (-not (Test-Path -LiteralPath $src)) {
                throw "V baliku chyba subor $name. Stiahnite cely aktualny ZIP z GitHubu."
            }
            $dest = Join-Path $appDir $name
            if ([IO.Path]::GetFullPath($src) -ne [IO.Path]::GetFullPath($dest)) {
                Copy-Item -LiteralPath $src -Destination $dest -Force
            }
        }
        if (-not (Test-Path -LiteralPath $uvExe)) {
            $consent = [System.Windows.Forms.MessageBox]::Show(
                'Na prvom spusteni sa do uzivatelskeho profilu nainstaluje uv, Python a kniznica keyring cez internet. Chcete pokracovat?',
                'Príprava konektora', 'YesNo', 'Question')
            if ($consent -ne 'Yes') { throw 'Instalacia bola zrusena.' }
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $installer = Join-Path $appDir 'uv-install.ps1'
            Invoke-WebRequest -UseBasicParsing -Uri 'https://astral.sh/uv/0.13.0/install.ps1' -OutFile $installer
            $env:UV_UNMANAGED_INSTALL = $uvDir
            try {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer
                if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $uvExe)) { throw 'Python instalator zlyhal.' }
            } finally { Remove-Item -LiteralPath $installer -Force -ErrorAction SilentlyContinue }
        }
        if (-not (Test-Path -LiteralPath $pythonExe)) {
            & $uvExe venv --python 3.12 (Join-Path $appDir '.venv')
            if ($LASTEXITCODE -ne 0) { throw 'Priprava Python prostredia zlyhala.' }
        }
        & $uvExe pip install --python $pythonExe -r (Join-Path $appDir 'requirements.txt')
        if ($LASTEXITCODE -ne 0) { throw 'Instalacia kniznic zlyhala.' }
    }

    function Invoke-SetupScript([string]$scriptName, [hashtable]$settings) {
        $info = New-Object System.Diagnostics.ProcessStartInfo
        $info.FileName = $pythonExe
        $info.Arguments = '"' + (Join-Path $appDir $scriptName) + '"'
        $info.WorkingDirectory = $appDir
        $info.UseShellExecute = $false
        $info.CreateNoWindow = $true
        $info.RedirectStandardInput = $true
        $info.RedirectStandardOutput = $true
        $info.RedirectStandardError = $true
        $info.EnvironmentVariables['PYTHONIOENCODING'] = 'utf-8'
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $info
        try {
            [void]$proc.Start()
            $json = $settings | ConvertTo-Json -Compress
            $encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
            $proc.StandardInput.WriteLine($encoded)
            $proc.StandardInput.Close()
            $json = $null; $encoded = $null; $settings = $null
            if (-not $proc.WaitForExit(60000)) {
                $proc.Kill()
                throw 'Overenie servera trvalo prilis dlho.'
            }
            if ($proc.ExitCode -ne 0) {
                if ($scriptName -eq 'account_setup.py') {
                    throw 'Nepodarilo sa pripojiť k prichádzajúcej pošte. Skontrolujte e-mail, heslo a nastavenie servera.'
                }
                throw 'Nepodarilo sa overiť SMTP. Skontrolujte server, heslo a prípadne rozšírené nastavenia.'
            }
        } finally { if (-not $proc.HasExited) { $proc.Kill() }; $proc.Dispose() }
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Webglobe Mail Connector | Jednoduché nastavenie 0.8.1'
    $form.ClientSize = New-Object System.Drawing.Size(590,375)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false

    $title = New-Object System.Windows.Forms.Label
    $title.Text = 'Pripojenie e-mailovej schránky'
    $title.Font = New-Object System.Drawing.Font('Segoe UI',14,[System.Drawing.FontStyle]::Bold)
    $title.SetBounds(20,16,550,34); $form.Controls.Add($title)
    $intro = New-Object System.Windows.Forms.Label
    $intro.Text = 'Pre bežný Webglobe účet stačí e-mail a heslo.'
    $intro.SetBounds(22,54,540,22); $form.Controls.Add($intro)
    $mailLabel = New-Object System.Windows.Forms.Label
    $mailLabel.Text = 'E-mailová adresa'; $mailLabel.SetBounds(22,89,540,19); $form.Controls.Add($mailLabel)
    $mailField = New-Object System.Windows.Forms.TextBox
    $mailField.SetBounds(22,109,542,27)
    if ($savedAccount) { $mailField.Text = [string]$savedAccount.user }
    $form.Controls.Add($mailField)
    $passLabel = New-Object System.Windows.Forms.Label
    $passLabel.Text = 'Heslo schránky'; $passLabel.SetBounds(22,150,540,19); $form.Controls.Add($passLabel)
    $passField = New-Object System.Windows.Forms.TextBox
    $passField.SetBounds(22,170,542,27); $passField.UseSystemPasswordChar = $true
    $form.Controls.Add($passField)
    $passHint = New-Object System.Windows.Forms.Label
    $passHint.Text = if ($savedAccount) { 'Pri nezmenenej schránke môže heslo zostať prázdne.' } else { 'Heslo sa ukladá do systému Windows, nie do ChatGPT.' }
    $passHint.SetBounds(22,201,542,19); $form.Controls.Add($passHint)
    $sendToggle = New-Object System.Windows.Forms.CheckBox
    $sendToggle.Text = 'Povoliť aj odosielanie e-mailov (vždy sa vyžaduje potvrdenie)'
    $sendToggle.SetBounds(22,234,545,30)
    $sendToggle.Checked = [bool]($savedSending -and $savedSending.enabled)
    $form.Controls.Add($sendToggle)
    $advancedToggle = New-Object System.Windows.Forms.CheckBox
    $advancedToggle.Text = 'Rozšírené nastavenia serverov (voliteľné)'
    $advancedToggle.SetBounds(22,276,542,25); $form.Controls.Add($advancedToggle)

    $protocolLabel = New-Object System.Windows.Forms.Label
    $protocolLabel.Text = 'Protokol prijímania'; $protocolLabel.SetBounds(22,313,255,19)
    $protocolBox = New-Object System.Windows.Forms.ComboBox
    $protocolBox.DropDownStyle = 'DropDownList'; $protocolBox.SetBounds(22,335,255,25)
    [void]$protocolBox.Items.Add('IMAP (odporúčané)'); [void]$protocolBox.Items.Add('POP3')
    $protocolBox.SelectedIndex = if ($savedAccount -and $savedAccount.protocol -eq 'POP3') { 1 } else { 0 }
    $incomingLabel = New-Object System.Windows.Forms.Label
    $incomingLabel.Text = 'Server prijímania'; $incomingLabel.SetBounds(302,313,262,19)
    $incomingField = New-Object System.Windows.Forms.TextBox
    $incomingField.SetBounds(302,335,262,25)
    $incomingField.Text = if ($savedAccount -and $savedAccount.host) { [string]$savedAccount.host } else { 'mail.webglobe.sk' }
    $smtpLabel = New-Object System.Windows.Forms.Label
    $smtpLabel.Text = 'SMTP server (odosielanie)'; $smtpLabel.SetBounds(22,380,255,19)
    $smtpField = New-Object System.Windows.Forms.TextBox
    $smtpField.SetBounds(22,402,255,25)
    $smtpField.Text = if ($savedSending -and $savedSending.host) { [string]$savedSending.host } else { 'mail.webglobe.sk' }
    $securityLabel = New-Object System.Windows.Forms.Label
    $securityLabel.Text = 'SMTP zabezpečenie'; $securityLabel.SetBounds(302,380,262,19)
    $securityBox = New-Object System.Windows.Forms.ComboBox
    $securityBox.DropDownStyle = 'DropDownList'; $securityBox.SetBounds(302,402,262,25)
    [void]$securityBox.Items.Add('SSL/TLS - port 465'); [void]$securityBox.Items.Add('STARTTLS - port 587')
    $securityBox.SelectedIndex = if ($savedSending -and $savedSending.mode -eq 'STARTTLS') { 1 } else { 0 }
    $advanced = @($protocolLabel,$protocolBox,$incomingLabel,$incomingField,$smtpLabel,$smtpField,$securityLabel,$securityBox)
    foreach ($c in $advanced) { $c.Visible = $false; $form.Controls.Add($c) }

    $save = New-Object System.Windows.Forms.Button
    $save.Text = 'Overiť a uložiť pripojenie'
    $save.SetBounds(22,315,245,35); $form.Controls.Add($save)
    $status = New-Object System.Windows.Forms.Label
    $status.Text = 'Odosielanie je štandardne vypnuté. Mazanie nie je podporované.'
    $status.SetBounds(290,315,274,45); $form.Controls.Add($status)
    $advancedToggle.Add_CheckedChanged({
        $show = $advancedToggle.Checked
        foreach ($control in $advanced) { $control.Visible = $show }
        if ($show) {
            $form.ClientSize = New-Object System.Drawing.Size(590,510)
            $save.Top = 455; $status.Top = 455
        } else {
            $form.ClientSize = New-Object System.Drawing.Size(590,375)
            $save.Top = 315; $status.Top = 315
        }
    })
    $sendToggle.Add_CheckedChanged({
        $smtpField.Enabled = $sendToggle.Checked
        $securityBox.Enabled = $sendToggle.Checked
    })
    $smtpField.Enabled = $sendToggle.Checked
    $securityBox.Enabled = $sendToggle.Checked

    $save.Add_Click({
        $save.Enabled = $false
        try {
            $address = $mailField.Text.Trim()
            $pass = $passField.Text
            $incomingHost = $incomingField.Text.Trim()
            $protocol = if ($protocolBox.SelectedIndex -eq 1) { 'POP3' } else { 'IMAP' }
            if ($address.Length -gt 254 -or $address -notmatch '^[^\s<>@,;]+@[^\s<>@,;]+\.[^\s<>@,;]+$') {
                throw 'Zadajte platnú úplnú e-mailovú adresu.'
            }
            if (-not $incomingHost -or $incomingHost -match '[/@: ]') { throw 'Nesprávny server prijímania.' }
            $sameAccount = ($savedAccount -and ($savedAccount.user -ieq $address) -and
                ($savedAccount.host -ieq $incomingHost) -and
                (([string]$savedAccount.protocol -eq $protocol) -or
                 (-not $savedAccount.protocol -and $protocol -eq 'IMAP')))
            if (-not $pass -and -not $sameAccount) {
                throw 'Pre nové alebo zmenené konto zadajte heslo.'
            }
            # On existing accounts a blank password is fine for reading, but enabling SMTP
            # for the first time needs an SMTP secret. The same mailbox password is used.
            if ($sendToggle.Checked -and -not $pass) {
                $expectedMode = if ($securityBox.SelectedIndex -eq 1) { 'STARTTLS' } else { 'SSL' }
                $reuseSMTP = ($savedSending -and $savedSending.enabled -and
                    ($savedSending.user -ieq $address) -and
                    ($savedSending.host -ieq $smtpField.Text.Trim()) -and
                    ($savedSending.mode -eq $expectedMode))
                if (-not $reuseSMTP) { throw 'Na prvé zapnutie odosielania zadajte heslo schránky.' }
            }
            $status.Text = 'Pripravujem konektor...'; $form.Refresh()
            Install-LocalComponents
            if (-not $sameAccount -or $pass) {
                $status.Text = 'Overujem prihlásenie...'; $form.Refresh()
                Invoke-SetupScript 'account_setup.py' @{ protocol=$protocol;host=$incomingHost;user=$address;password=$pass }
            }
            $smtpHost = $smtpField.Text.Trim()
            $mode = if ($securityBox.SelectedIndex -eq 1) { 'STARTTLS' } else { 'SSL' }
            $smtpPort = if ($mode -eq 'STARTTLS') { 587 } else { 465 }
            $status.Text = 'Nastavujem SMTP...'; $form.Refresh()
            if ($sendToggle.Checked) {
                Invoke-SetupScript 'sending_setup.py' @{ enabled=$true;host=$smtpHost;user=$address;
                    mode=$mode;port=$smtpPort;password=$pass }
            } else {
                Invoke-SetupScript 'sending_setup.py' @{enabled=$false}
            }
            $pass = $null; $passField.Clear()
            $status.Text = 'Pripravujem doplnok...'; $form.Refresh()
            & $pythonExe (Join-Path $appDir 'smtp_package_local.py') | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'Priprava balika doplnku zlyhala.' }
            $packageDir = Join-Path $appDir 'Pridat-do-aplikacie'
            $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Webglobe Mail - nastavenie.lnk'))
            $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
            $shortcut.Arguments = '-NoProfile -STA -ExecutionPolicy Bypass -File "' + (Join-Path $appDir 'windows-easy-setup.ps1') + '"'
            $shortcut.WorkingDirectory = $appDir
            $shortcut.Save()
            $message = 'Pripojenie je uložené. Aktualizujte pôvodný doplnok v ChatGPT pomocou ZIP zo zobrazeného priečinka.'
            if ($sendToggle.Checked) { $message += "`nOdosielanie je povolené, ale každá správa vyžaduje samostatné potvrdenie." }
            else { $message += "`nOdosielanie zostalo vypnuté." }
            $answer = [System.Windows.Forms.MessageBox]::Show($message + "`n`nOtvoriť priečinok s doplnkom?", 'Nastavenie hotové', 'YesNo', 'Information')
            if ($answer -eq 'Yes') { Start-Process explorer.exe -ArgumentList ('"' + $packageDir + '"') }
            $form.Close()
        } catch {
            # Never display process stdout, passwords or SMTP server responses.
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Nastavenie sa nepodarilo') | Out-Null
            $status.Text = 'Upravte údaje a skúste znova.'
        } finally {
            $passField.Clear(); $save.Enabled = $true
        }
    })
    [void]$form.ShowDialog()
} catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Webglobe Mail - chyba') | Out-Null
    exit 1
}
