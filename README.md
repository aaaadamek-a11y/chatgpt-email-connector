# Webglobe Mail Connector

**Read and search email from ChatGPT via IMAP/POP3, with an OPTIONAL, user-confirmed SMTP sending mode.** Works as a local MCP connector for Windows. Email deletion and mailbox modification are **not supported**.

**Original author:** Mgr. Peter Adámek | AI konzultant  
**Website:** https://ai-konzultant.sk/  
[Slovenská dokumentácia](README.sk.md) · [SMTP setup](SMTP.md) · [Security policy](SECURITY.md) · [License](LICENSE) · [Attribution](NOTICE)

> Independent community project, not affiliated with, endorsed by or operated by Webglobe.

## Features

| Operation | Default | Notes |
| --- | --- | --- |
| List, search and read email | Enabled | IMAP 993/TLS or POP3 995/TLS |
| Browse IMAP folders and sent mail | Enabled | POP3 supports INBOX only |
| Summarize email via ChatGPT | Enabled | Contents handled by AI client |
| Compose a draft in chat | Enabled | Does not send or save drafts |
| **Send email via authenticated SMTP** | **Disabled** | Explicit local opt-in and per-message human approval required |
| Delete, move, mark as read | **Unavailable** | No such tools implemented |

Supported MCP tools: `list_mailboxes`, `list_messages`, `search_messages`, `read_message`, `prepare_draft`, `sending_status`, and **`send_message`**. The sending tool is advertised as a write-capable, irreversible operation; it is blocked until enabled by the current Windows user. Sending is never triggered by received email content alone.

## Easy setup / update on Windows (v0.8.1)

1. [Download the current ZIP](https://github.com/aaaadamek-a11y/chatgpt-email-connector/archive/refs/heads/main.zip) and **extract all files** to one folder.
2. Double-click **`NASTAVIT.cmd`**. A single setup window asks only for **your full email address** and **password**. For standard Webglobe mailboxes, IMAP (`mail.webglobe.sk`, port 993) is preconfigured; no server knowledge is required.
3. **Optional:** tick *Enable sending*. SMTP uses the same address/password, with `mail.webglobe.sk` port 465 (SSL/TLS) as the default. SMTP is **off by default** and each real send requires an additional local confirmation dialog. No test email is sent during setup.
4. For another provider, older Webglobe hosting (`imap.nameserver.sk`), POP3, or special settings, expand **Advanced server settings**. Existing configured hostnames and mail settings are preserved when upgrading.
5. Click **Verify and save connection**. The setup installs missing local dependencies, verifies the chosen mail protocols and prepares `Webglobe-pridat-doplnok.zip`. Open the generated folder and **update/re-import the existing plugin** in your compatible desktop MCP client. Check `sending_status` in a new chat.

To change settings later, run `NASTAVIT.cmd` again, or use the desktop shortcut **Webglobe Mail – nastavenie**. For an unchanged connected mailbox, the existing password can remain blank unless enabling SMTP for the first time. The older `NASTAVIT-UCET.cmd` and `NASTAVIT-ODOSIELANIE.cmd` launch the same wizard for compatibility.

Each Windows user has independent credentials in the OS keychain. Passwords never belong in GitHub, an MCP configuration, or a chat message. Deleting, moving, marking read, and auto-sending without approval remain unavailable.

**Compatibility:** installation requires a Windows desktop client supporting local MCP/stdio plugins; it is not a hosted cloud connector. A clean-machine Windows GUI test is still required before broad deployment to colleagues. See [Slovenský návod](README.sk.md) and [SMTP](SMTP.md).

### Important safety behavior

- Sending is **off by default**, including after upgrading from earlier versions.
- Every message requires a **separate, explicit user confirmation** in a local dialog displaying the entire From/To/Cc/Bcc/Subject/Body; if the dialog cannot open or the user cancels, the connector will **not send**.
- SMTP uses verified TLS and authentication, supports only port 465 (SSL) or 587 (STARTTLS). `From` is fixed to the locally configured mailbox. A separate SMTP password is stored in the OS keychain.
- Messages are plain text only, up to 20 distinct recipients and 24,000 body characters. No attachments or HTML sending.
- SMTP acceptance is not guaranteed final delivery. A mail provider may **not** save SMTP-sent messages in its Sent folder. Do not automatically retry after ambiguous network failures.
- No mailbox deletion, moving, read/unread changes, or stored drafts.
- IMAP reads use `EXAMINE` and `BODY.PEEK`; POP3 uses `UIDL`/`TOP`, never `DELE`.
- All incoming email content is untrusted; AI must not treat it as executable instructions. Sensitive mail text supplied to ChatGPT is handled by the AI provider according to its settings and terms.

## Provider configuration

For commonly configured Webglobe mailboxes the published outgoing server is `mail.webglobe.sk` and SSL port `465` or STARTTLS port `587`. Actual settings vary by hosting platform; confirm the server hostname with your provider. Incoming IMAP and POP3 servers are configured separately from SMTP.

## Status / limitations

Version **0.8.1** introduces a unified Windows setup window and retains optional SMTP sending with per-user consent. Automated offline tests validate disabled-by-default behavior and approval paths. Live Webglobe SMTP, Windows GUI and installation require an actual Windows pilot; do not treat offline tests as proof of production delivery.

## License and author attribution

Copyright 2026 **Mgr. Peter Adámek | AI konzultant** — https://ai-konzultant.sk/

Licensed under the **Apache License, Version 2.0**. See [LICENSE](LICENSE) and [NOTICE](NOTICE). Redistributed copies and modified versions must preserve applicable copyright, license and NOTICE attribution as provided by the license.

**0.8.1 fix:** Corrected the Windows PowerShell automatic `$Host` variable collision in the account setup wizard. Download and extract the updated ZIP before re-running `NASTAVIT.cmd`.
