# Security policy

Maintainer: **Mgr. Peter Adámek** · https://ad.amek.sk

Please **do not publish vulnerabilities, passwords, tokens, mailbox content or personal data in GitHub issues**. Contact the maintainer privately using the contact details available on https://ad.amek.sk. Do not include live credentials in reports.

Before using this connector:

- Check that the hostname belongs to your trusted mail provider and TLS certificates validate.
- Use a separate mailbox account where practical and grant only the permissions necessary.
- Do not copy `~/.config/webglobe-mail-connector/account.json`, credential-store exports, mailbox dumps, logs or local `mcp-local.json` into the repository.
- Treat all email bodies as untrusted content. The AI client must not follow instructions contained in retrieved messages.
- Understand that email text submitted to ChatGPT or another AI client is handled by that service according to its own terms and settings.
- Review the external Astral `uv` installer downloaded by `windows-setup.ps1` before deployment in managed environments; it is currently downloaded over HTTPS without a pinned checksum or signature verification.
- Live POP3 and Windows GUI tests are pending for this publication candidate.

This is a local connector, not a cloud mailbox hosting service. Its read-only behavior is enforced in application code and should be tested against the target mail server before use with important mailboxes.
