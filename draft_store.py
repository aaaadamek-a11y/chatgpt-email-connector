"""Store an explicitly requested email draft in an existing IMAP Drafts folder.

This is an IMAP APPEND only. No SMTP delivery, mailbox creation, deletion,
move or read-status mutation is performed.
"""
from email.message import EmailMessage
from email.policy import SMTP
import imaplib
import json
import re
import ssl

import server
from smtp_sender import validate_address

class DraftError(Exception):
    """Safe error that does not expose IMAP responses or credentials."""

_DRAFT_NAMES = {"drafts", "draft", "concepts", "koncepty", "inbox.drafts", "inbox.koncepty", "entwuerfe"}
_LIST_RE = re.compile(rb'^\(([^)]*)\)\s+(?:"(?:[^"\\]|\\.)*"|NIL)\s+(.+)$')


def draft_folder(connection):
    status, listing = connection.list()
    if status != "OK" or not listing:
        raise DraftError("Cannot discover IMAP Drafts folder.")
    special, fallback = [], []
    for row in listing:
        if not isinstance(row, bytes):
            continue
        match = _LIST_RE.match(row)
        if not match:
            continue
        flags = match.group(1).decode("ascii", "ignore").split()
        if any(x.casefold() == r"\noselect" for x in flags):
            continue
        name = match.group(2).decode("ascii", "strict")
        if name.startswith('"') and name.endswith('"'):
            name = re.sub(r"\\(.)", r"\1", name[1:-1])
        if not name or any(ord(c) < 32 for c in name) or len(name) > 500:
            continue
        if any(x.casefold() == r"\drafts" for x in flags):
            special.append(name)
        elif name.casefold() in _DRAFT_NAMES:
            fallback.append(name)
    candidates = list(dict.fromkeys(special or fallback))
    if len(candidates) != 1:
        raise DraftError("Drafts folder is missing or ambiguous. Configure one Drafts folder in your IMAP mailbox.")
    return candidates[0]


def _addresses(arguments, field):
    value = arguments.get(field, [])
    if not isinstance(value, list) or len(value) > 20 or any(not validate_address(x) for x in value):
        raise DraftError("Invalid recipient email address.")
    return value


def save_draft(arguments, factory=None):
    if type(arguments) is not dict or set(arguments) - {"to", "cc", "bcc", "subject", "body"}:
        raise DraftError("Unsupported draft arguments.")
    to, cc, bcc = (_addresses(arguments, x) for x in ("to", "cc", "bcc"))
    if len(set(to + cc + bcc)) > 20:
        raise DraftError("At most 20 unique recipients are allowed.")
    subject, body = arguments.get("subject"), arguments.get("body")
    if not isinstance(subject, str) or not subject or len(subject) > 500 or any(ord(c) < 32 for c in subject):
        raise DraftError("Invalid subject.")
    if not isinstance(body, str) or len(body) > 24000 or "\x00" in body:
        raise DraftError("Invalid draft body.")

    try:
        account = json.loads(server.CONFIG.read_text(encoding="utf-8"))
        if account.get("protocol", "IMAP").upper() != "IMAP":
            raise DraftError("Saving drafts requires IMAP; POP3 does not support server-side drafts.")
        host, user = account["host"], account["user"]
        if not validate_address(user):
            raise DraftError("Configured sender address is invalid.")
        secret = server.secure_keyring().get_password(server.SERVICE, host + "|" + user)
        if not secret:
            raise DraftError("Mailbox password is missing. Run local setup.")
    except DraftError:
        raise
    except Exception:
        raise DraftError("Mailbox settings are unavailable. Run local setup.") from None

    message = EmailMessage()
    message["From"] = user
    if to: message["To"] = ", ".join(to)
    if cc: message["Cc"] = ", ".join(cc)
    if bcc: message["Bcc"] = ", ".join(bcc)
    message["Subject"] = subject
    message.set_content(body, charset="utf-8")
    raw = message.as_bytes(policy=SMTP)
    connection = None
    try:
        connection = factory(host) if factory is not None else imaplib.IMAP4_SSL(host, 993, ssl_context=ssl.create_default_context(), timeout=30)
        connection.login(user, secret)
        mailbox = draft_folder(connection)
        quoted = '"' + mailbox.replace("\\", "\\\\").replace('"', '\\"') + '"'
        status, _ = connection.append(quoted, r"(\Draft)", None, raw)
        if status != "OK":
            raise DraftError("IMAP server did not confirm saving the draft; verify before retrying.")
        return {"status": "saved", "sent": False, "folder": mailbox,
                "note": "Draft saved on the IMAP server. No email was sent. Opening in a mail client may require refresh."}
    except DraftError:
        raise
    except Exception:
        raise DraftError("Cannot confirm IMAP draft save. Check Drafts before retrying to avoid duplicates.") from None
    finally:
        if connection is not None:
            try: connection.logout()
            except Exception: pass
