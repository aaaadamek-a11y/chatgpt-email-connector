"""Local GUI bridge: credentials arrive through stdin, never process arguments."""
import json
import base64
import os
import sys
import imaplib
import ssl
import server

def save_account(data):
    host = data['host'].strip()
    user = data['user'].strip()
    password = data['password']
    protocol = data.get('protocol','IMAP').upper()
    if protocol not in ('IMAP','POP3'): raise ValueError('Unsupported protocol')
    if not host or any(x in host for x in '/:@\\') or any(ord(x) < 33 for x in host) or not user or not password:
        raise ValueError('Invalid account')
    store = server.secure_keyring()
    # Verify before replacing the previously configured account.
    if protocol == 'POP3':
        import pop3_reader
        c = pop3_reader.open_pop({'host':host,'user':user,'protocol':protocol},password)
        try:
            count,_ = c.stat()
            pop3_reader.identifiers(c)
            if count: c.top(1,0)  # Headers only: verify TOP without RETR.
        finally:
            try: c.quit()
            except Exception: c.close()
    else:
        c = imaplib.IMAP4_SSL(host, 993, ssl_context=ssl.create_default_context(), timeout=15)
        try:
            c.login(user, password)
            status, _ = c.select('INBOX', readonly=True)
            if status != 'OK': raise ValueError('Cannot examine INBOX')
        finally:
            c.logout()
    store.set_password(server.SERVICE, host + '|' + user, password)
    server.CONFIG.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    server.CONFIG.write_text(json.dumps({'host':host,'user':user,'protocol':protocol}), encoding='utf-8')
    os.chmod(server.CONFIG, 0o600)

if __name__ == '__main__':
    try:
        save_account(json.loads(base64.b64decode(sys.stdin.readline().strip(), validate=True).decode('utf-8')))
    except Exception:
        print('Account setup failed.', file=sys.stderr)
        sys.exit(1)

