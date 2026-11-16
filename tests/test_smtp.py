"""Offline tests for opt-in SMTP safety gates. No real message is sent."""
import importlib
import json
from pathlib import Path
import sys
import tempfile
import types
import unittest
from unittest.mock import Mock

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:sys.path.insert(0,str(ROOT))

class FakeKeyring:
    def __init__(self): self.data={}
    def get_password(self,service,key):return self.data.get((service,key))
    def set_password(self,service,key,password):self.data[(service,key)]=password
    def delete_password(self,service,key):self.data.pop((service,key),None)

server = types.ModuleType('server')
server.SERVICE = 'webglobe-mail-connector'
server.CONFIG = Path('/nonexistent/account.json')
server.TOOLS = [{'name':x,'annotations':{'readOnlyHint':True}} for x in ('list_messages','search_messages','read_message','list_mailboxes','prepare_draft')]
server.dispatch=lambda req:{'serverInfo':{'version':'0.6.1'}} if req.get('method')=='initialize' else {'tools':server.TOOLS}
server.write_response=lambda x:None
keyring=FakeKeyring()
server.secure_keyring=lambda:keyring
sys.modules['server']=server
import smtp_sender
import sending_setup
import smtp_server

class DummySMTP:
    def __init__(self):self.sent=[];self.quit_count=0;self.logged=[];self.upgraded=False
    def ehlo(self):pass
    def has_extn(self,x):return x.lower()=='starttls'
    def starttls(self,context=None):self.upgraded=True
    def login(self,user,pw):self.logged.append((user,pw))
    def send_message(self,message,from_addr,to_addrs):self.sent.append((message,from_addr,to_addrs))
    def quit(self):self.quit_count+=1
    def close(self):pass

class TestSMTP(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        server.CONFIG=Path(self.tmp.name)/'account.json'
        server.CONFIG.write_text(json.dumps({'user':'person@example.com','protocol':'IMAP','host':'imap.example.com'}))
        smtp_sender.SENDING_CONFIG=Path(self.tmp.name)/'sending.json'
        keyring.data.clear()
    def cfg(self):
        return {'enabled':True,'host':'mail.example.com','port':465,'mode':'SSL','user':'person@example.com'}
    def args(self):
        return {'to':['recipient@example.com'],'cc':['copy@example.com'], 'bcc':['hidden@example.com'],
                'subject':'Potvrdenie','body':'Dobrý deň,\nďakujem.'}
    def enabled(self):
        smtp_sender.SENDING_CONFIG.write_text(json.dumps(self.cfg()))
        keyring.set_password(smtp_sender.KEY_SERVICE,smtp_sender.smtp_key('mail.example.com','person@example.com'),'test-only')
    def test_disabled_by_default(self):
        self.assertFalse(smtp_sender.status()['enabled'])
        with self.assertRaisesRegex(smtp_sender.SendingError,'disabled'):
            smtp_sender.send_message(self.args(), confirmer=lambda _:True)
    def test_bad_subject_rejected(self):
        self.enabled();p=self.args();p['subject']='a\nBcc: attacker@example.com'
        with self.assertRaisesRegex(smtp_sender.SendingError,'subject'):
            smtp_sender.send_message(p, confirmer=lambda _:True)
    def test_bad_recipients_rejected(self):
        self.enabled();p=self.args();p['to']=['x@example.com\r\nBcc:bad@example.com']
        with self.assertRaises(smtp_sender.SendingError):
            smtp_sender.send_message(p, confirmer=lambda _:True)
    def test_confirmation_declined_no_smtp(self):
        self.enabled();spy=Mock()
        result=smtp_sender.send_message(self.args(), confirmer=lambda _:False, smtp_opener=spy)
        self.assertEqual(result['status'],'cancelled'); spy.assert_not_called()
    def test_confirmation_required_and_bcc_hidden(self):
        self.enabled();dummy=DummySMTP();approved=[]
        out=smtp_sender.send_message(self.args(), confirmer=lambda m:(approved.append(m),True)[1],smtp_opener=lambda cfg,pw:dummy)
        self.assertEqual(out['status'],'sent');self.assertEqual(len(dummy.sent),1)
        msg,sender,recs=dummy.sent[0]
        self.assertEqual(sender,'person@example.com')
        self.assertEqual(recs,['recipient@example.com','copy@example.com','hidden@example.com'])
        self.assertNotIn('Bcc',msg)
        self.assertEqual(approved[0]['body'],self.args()['body'])
    def test_send_is_marked_write_irreversible(self):
        x={t['name']:t for t in smtp_server.dispatch({'method':'tools/list'})['tools']}
        self.assertFalse(x['send_message']['annotations']['readOnlyHint'])
        self.assertTrue(x['send_message']['annotations']['destructiveHint'])
        for name in ('list_messages','search_messages','read_message','list_mailboxes','prepare_draft','sending_status'):
            self.assertTrue(x[name]['annotations']['readOnlyHint'])
        self.assertNotIn('delete_message',x)
        self.assertNotIn('move_message',x)
    def test_enabled_state_invalid_on_account_switch(self):
        self.enabled();server.CONFIG.write_text(json.dumps({'user':'someoneelse@example.com'}))
        with self.assertRaises(smtp_sender.SendingError):smtp_sender.status()
    def test_disable_removes_credentials(self):
        self.enabled()
        self.assertFalse(sending_setup.set_sending({'enabled':False})['enabled'])
        self.assertFalse(smtp_sender.status()['enabled'])
        self.assertFalse(keyring.data)
    def test_enable_requires_login_and_correct_mailbox(self):
        bad={**self.cfg(),'password':'dummy','user':'other@example.com'}
        with self.assertRaisesRegex(ValueError,'match'):
            sending_setup.set_sending(bad)
        self.assertFalse(smtp_sender.status()['enabled'])
    def test_tls_smtp_supported_only_secure_ports(self):
        for data in ({**self.cfg(),'port':25},{**self.cfg(),'port':587}, {**self.cfg(),'mode':'PLAIN'}):
            with self.assertRaises(smtp_sender.SendingError):smtp_sender.validate_smtp_settings(data)
    def test_smtps_and_starttls_login(self):
        first=DummySMTP();second=DummySMTP()
        c=smtp_sender.smtp_connect(self.cfg(),'password',factory_ssl=lambda *a,**k:first)
        self.assertIs(c,first);self.assertEqual(first.logged,[('person@example.com','password')])
        c=smtp_sender.smtp_connect({**self.cfg(),'mode':'STARTTLS','port':587},'password',factory_starttls=lambda *a,**k:second)
        self.assertIs(c,second);self.assertTrue(second.upgraded)
        self.assertEqual(second.logged,[('person@example.com','password')])
    def test_no_gui_fail_closed(self):
        from send_confirmation import confirm_message
        # Test refusal for invalid/headless Tk by preventing import of tkinter.
        with unittest.mock.patch.dict(sys.modules,{'tkinter':None}):
            self.assertFalse(confirm_message(self.args()))

if __name__=='__main__': unittest.main()
