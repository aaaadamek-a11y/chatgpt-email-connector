"""Offline IMAP Drafts tests: never connect to or modify a real mailbox."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

import draft_store


class FakeIMAP:
    def __init__(self, listing=None, status="OK"):
        self.rows = listing if listing is not None else [
            b'(\\HasNoChildren \\Drafts) "/" "Drafts"',
            b'(\\HasNoChildren) "/" "INBOX"']
        self.status = status
        self.appended = []
        self.login_calls = []
        self.logged_out = 0

    def login(self, user, password):
        self.login_calls.append((user, password))
        return "OK", [b"logged in"]

    def list(self):
        return "OK", self.rows

    def append(self, mailbox, flags, date_time, raw):
        self.appended.append((mailbox, flags, date_time, raw))
        return self.status, [b"append complete"]

    def logout(self):
        self.logged_out += 1


class Keyring:
    def get_password(self, service, key):
        return "fake-password"


class TestDrafts(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.config = Path(self.tmp.name) / "account.json"
        self.config.write_text(json.dumps({"protocol":"IMAP", "host":"imap.example.com", "user":"sender@example.com"}))
        self.patch_config = patch.object(draft_store.server, "CONFIG", self.config)
        self.patch_keyring = patch.object(draft_store.server, "secure_keyring", lambda: Keyring())
        self.patch_config.start()
        self.patch_keyring.start()
        self.addCleanup(self.patch_config.stop)
        self.addCleanup(self.patch_keyring.stop)

    def payload(self):
        return {"to":["one@example.com"], "cc":["two@example.com"], "bcc":["hidden@example.com"],
                "subject":"Koncept", "body":"Ahoj. Toto je pripravená správa."}

    def test_saves_only_to_drafts_with_draft_flag(self):
        imap = FakeIMAP()
        result = draft_store.save_draft(self.payload(), factory=lambda host: imap)
        self.assertEqual(result["status"], "saved")
        self.assertFalse(result["sent"])
        self.assertEqual(result["folder"], "Drafts")
        self.assertEqual(len(imap.appended), 1)
        name, flags, _date, raw = imap.appended[0]
        self.assertEqual(name, '"Drafts"')
        self.assertEqual(flags, "(\Draft)")
        self.assertIn(b"Subject: Koncept", raw)
        self.assertIn(b"Bcc: hidden@example.com", raw)
        self.assertEqual(imap.logged_out, 1)
        self.assertEqual(imap.login_calls, [("sender@example.com","fake-password")])

    def test_pop3_never_opens_connection(self):
        self.config.write_text(json.dumps({"protocol":"POP3","host":"pop3.example.com","user":"sender@example.com"}))
        opening = Mock()
        with self.assertRaisesRegex(draft_store.DraftError, "POP3"):
            draft_store.save_draft(self.payload(), factory=opening)
        opening.assert_not_called()

    def test_missing_folder_does_not_append(self):
        imap = FakeIMAP([b'(\\HasNoChildren) "/" "INBOX"'])
        with self.assertRaisesRegex(draft_store.DraftError, "missing"):
            draft_store.save_draft(self.payload(), factory=lambda _:imap)
        self.assertEqual(imap.appended, [])
        self.assertEqual(imap.logged_out, 1)

    def test_ambiguous_drafts_fail_closed(self):
        imap = FakeIMAP([b'(\\Drafts) "/" "Drafts"',b'(\\Drafts) "/" "INBOX.Drafts"'])
        with self.assertRaisesRegex(draft_store.DraftError,"ambiguous"):
            draft_store.save_draft(self.payload(), factory=lambda _:imap)
        self.assertEqual(imap.appended, [])

    def test_uses_fallback_koncepty_folder(self):
        imap = FakeIMAP([b'(\\HasNoChildren) "/" "Koncepty"'])
        result = draft_store.save_draft(self.payload(), factory=lambda _:imap)
        self.assertEqual(result["folder"],"Koncepty")

    def test_no_header_injection_and_no_send(self):
        imap = FakeIMAP()
        for bad in (
            {"to":["one@example.com\r\nBcc:evil@example.com"]},
            {"subject":"A\nBcc: evil@example.com"},
            {"body":"illegal\x00byte"}
        ):
            with self.subTest(bad=bad):
                args={**self.payload(),**bad}
                with self.assertRaises(draft_store.DraftError):
                    draft_store.save_draft(args, factory=lambda _:imap)
        self.assertEqual(imap.appended, [])

    def test_ambiguous_network_error_does_not_auto_retry(self):
        class BrokenIMAP(FakeIMAP):
            def append(self, *args):
                self.appended.append(args)
                raise OSError("network lost after APPEND")
        imap=BrokenIMAP()
        with self.assertRaisesRegex(draft_store.DraftError,"Check Drafts"):
            draft_store.save_draft(self.payload(), factory=lambda _:imap)
        self.assertEqual(len(imap.appended),1)


if __name__ == "__main__":
    unittest.main()
