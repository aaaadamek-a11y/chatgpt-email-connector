# Publishing Webglobe Mail Connector 0.9.0

**Original author:** Mgr. Peter Adámek | AI konzultant — https://ai-konzultant.sk/

Repository: https://github.com/aaaadamek-a11y/chatgpt-email-connector
License: Apache License 2.0; preserve original attribution in NOTICE and the applicable license/copyright notices when redistributing, as required by the license.

## Release checklist

1. Keep code, documentation and both plugin manifests on version 0.9.0.
2. Ensure SMTP is **disabled by default**, the user must enable it locally, and all SMTP actions require an additional local confirmation dialog.
3. Verify the plugin's only write tool is `send_message`. There must be **no delete, expunge, move, mark-as-read or save-draft** tools.
4. Run `python -m unittest discover -s tests -v`, inspect MCP `tools/list` annotations, and pilot-test the Windows setup and SMTP TLS authentication.
5. Before publishing, scan for credentials, `.env`, private email exports, `account.json`, `sending.json`, `mcp-local.json`, logs, and developer machine paths. Check full Git history.
6. Publish only source files and legal/docs files, not per-user configuration files, private ZIPs or real mailbox contents.
7. After installing on Windows, run `NASTAVIT-ODOSIELANIE.cmd` to configure/revoke per-user SMTP permissions. Test a deliberately addressed non-sensitive message and confirm explicitly.

Public GitHub source alone does not make a private ChatGPT plugin publicly listed. This is an unofficial community project, not endorsed by Webglobe.

## Easy setup 0.9.0

Use `NASTAVIT.cmd` (unified setup) instead of requiring users to understand separate IMAP and SMTP setup. The old command aliases remain supported. Run the Windows GUI on a clean host before calling the installer production-tested.

Release 0.9.0: ensure EXE contains `draft_store.py`, new `save_draft` MCP write annotation and test suite, default checkbox state for new users, and unchanged local approval for every SMTP send. IMAP APPEND only; no delete tools. Windows CI builds and checks the installer; live mailbox integration still needs a pilot.
