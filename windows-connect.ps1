$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
$appDir = Join-Path $env:LOCALAPPDATA 'WebglobeMailConnector'
$pythonExe = Join-Path $appDir '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $pythonExe)) {
    [Windows.Forms.MessageBox]::Show('Najprv spustite NASTAVIT.cmd.', 'Webglobe') | Out-Null
    exit 1
}
$form = New-Object Windows.Forms.Form
$form.Text = 'Webglobe - dokoncit pripojenie'
$form.ClientSize = New-Object Drawing.Size(690,535)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false
$intro = New-Object Windows.Forms.Label
$intro.Text = "1. V desktopovej aplikacii otvorte Nastavenia > Doplnky > Pridat > Pridat MCP server.`r`n2. Vyberte STDIO. Pre kazde pole kliknite Kopirovat a vlozte ho do aplikacie cez Ctrl+V."
$intro.Location = New-Object Drawing.Point(20,18); $intro.Size = New-Object Drawing.Size(650,55)
$form.Controls.Add($intro)
$rows = @(
    @('Meno', 'webglobe_mail'),
    @('Prikaz na spustenie', $pythonExe),
    @('Argumenty - jeden argument', (Join-Path $appDir 'server.py')),
    @('Pracovny adresar', $appDir)
)
for ($i=0; $i -lt $rows.Count; $i++) {
    $label = New-Object Windows.Forms.Label
    $label.Text = $rows[$i][0]; $label.Location = New-Object Drawing.Point(20,(83+$i*70))
    $label.Size = New-Object Drawing.Size(640,20); $form.Controls.Add($label)
    $text = New-Object Windows.Forms.TextBox
    $text.Text = $rows[$i][1]; $text.ReadOnly = $true
    $text.Location = New-Object Drawing.Point(20,(105+$i*70)); $text.Size = New-Object Drawing.Size(535,25)
    $form.Controls.Add($text)
    $button = New-Object Windows.Forms.Button
    $button.Text = 'Kopirovat'; $button.Tag = $rows[$i][1]
    $button.Location = New-Object Drawing.Point(565,(102+$i*70)); $button.Size = New-Object Drawing.Size(105,29)
    $button.Add_Click({
        param($sender, $eventArgs)
        try { [Windows.Forms.Clipboard]::SetText([string]$sender.Tag); $sender.Text = 'Skopirovane' }
        catch { [Windows.Forms.MessageBox]::Show('Schranka je obsadena. Skuste Kopirovat znova.') | Out-Null }
    })
    $form.Controls.Add($button)
}
$finish = New-Object Windows.Forms.Label
$finish.Text = "3. Premenne prostredia nechajte prazdne. Kliknite Ulozit.`r`n4. Otvorte novy chat a vlozte testovaci pokyn tlacidlom nizsie.`r`nAk uz webglobe_mail existuje, nepridavajte druhy server. Heslo sem nevkladajte."
$finish.Location = New-Object Drawing.Point(20,374); $finish.Size = New-Object Drawing.Size(650,63)
$form.Controls.Add($finish)
$test = New-Object Windows.Forms.Button
$test.Text = 'Kopirovat testovaci pokyn'
$test.Location = New-Object Drawing.Point(20,451); $test.Size = New-Object Drawing.Size(255,36)
$test.Add_Click({
    [Windows.Forms.Clipboard]::SetText('Pouzi MCP server webglobe_mail. Zavolaj iba list_messages s limitom 3 a zobraz UID. Necitaj obsah sprav, nic neposielaj ani nemen.')
    $test.Text = 'Skopirovane - vlozte do chatu'
})
$form.Controls.Add($test)
$close = New-Object Windows.Forms.Button
$close.Text = 'Zavriet'; $close.Location = New-Object Drawing.Point(550,451)
$close.Size = New-Object Drawing.Size(120,36); $close.Add_Click({$form.Close()})
$form.Controls.Add($close)
[void]$form.ShowDialog()

