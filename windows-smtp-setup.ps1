# Separate opt-in SMTP settings. Never passes passwords in command arguments.
param()
$ErrorActionPreference = 'Stop'
try {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
  $appDir = Join-Path $env:LOCALAPPDATA 'WebglobeMailConnector'
  $pythonExe = Join-Path $appDir '.venv\Scripts\python.exe'
  if (-not (Test-Path -LiteralPath $pythonExe)) { throw 'Najprv spustite NASTAVIT-UCET.cmd a nastavte prijimanie posty.' }
  foreach ($name in @('smtp_sender.py','smtp_server.py','sending_setup.py','send_confirmation.py','smtp_package_local.py','windows-smtp-setup.ps1','NASTAVIT-ODOSIELANIE.cmd')) {
    $source = Join-Path $PSScriptRoot $name
    $target = Join-Path $appDir $name
    if (-not (Test-Path -LiteralPath $source)) { throw "Chyba subor $name, stiahnite aktualny ZIP konektora." }
    if ([IO.Path]::GetFullPath($source) -ne [IO.Path]::GetFullPath($target)) {
      Copy-Item -LiteralPath $source -Destination $target -Force
    }
  }
  # Keep the sending settings accessible even after the source ZIP is removed.
  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Webglobe - odosielanie.lnk'))
  $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $shortcut.Arguments = '-NoProfile -STA -ExecutionPolicy Bypass -File "' + (Join-Path $appDir 'windows-smtp-setup.ps1') + '"'
  $shortcut.WorkingDirectory = $appDir
  $shortcut.Save()
  $accountPath = Join-Path $env:USERPROFILE '.config\webglobe-mail-connector\account.json'
  if (-not (Test-Path -LiteralPath $accountPath)) { throw 'Najprv nastavte prijimanie posty.' }
  $mailAccount = Get-Content -Raw -LiteralPath $accountPath | ConvertFrom-Json
  $sendingPath = Join-Path $env:USERPROFILE '.config\webglobe-mail-connector\sending.json'
  $saved = $null
  if (Test-Path -LiteralPath $sendingPath) { try { $saved = Get-Content -Raw -LiteralPath $sendingPath | ConvertFrom-Json } catch {} }

  $form = New-Object System.Windows.Forms.Form
  $form.Text = 'Webglobe Mail – nastavenie odosielania'
  $form.ClientSize = New-Object System.Drawing.Size(570,460)
  $form.StartPosition = 'CenterScreen'
  $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false
  $toggle = New-Object System.Windows.Forms.CheckBox
  $toggle.Text = 'Povolit odosielanie e-mailov (standardne vypnute)'
  $toggle.SetBounds(20,20,520,28)
  $toggle.Checked = [bool]($saved -and $saved.enabled)
  $form.Controls.Add($toggle)
  $note = New-Object System.Windows.Forms.Label
  $note.Text = 'Kazda odosielana sprava musi byt osobitne potvrdena v lokalnom okne. Mazanie posty je zakazane.'
  $note.SetBounds(20,55,520,40); $form.Controls.Add($note)

  $labels = @('SMTP server (podla poskytovatela):','Zabezpecenie:','SMTP pouzivatel (e-mail):','SMTP heslo (ulozi sa do Windows Credential Manager):')
  $positions = @(110,174,238,302)
  foreach ($i in 0..3) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $labels[$i]; $label.SetBounds(20,$positions[$i],525,20)
    $form.Controls.Add($label)
  }
  $hostField = New-Object System.Windows.Forms.TextBox
  $hostField.SetBounds(20,133,520,24)
  $hostField.Text = if ($saved -and $saved.host) { [string]$saved.host } else { 'mail.webglobe.sk' }
  $form.Controls.Add($hostField)
  $tlsBox = New-Object System.Windows.Forms.ComboBox
  $tlsBox.DropDownStyle = 'DropDownList'; $tlsBox.SetBounds(20,197,520,24)
  [void]$tlsBox.Items.Add('SSL/TLS (port 465)')
  [void]$tlsBox.Items.Add('STARTTLS (port 587)')
  $tlsBox.SelectedIndex = if ($saved -and $saved.mode -eq 'STARTTLS') { 1 } else { 0 }
  $form.Controls.Add($tlsBox)
  $userField = New-Object System.Windows.Forms.TextBox
  $userField.SetBounds(20,261,520,24)
  $userField.Text = [string]$mailAccount.user
  $form.Controls.Add($userField)
  $passwordField = New-Object System.Windows.Forms.TextBox
  $passwordField.SetBounds(20,325,520,24); $passwordField.UseSystemPasswordChar = $true
  $form.Controls.Add($passwordField)
  $hint = New-Object System.Windows.Forms.Label
  $hint.Text = 'Heslo: pri nezmenenych SMTP udajoch moze ostat prazdne. Pri zmene servera ho zadajte.'
  $hint.SetBounds(20,356,520,38); $form.Controls.Add($hint)
  $save = New-Object System.Windows.Forms.Button
  $save.Text = 'Ulozit nastavenie'; $save.SetBounds(20,410,210,32)
  $form.Controls.Add($save)
  $toggle.Add_CheckedChanged({
    foreach ($field in @($hostField,$tlsBox,$userField,$passwordField)) { $field.Enabled = $toggle.Checked }
  })
  foreach ($field in @($hostField,$tlsBox,$userField,$passwordField)) { $field.Enabled = $toggle.Checked }
  $save.Add_Click({
    $save.Enabled = $false
    try {
      $isEnabled = [bool]$toggle.Checked
      $mode = if ($tlsBox.SelectedIndex -eq 1) { 'STARTTLS' } else { 'SSL' }
      $port = if ($mode -eq 'STARTTLS') { 587 } else { 465 }
      $payload = if ($isEnabled) {
        @{enabled=$true;host=$hostField.Text.Trim();user=$userField.Text.Trim();mode=$mode;port=$port;password=$passwordField.Text}
      } else { @{enabled=$false} }
      $info = New-Object System.Diagnostics.ProcessStartInfo
      $info.FileName = $pythonExe
      $info.Arguments = '"' + (Join-Path $appDir 'sending_setup.py') + '"'
      $info.UseShellExecute = $false; $info.CreateNoWindow = $true
      $info.RedirectStandardInput = $true; $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
      $info.EnvironmentVariables['PYTHONIOENCODING'] = 'utf-8'
      $process = New-Object System.Diagnostics.Process
      $process.StartInfo = $info; [void]$process.Start()
      $serialized = $payload | ConvertTo-Json -Compress
      $encodedPayload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($serialized))
      $process.StandardInput.WriteLine($encodedPayload)
      $process.StandardInput.Close()
      $encodedPayload = $null; $serialized = $null; $payload = $null
      $passwordField.Clear()
      if (-not $process.WaitForExit(45000)) { $process.Kill(); throw 'Overenie SMTP vyprsalo.' }
      if ($process.ExitCode -ne 0) { throw 'SMTP prihlasenie sa nepodarilo overit. Skontrolujte TLS, server, konto a heslo.' }
      # Ensure the locally installed MCP path uses the opt-in wrapper.
      $localConfigPath = Join-Path $appDir 'mcp-local.json'
      if (Test-Path -LiteralPath $localConfigPath) {
        $localConfig = Get-Content -Raw -LiteralPath $localConfigPath | ConvertFrom-Json
        $localConfig.mcpServers.'webglobe-mail'.args = @((Join-Path $appDir 'smtp_server.py'))
        [IO.File]::WriteAllText($localConfigPath,($localConfig | ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
      }
      [IO.File]::WriteAllText((Join-Path $appDir 'SPUSTIT-MCP.cmd'), ('@echo off' + "`r`n" + '"' + $pythonExe + '" "' + (Join-Path $appDir 'smtp_server.py') + '"' + "`r`n"),[Text.Encoding]::Default)
      & $pythonExe (Join-Path $appDir 'smtp_package_local.py')
      if ($LASTEXITCODE -ne 0) { throw 'Nepodarilo sa pripravit lokalny doplnok. Odosielanie sa vsak mohlo ulozit.' }
      $message = if ($isEnabled) { 'Odosielanie je povolene. Pri KAZDOM odoslani sa zobrazi potvrdzovacie okno.' } else { 'Odosielanie je vypnute.' }
      [System.Windows.Forms.MessageBox]::Show($message + "`nObnovte/reimportujte vygenerovany lokalny MCP doplnok, aby sa nove funkcie prejavili.", 'Ulozene') | Out-Null
      $form.Close()
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'SMTP nastavenie – chyba') | Out-Null
    } finally { $save.Enabled = $true }
  })
  [void]$form.ShowDialog()
} catch {
  [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'SMTP nastavenie – chyba') | Out-Null
  exit 1
}
