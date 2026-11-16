"""Offline setup/packaging invariant tests (cannot emulate Windows Forms here)."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class EasySetupSafety(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.form = (ROOT / 'windows-easy-setup.ps1').read_text(encoding='utf-8-sig')

    def test_one_window_launchers(self):
        self.assertTrue((ROOT / 'NASTAVIT.cmd').is_file())
        for name in ('NASTAVIT.cmd','NASTAVIT-UCET.cmd','NASTAVIT-ODOSIELANIE.cmd'):
            self.assertIn('windows-easy-setup.ps1',(ROOT / name).read_text())

    def test_server_fields_advanced_and_default(self):
        self.assertIn("$incomingField.Text = if ($savedAccount", self.form)
        self.assertIn("'mail.webglobe.sk'", self.form)
        self.assertIn('Rozšírené nastavenia', self.form)
        self.assertIn('$c.Visible = $false', self.form)
        self.assertIn("'POP3'", self.form)

    def test_local_stdin_and_separate_smtp_optin(self):
        self.assertIn('RedirectStandardInput = $true', self.form)
        self.assertIn('StandardInput.WriteLine($encoded)', self.form)
        self.assertNotIn("$info.Arguments = $pass", self.form)
        self.assertIn("Invoke-SetupScript 'sending_setup.py' @{enabled=$false}", self.form)
        self.assertIn("$sendToggle.Checked = [bool]($savedSending -and $savedSending.enabled)", self.form)

    def test_version_and_metadata(self):
        root=json.loads((ROOT/'plugin.json').read_text())
        legacy=json.loads((ROOT/'.codex-plugin/plugin.json').read_text())
        self.assertEqual(root['version'],'0.8.0')
        self.assertEqual(legacy['version'],root['version'])
        self.assertEqual(root['license'],'Apache-2.0')
        self.assertIn('Mgr. Peter Adámek',root['author']['name'])
        self.assertEqual(root['homepage'],'https://ai-konzultant.sk/')

    def test_no_deletion_and_no_unapproved_send(self):
        server=(ROOT/'smtp_server.py').read_text()
        sender=(ROOT/'smtp_sender.py').read_text()
        self.assertIn("'destructiveHint':True", server)
        self.assertNotIn("'name':'delete_message'",server)
        self.assertIn('confirmer(',sender)
        self.assertIn("if not settings['enabled']:",sender)


if __name__=='__main__':
    unittest.main()
