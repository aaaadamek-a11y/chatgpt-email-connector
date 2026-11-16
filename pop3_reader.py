"""POP3 SSL read-only adapter. Never uses RETR or DELE; requires UIDL and TOP."""
import base64
import hashlib
import poplib
import ssl
import time

MAX_BYTES = 500_000
SCAN_MESSAGES = 50
SCAN_BYTES = 5_000_000
SCAN_SECONDS = 20

class MailError(ValueError):
    """Safe, user-facing error with no server/credential details."""

class LimitedPOP3(poplib.POP3_SSL):
    # Bound every multi-line response, even if the server misreports LIST size.
    response_limit = 10_000_000
    def _getlongresp(self):
        self._response_bytes = 0
        return super()._getlongresp()
    def _getline(self):
        line, size = super()._getline()
        self._response_bytes = getattr(self, '_response_bytes', 0) + size
        if self._response_bytes > self.response_limit:
            self.close()
            raise MailError('POP3 response exceeded the safe size limit. Connection closed.')
        return line, size

def open_pop(cfg, password, factory=LimitedPOP3):
    c=factory(cfg['host'],995,context=ssl.create_default_context(),timeout=15)
    try:
        c.user(cfg['user']);c.pass_(password)
        return c
    except Exception:
        c.close()
        raise

def identity(cfg):
    # Bind stable IDs to account + endpoint; never expose either in the response.
    value=('POP3\0'+cfg['host'].lower()+'\0'+cfg['user']).encode('utf-8')
    return str(int.from_bytes(hashlib.sha256(value).digest()[:8],'big'))

def token(uid):
    return 'pop3:'+base64.urlsafe_b64encode(uid).decode('ascii').rstrip('=')

def identifiers(c):
    try: lines=c.uidl()[1]
    except poplib.error_proto:
        raise MailError('This POP3 server does not support UIDL. Stable message reading requires UIDL; use IMAP instead.') from None
    rows=[];seen=set()
    for line in lines:
        parts=line.split()
        if len(parts)!=2 or not parts[0].isdigit() or not parts[1] or parts[1] in seen:
            raise MailError('Invalid or duplicate POP3 UIDL response.')
        seen.add(parts[1]);rows.append((int(parts[0]),parts[1]))
    return sorted(rows,reverse=True)

def read_top(c, number, size):
    if size < 0 or size > MAX_BYTES:raise MailError('Message exceeds the 500 KB limit.')
    c.response_limit=MAX_BYTES+10_000
    try:
        # At most MAX_BYTES lines can occur in a message below MAX_BYTES bytes.
        # Request the full plain message using TOP, which does not set seen flags.
        response,lines,_=c.top(number,MAX_BYTES)
    except poplib.error_proto:
        raise MailError('This POP3 server rejected TOP. To avoid changing read status, RETR is not used. Use IMAP instead.') from None
    finally:c.response_limit=10_000_000
    raw=b'\r\n'.join(lines)+b'\r\n'
    if len(raw)>MAX_BYTES:raise MailError('Message exceeds the 500 KB limit.')
    return raw

def run(name,args,cfg,password,parse_message,factory=open_pop):
    mailbox=args.get('mailbox','INBOX')
    if not isinstance(mailbox,str) or mailbox.upper()!='INBOX':
        raise MailError('POP3 provides only INBOX. Sent mail and other folders require IMAP.')
    if name=='list_mailboxes':
        return {'protocol':'POP3','mailboxes':[{'mailbox':'INBOX','sent':False}],
                'notice':'POP3 has no sent folder; use IMAP for sent mail.'}
    limit=args.get('limit',5)
    if type(limit) is not int or not 1<=limit<=20:raise MailError('Limit must be between 1 and 20.')
    if name=='search_messages':
        query=args.get('query','')
        if not isinstance(query,str) or not query or len(query)>200 or not query.isascii() or any(ord(x)<32 for x in query):
            raise MailError('Search requires 1-200 printable ASCII characters.')
    if name=='read_message':
        if not isinstance(args.get('uid'),str) or not args['uid'].startswith('pop3:'):
            raise MailError('Use a POP3 UID returned by a new list or search, not an IMAP UID.')
        if str(args.get('uidvalidity'))!=identity(cfg):raise MailError('The configured account changed; list messages again.')
    c=factory(cfg,password)
    try:
        rows=identifiers(c);validity=identity(cfg)
        common={'protocol':'POP3','mailbox':'INBOX','scope':'INBOX','uidvalidity':validity,
                'ordering':'descending POP3 session message number; not sorted by Date header'}
        if name=='list_messages':
            return dict(common,uids=[token(uid) for _,uid in rows[:limit]],matches=len(rows))
        if name=='read_message':
            number=next((num for num,uid in rows if token(uid)==args['uid']),None)
            if number is None:raise MailError('Message is no longer on the server. List messages again.')
            size=int(c.list(number).split()[2])
            return dict(common,uid=args['uid'],**parse_message(read_top(c,number,size)))
        if name!='search_messages':raise MailError('Unknown POP3 operation.')
        sizes={int(line.split()[0]):int(line.split()[1]) for line in c.list()[1]}
        results=[];scanned=0;skipped=0;transferred=0;examined=0;started=time.monotonic()
        for number,uid in rows[:SCAN_MESSAGES]:
            if time.monotonic()-started>=SCAN_SECONDS:break
            size=sizes.get(number,MAX_BYTES+1)
            if size>MAX_BYTES or size<0:skipped+=1;examined+=1;continue
            if transferred+size>SCAN_BYTES:break
            parsed=parse_message(read_top(c,number,size));transferred+=size;scanned+=1;examined+=1
            hay='\n'.join(str(parsed.get(k,'')) for k in ('subject','from','date','text')).casefold()
            if query.casefold() in hay:results.append(token(uid))
        complete=examined==len(rows) and skipped==0
        return dict(common,uids=results[:limit],matches=len(results),total_messages=len(rows),
                    scanned_messages=scanned,skipped_messages=skipped,search_complete=complete,
                    search_scope='Headers and up to 24000 plain-text characters per message; newest 50 session message numbers, at most 5 MB and 20 seconds plus one in-flight command.',
                    notice='matches counts only scanned messages, not the whole mailbox. No local search index is saved.')
    finally:
        try:c.quit()
        except Exception:c.close()
