"""Create a local MCP plugin ZIP without touching mailbox data or starting a subprocess.

A previous implementation launched smtp_server.py with tools/list inside a second
Python process. On some Windows uv installations that process failed, hiding the
error behind "Priprava balika doplnku zlyhala". Importing the tool registry directly
is deterministic and works even when no email account is configured.
"""
import json
import os
from pathlib import Path
import sys
import tempfile
import zipfile

VERSION = '0.9.1'
EXPECTED_TOOLS = {'list_messages','search_messages','read_message','list_mailboxes',
                  'prepare_draft','sending_status','send_message','save_draft'}


def build():
    # Only inspect definitions. No IMAP, POP3 or SMTP connection is opened here.
    from smtp_server import TOOLS
    if len(TOOLS) != len(EXPECTED_TOOLS) or {item['name'] for item in TOOLS} != EXPECTED_TOOLS:
        raise RuntimeError('Unexpected tool definitions')
    for tool in TOOLS:
        annot = tool['annotations']
        if not isinstance(annot.get('readOnlyHint'),bool):
            raise RuntimeError('Missing readOnlyHint annotation')
        if tool['name'] in ('send_message','save_draft') and annot['readOnlyHint']:
            raise RuntimeError('A write tool was marked read-only')
        if tool['name'] not in ('send_message','save_draft') and not annot['readOnlyHint']:
            raise RuntimeError('A read tool was marked as a write tool')
    if not next(t for t in TOOLS if t['name']=='send_message')['annotations']['destructiveHint']:
        raise RuntimeError('Sending must retain irreversible-action annotation')

    base = Path(__file__).absolute().parent
    executable = os.path.abspath(sys.executable)
    endpoint = os.path.abspath(str(base/'smtp_server.py'))
    if not Path(executable).is_file() or not Path(endpoint).is_file():
        raise RuntimeError('Python interpreter or MCP server missing')

    manifest={'$schema':'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json',
      'name':'webglobe-mail-connector','version':VERSION,
      'description':'IMAP/POP3 reading, IMAP Drafts and user-approved SMTP; no deletion.',
      'homepage':'https://ai-konzultant.sk/',
      'repository':'https://github.com/aaaadamek-a11y/chatgpt-email-connector',
      'license':'Apache-2.0','author':{'name':'Mgr. Peter Adámek | AI konzultant','url':'https://ai-konzultant.sk/'}}
    config={'$schema':'https://agent-plugins.org/schemas/1.0.0/mcp.schema.json',
      'mcpServers':{'webglobe-mail':{'type':'stdio','command':executable,
                    'args':[endpoint],'cwd':str(base)}}}
    target=base/'Pridat-do-aplikacie'
    target.mkdir(parents=True,exist_ok=True)
    zip_path=target/'Webglobe-pridat-doplnok.zip'
    fd,tmp=tempfile.mkstemp(prefix='.webglobe-',suffix='.zip',dir=target)
    os.close(fd)
    try:
        with zipfile.ZipFile(tmp,'w',zipfile.ZIP_DEFLATED) as z:
            z.writestr('plugin.json',json.dumps(manifest,ensure_ascii=False,indent=2))
            z.writestr('mcp.json',json.dumps(config,ensure_ascii=False,indent=2))
        with zipfile.ZipFile(tmp) as z:
            if z.testzip() is not None or set(z.namelist()) != {'plugin.json','mcp.json'}:
                raise RuntimeError('Generated archive failed verification')
        os.replace(tmp,zip_path)
    finally:
        if os.path.exists(tmp): os.unlink(tmp)

    (target/'AKO-PRIDAT.txt').write_text(
      'Importujte Webglobe-pridat-doplnok.zip do kompatibilneho lokalneho MCP klienta.\n'
      'Ukladanie do Konceptov vyzaduje IMAP a prikaz uzivatela.\n'
      'SMTP sa povoli az po uspesnom overeni a kazde odoslanie vyzaduje lokalne potvrdenie.\n'
      'Mazanie nie je podporovane.\n',encoding='utf-8')
    return zip_path


if __name__=='__main__':
    try:
        print(build())
    except Exception as exc:
        # Diagnostic information intentionally omits exception messages, arguments,
        # credentials and mailbox content.
        print('Package creation failed (' + type(exc).__name__ + ').',
              file=sys.stderr)
        sys.exit(1)
