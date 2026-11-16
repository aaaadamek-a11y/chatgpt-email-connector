"""Export the installed local read/write MCP endpoint (never includes credentials)."""
import json
from pathlib import Path
import subprocess
import sys
import zipfile

VERSION = '0.8.1'

def build():
    base = Path(__file__).resolve().parent
    python = str(Path(sys.executable).resolve())
    script = str((base / 'smtp_server.py').resolve())
    request = {'jsonrpc':'2.0','id':1,'method':'tools/list'}
    p=subprocess.run([python,script],input=json.dumps(request)+'\n',text=True,capture_output=True,timeout=15,check=True)
    tools = json.loads(p.stdout)['result']['tools']
    names = {tool['name'] for tool in tools}
    if names != {'list_messages','search_messages','read_message','list_mailboxes','prepare_draft','sending_status','send_message'}:
        raise RuntimeError('Unexpected MCP tools.')
    if any((t['name']=='send_message') == t['annotations']['readOnlyHint'] for t in tools):
        raise RuntimeError('Incorrect read/write tool permissions.')
    manifest={'$schema':'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json',
      'name':'webglobe-mail-connector','version':VERSION,
      'description':'Easy setup for IMAP/POP3 reading and optional user-confirmed SMTP sending; no deletion.',
      'homepage':'https://ai-konzultant.sk/',
      'repository':'https://github.com/aaaadamek-a11y/chatgpt-email-connector',
      'license':'Apache-2.0','author':{'name':'Mgr. Peter Adámek | AI konzultant','url':'https://ai-konzultant.sk/'}}
    config={'$schema':'https://agent-plugins.org/schemas/1.0.0/mcp.schema.json',
      'mcpServers':{'webglobe-mail':{'type':'stdio','command':python,'args':[script],'cwd':str(base)}}}
    target=base/'Pridat-do-aplikacie';target.mkdir(exist_ok=True)
    zip_path=target/'Webglobe-pridat-doplnok.zip'
    with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('plugin.json',json.dumps(manifest,ensure_ascii=False,indent=2))
        z.writestr('mcp.json',json.dumps(config,ensure_ascii=False,indent=2))
    (target/'AKO-PRIDAT.txt').write_text('Importujte Webglobe-pridat-doplnok.zip do podporovaneho lokalneho MCP klienta.\n'
      'Odosielanie je predvolene vypnute. Nastavujte ho cez NASTAVIT.cmd.\n'
      'Pri kazdom odoslani musite potvrdit spravu v lokalnom okne. Mazanie nie je podporovane.\n',encoding='utf-8')
    return zip_path

if __name__=='__main__':
    print(build())
