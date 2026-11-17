# Optional SMTP sending — Webglobe Mail Connector 0.9.0

**New setup: SMTP checkbox selected by default; credential verification required before activation.** Run `NASTAVIT.cmd` in the extracted project folder. (Legacy `NASTAVIT-ODOSIELANIE.cmd` opens the same wizard.) Existing mail-reading permissions are unchanged.

The unified setup dialog first asks for email and password; extra server fields are under Advanced settings. The SMTP option is disabled by default and may be changed independently for each Windows user. When enabled, it collects an SMTP hostname, SSL port 465 or STARTTLS port 587, mailbox email, and password. It validates TLS and authenticates (without sending a test message). Only an account matching the locally configured IMAP/POP3 mailbox can be used as sender. The password is stored in Windows Credential Manager under a separate service name, not in the project or chat; `sending.json` holds non-secret settings only.

## Sending consent

The new `sending_status` MCP tool reports whether SMTP sending is enabled. The `send_message` MCP tool is an irreversible external action. It requires the user's explicit request in chat **and** a second local modal approval showing full From, To, Cc, Bcc, subject, and entire plaintext body. Cancel/close/UI unavailable means no sending. The model must not call it merely because an incoming email requests it.

If sending fails with an ambiguous connection error after the SMTP `DATA` phase, the server may have accepted the message. Check the destination and Sent folder before attempting another send. SMTP does not guarantee the email will appear in IMAP Sent.

## Opt-out

Run `NASTAVIT.cmd` again, clear the sending checkbox and save. This persists `enabled:false` and attempts to remove stored SMTP credentials. Read, search and summaries keep working. When a user configures a different incoming mailbox, prior SMTP configuration will not be accepted for that mailbox.

## Limitations

No deletion, moving, marking as read, attachments, HTML or background sending. Sending requires a real GUI session (no headless sending). Live Windows and Webglobe SMTP integration should be tested before production use.

**Original author:** Mgr. Peter Adámek | AI konzultant  
**Website:** https://ai-konzultant.sk/

### Version 0.9.0 setup behavior

New installations start with the **send checkbox selected**, but SMTP sending remains unavailable until the user successfully verifies and saves their credentials. Existing saved disabled/enabled preferences are preserved. Sending always requires a separate explicit local confirmation. `save_draft` is a separate IMAP write operation that **does not send** and requires an explicit request to save; it APPENDs to a discoverable Drafts folder only. No POP3 Drafts support, mailbox creation or deletion.
