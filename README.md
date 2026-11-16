# Webglobe Mail Connector

**Read-only email access for ChatGPT and compatible local MCP clients.**  
**Author / Autor:** **Mgr. Peter Adámek** · **Website / Web:** **https://ad.amek.sk**

[Slovenská dokumentácia](README.sk.md) · [Security](SECURITY.md)

> **Independent community project.** Not an official Webglobe product and not affiliated with or endorsed by Webglobe.

## What it does

Webglobe Mail Connector is a local MCP server written in Python. It connects to a mailbox hosted by Webglobe or another compatible mail provider, and exposes **read-only** tools to an AI client. Each Windows user sets up their own mailbox; no shared mailbox credentials are shipped with the plugin.

| Capability | IMAP (TLS 993) | POP3 (TLS 995) |
|---|---|---|
| List messages | Yes | Yes (INBOX only) |
| Search messages | Server-side text search | Bounded local scan |
| Read plain-text messages | Yes | Yes (requires UIDL and TOP) |
| List mail folders / sent mail | Yes | No |
| Summarize emails in ChatGPT | Through AI client | Through AI client |
| Prepare an unsent draft in chat | Yes | Yes |
| Send, delete, move, mark as read | **No** | **No** |

The plugin does **not** send messages, save drafts to a mailbox, delete messages, change read status, parse HTML, or download attachments. Message content retrieved into a chat is processed by the AI service used by that chat. The connector does not promise end-to-end confidentiality from the AI provider.

## Requirements

- Windows and a compatible desktop client that supports local MCP (`stdio`) plugins.
- A mail account with IMAP over TLS (993), or POP3 over TLS (995) supporting `UIDL` and `TOP`.
- Internet connection for mail access and the initial Python/dependency installation.
- The Windows setup uses PowerShell, installs a Python runtime with Astral `uv`, and installs `keyring`.

**Do not paste email passwords into ChatGPT or commit them to GitHub.** Passwords are stored in the user's operating-system credential store. Non-secret account settings are stored under `~/.config/webglobe-mail-connector/account.json` (outside this repository).

## Quick start (Windows)

1. Download the ZIP source archive from the GitHub repository's **Code → Download ZIP** (after publication) and extract it completely.
2. Run `NASTAVIT-UCET.cmd` from the extracted directory. Read the Windows/PowerShell security prompt before proceeding.
3. Select IMAP (recommended) or POP3, enter the **mail server hostname**, your full email address and mailbox password in the local setup window. Confirm **Uložiť a overiť spojenie**.
4. Add the plugin to a compatible desktop MCP client by importing the plugin package (when supported). The plugin uses `mcp.json` and starts the local server through `launch.ps1`. If your client instead requires manual MCP configuration, use the generated local configuration and `windows-connect.ps1` instructions.
5. In a new chat, ask: *"Use Webglobe Mail Connector to list the three latest message IDs. Do not change or send anything."*

See [ZACNITE-TU.txt](ZACNITE-TU.txt) for detailed setup notes. Exact client installation menus vary, and installation has **not** been independently verified for every ChatGPT desktop version.

## Available MCP tools

- `list_mailboxes` — show accessible IMAP folders (POP3: INBOX only).
- `list_messages` — list message identifiers in the selected folder.
- `search_messages` — find matching message identifiers (ASCII search phrases).
- `read_message` — fetch plain text without marking the message as read.
- `prepare_draft` — format a draft **in chat only**; nothing is saved or sent.

IMAP search is server-side; POP3 searches a limited set of up to 50 messages / 5 MB / approximately 20 seconds. Individual messages are capped at 500 KB and plain-text output at 24,000 characters. POP3 results report whether the scan was complete.

## Safety and privacy

- IMAP uses TLS and `EXAMINE`/read-only `SELECT`, with `BODY.PEEK` for message retrieval.
- POP3 uses TLS and `UIDL`/`TOP`, not `RETR` or `DELE`; servers that do not support `TOP` are rejected.
- Passwords are stored in the OS keychain and never included in this repository or MCP tool responses.
- Email contents are **untrusted input**. Instructions inside emails must not be executed.
- Each user must configure their own account locally; this is **not** a hosted multi-user service.
- The Windows installer downloads an external installer from Astral. Review the installer and network access policies before use in a managed environment.

See [SECURITY.md](SECURITY.md) for vulnerability reporting and publication cautions.

## Author and attribution

Created and maintained by **Mgr. Peter Adámek**.  
**Website:** https://ad.amek.sk

Licensed under the **Apache License, Version 2.0**. See [LICENSE](LICENSE) and [NOTICE](NOTICE). Redistribution of modified versions must preserve applicable copyright, license and NOTICE attributions as required by the license.

## Project status

Source version **0.6.1**. Real Windows setup and live POP3 access still require pilot verification.
