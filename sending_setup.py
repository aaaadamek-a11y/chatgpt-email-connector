"""Persist per-user SMTP opt-in; receives credentials via base64 stdin, never argv."""
import base64
import json
import os
import sys
import tempfile

import server
import smtp_sender


def persist(settings):
    path = smtp_sender.SENDING_CONFIG
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temp = tempfile.mkstemp(prefix='.sending-',suffix='.json',dir=path.parent)
    try:
        with os.fdopen(fd,'w',encoding='utf-8') as out:
            json.dump(settings,out)
        os.chmod(temp,0o600)
        os.replace(temp,path)
    finally:
        if os.path.exists(temp): os.unlink(temp)


def set_sending(data):
    if type(data) is not dict or type(data.get('enabled')) is not bool:
        raise ValueError('Invalid opt-in.')
    keyring = server.secure_keyring()
    previous = None
    try:
        previous = smtp_sender.read_settings()
    except Exception:
        pass
    if data['enabled'] is False:
        # First block sending, then best-effort delete stored SMTP password.
        persist({'enabled':False})
        if previous and previous['enabled']:
            try: keyring.delete_password(smtp_sender.KEY_SERVICE, smtp_sender.smtp_key(previous['host'],previous['user']))
            except Exception: pass
        return {'enabled':False}
    if set(data) - {'enabled','host','user','port','mode','password'}:
        raise ValueError('Unsupported settings.')
    settings = smtp_sender.validate_smtp_settings(data)
    # Prevent SMTP from being used for an unrelated mailbox or identity.
    account = json.loads(server.CONFIG.read_text(encoding='utf-8'))
    if settings['user'].casefold() != account.get('user','').casefold():
        raise ValueError('SMTP user must match the locally configured mailbox.')
    secret = data.get('password')
    if not secret and previous and previous['enabled'] and all(previous[k]==settings[k] for k in ('host','user','port','mode')):
        secret = keyring.get_password(smtp_sender.KEY_SERVICE,smtp_sender.smtp_key(settings['host'],settings['user']))
    if not isinstance(secret,str) or not secret or len(secret)>1024:
        raise ValueError('SMTP password is required.')
    # Validate TLS & authentication before enabling anything; do not send test mail.
    c = smtp_sender.smtp_connect(settings,secret)
    try: c.quit()
    except Exception: c.close()
    keyring.set_password(smtp_sender.KEY_SERVICE,smtp_sender.smtp_key(settings['host'],settings['user']),secret)
    persist({'enabled':True,**settings})
    if previous and previous['enabled'] and (previous['host'],previous['user']) != (settings['host'],settings['user']):
        try: keyring.delete_password(smtp_sender.KEY_SERVICE,smtp_sender.smtp_key(previous['host'],previous['user']))
        except Exception: pass
    return {'enabled':True}


if __name__=='__main__':
    try:
        request=json.loads(base64.b64decode(sys.stdin.readline().strip(),validate=True).decode('utf-8'))
        response=set_sending(request)
        print(json.dumps(response))
    except Exception:
        print('SMTP setup failed. Check server, login, TLS and mailbox settings.',file=sys.stderr)
        sys.exit(1)
