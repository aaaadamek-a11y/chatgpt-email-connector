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

## Install / update on Windows

1. Download and fully extract the repository ZIP. Run `NASTAVIT-UCET.cmd` to configure the read-only mailbox first (Python runtime and dependencies are installed locally). Enter passwords **only in the local settings window**, never in ChatGPT or source files.
2. Connect the local MCP plugin through the generated package or manual configuration as described in `ZACNITE-TU.txt`.
3. **Optional:** run `NASTAVIT-ODOSIELANIE.cmd` to enable SMTP. The checkbox defaults to **off**. Enter SMTP hostname, SSL 465 or STARTTLS 587, the same email account and SMTP password. An SMTP login/TLS test runs without sending a message.
4. Reload or re-import the newly generated local MCP plugin. Check `sending_status` before sending.
5. To disable sending again, run `NASTAVIT-ODOSIELANIE.cmd`, uncheck the box and save. Passwords are stored in Windows Credential Manager, separately from the IMAP/POP3 password.

Each colleague configures their own account in their own Windows user profile. No shared password is distributed in the plugin ZIP. The connector is local, not a shared hosted mail service.

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

Version **0.7.0** adds optional SMTP sending and a local per-user consent dialog. Automated offline tests validate disabled-by-default behavior and approval paths. Live Webglobe SMTP, Windows GUI and installation require an actual Windows pilot; do not treat offline tests as proof of production delivery.

## License and author attribution

Copyright 2026 **Mgr. Peter Adámek | AI konzultant** — https://ai-konzultant.sk/

Licensed under the **Apache License, Version 2.0**. See [LICENSE](LICENSE) and [NOTICE](NOTICE). Redistributed copies and modified versions must preserve applicable copyright, license and NOTICE attribution as provided by the license.
