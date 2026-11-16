# Publishing Webglobe Mail Connector 0.7.0

**Original author:** Mgr. Peter Adámek | AI konzultant — https://ai-konzultant.sk/

Repository: https://github.com/aaaadamek-a11y/chatgpt-email-connector
License: Apache License 2.0; preserve original attribution in NOTICE and the applicable license/copyright notices when redistributing, as required by the license.

## Release checklist

1. Keep code, documentation and both plugin manifests on version 0.7.0.
2. Ensure SMTP is **disabled by default**, the user must enable it locally, and all SMTP actions require an additional local confirmation dialog.
3. Verify the plugin's only write tool is `send_message`. There must be **no delete, expunge, move, mark-as-read or save-draft** tools.
4. Run `python -m unittest discover -s tests -v`, inspect MCP `tools/list` annotations, and pilot-test the Windows setup and SMTP TLS authentication.
5. Before publishing, scan for credentials, `.env`, private email exports, `account.json`, `sending.json`, `mcp-local.json`, logs, and developer machine paths. Check full Git history.
6. Publish only source files and legal/docs files, not per-user configuration files, private ZIPs or real mailbox contents.
7. After installing on Windows, run `NASTAVIT-ODOSIELANIE.cmd` to configure/revoke per-user SMTP permissions. Test a deliberately addressed non-sensitive message and confirm explicitly.

Public GitHub source alone does not make a private ChatGPT plugin publicly listed. This is an unofficial community project, not endorsed by Webglobe.
