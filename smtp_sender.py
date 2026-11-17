"""Opt-in SMTP delivery for the local Webglobe MCP plugin.

No SMTP operation is available unless the user enables it locally. Each delivery
requires an independent, user-visible confirmation showing the entire message.
"""
from email.message import EmailMessage
import json
from pathlib import Path
import re
import smtplib
import ssl

import server

SENDING_CONFIG = server.CONFIG.with_name('sending.json')
KEY_SERVICE = server.SERVICE + '-smtp'
MAX_BODY = 24000
MAX_RECIPIENTS = 20
ADDRESS = re.compile(r'[^\s<>@,;\x00-\x1f\x7f]+@[^\s<>@,;\x00-\x1f\x7f]+\.[^\s<>@,;\x00-\x1f\x7f]+\Z')

class SendingError(Exception):
    """Sanitized public-facing sender exception."""


def smtp_key(host, user):
    return host.lower() + '|' + user.lower()


def validate_address(s):
    return isinstance(s, str) and len(s) <= 254 and '\r' not in s and '\n' not in s and s.isascii() and ADDRESS.fullmatch(s) is not None


def validate_smtp_settings(settings):
    host = settings.get('host')
    user = settings.get('user')
    port = settings.get('port')
    mode = settings.get('mode')
    if not isinstance(host, str) or not host or len(host) > 253 or any(ch in host for ch in '/:@\\ ') or not host.isascii() or any(ord(c) < 33 for c in host):
        raise SendingError('Invalid SMTP hostname.')
    if not validate_address(user):
        raise SendingError('SMTP login must be an email address.')
    if type(port) is not int or (port, mode) not in ((465, 'SSL'), (587, 'STARTTLS')):
        raise SendingError('Only SMTP SSL on 465 or STARTTLS on 587 is supported.')
    return {'host':host, 'user':user, 'port':port, 'mode':mode}


def read_settings():
    if not SENDING_CONFIG.is_file():
        return {'enabled':False}
    try:
        data = json.loads(SENDING_CONFIG.read_text(encoding='utf-8'))
        if type(data) is not dict or type(data.get('enabled')) is not bool:
            raise ValueError()
        if not data['enabled']:
            return {'enabled':False}
        settings = validate_smtp_settings(data)
        account = json.loads(server.CONFIG.read_text(encoding='utf-8'))
        if account.get('user','').casefold() != settings['user'].casefold():
            raise SendingError('SMTP user differs from the configured mailbox. Disable and configure again.')
        return {'enabled':True, **settings}
    except SendingError:
        raise
    except Exception:
        raise SendingError('SMTP configuration is invalid. Reconfigure sending locally.') from None


def status():
    settings = read_settings()
    if not settings['enabled']:
        return {'enabled':False,'note':'Sending is not configured or is disabled. Use NASTAVIT.cmd locally to configure it.'}
    return {'enabled':True,'host':settings['host'],'port':settings['port'],'mode':settings['mode'],
            'user':settings['user'],'note':'Each message requires explicit local confirmation.'}


def smtp_connect(settings, password, factory_ssl=smtplib.SMTP_SSL, factory_starttls=smtplib.SMTP):
    context = ssl.create_default_context()
    if settings['mode'] == 'SSL':
        c = factory_ssl(settings['host'], settings['port'], context=context, timeout=20)
    else:
        c = factory_starttls(settings['host'], settings['port'], timeout=20)
        try:
            c.ehlo()
            if not c.has_extn('starttls'):
                raise SendingError('Server does not support required STARTTLS.')
            c.starttls(context=context)
            c.ehlo()
        except Exception:
            try: c.close()
            except Exception: pass
            raise
    try:
        c.login(settings['user'], password)
    except Exception:
        try: c.close()
        except Exception: pass
        raise
    return c


def addresses(args, field):
    value = args.get(field, [])
    if not isinstance(value, list) or any(not validate_address(x) for x in value):
        raise SendingError('Supply explicit, valid recipient addresses.')
    return value


def send_message(args, confirmer=None, smtp_opener=smtp_connect):
    if not isinstance(args, dict) or set(args) - {'to', 'cc', 'bcc', 'subject', 'body'}:
        raise SendingError('Unsupported send arguments.')
    settings = read_settings()
    if not settings['enabled']:
        raise SendingError('Sending is disabled. Run NASTAVIT.cmd on this PC first.')
    to, cc, bcc = (addresses(args,k) for k in ('to','cc','bcc'))
    all_recipients = list(dict.fromkeys(to + cc + bcc))
    if not to or len(all_recipients) > MAX_RECIPIENTS:
        raise SendingError('At least one To recipient and no more than 20 unique recipients are required.')
    subject = args.get('subject')
    body = args.get('body')
    if not isinstance(subject,str) or not subject or len(subject) > 500 or any(ord(c) < 32 for c in subject):
        raise SendingError('Invalid email subject.')
    if not isinstance(body,str) or not body or len(body)>MAX_BODY or '\x00' in body:
        raise SendingError('Invalid email body.')
    msg = EmailMessage()
    msg['From'] = settings['user']  # No caller-supplied From or sender spoofing.
    msg['To'] = ', '.join(to)
    if cc: msg['Cc'] = ', '.join(cc)
    msg['Subject'] = subject
    msg.set_content(body)
    if confirmer is None:
        from send_confirmation import confirm_message
        confirmer = confirm_message
    if confirmer({'from':settings['user'], 'to':to,'cc':cc,'bcc':bcc,'subject':subject,'body':body}) is not True:
        return {'status':'cancelled', 'sent':False, 'note':'User did not approve the local confirmation.'}
    # Re-read settings after the dialog in case the user disabled sending meanwhile.
    if read_settings() != settings:
        raise SendingError('Sending settings changed. Review and confirm the draft again.')
    secret = server.secure_keyring().get_password(KEY_SERVICE, smtp_key(settings['host'],settings['user']))
    if not secret:
        raise SendingError('SMTP credentials are missing. Reconfigure sending locally.')
    try:
        c = smtp_opener(settings,secret)
        try:
            c.send_message(msg, from_addr=settings['user'], to_addrs=all_recipients)
        finally:
            try: c.quit()
            except Exception: c.close()
    except Exception:
        # A network error after DATA may mean delivery happened: never auto-retry.
        raise SendingError('SMTP delivery could not be confirmed. Check the mailbox before retrying; the message might have been accepted.') from None
    return {'status':'sent','sent':True,'from':settings['user'],'to':to,'cc':cc,'bcc':bcc,
            'subject':subject,'notice':'SMTP server accepted the message; recipient delivery is not guaranteed.'}
