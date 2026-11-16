"""Build a machine-specific plugin, without mailbox data or credentials."""
import json
from pathlib import Path
import subprocess
import sys
import zipfile

VERSION = '0.6.1'

def build(destination, interpreter=None, server=None, verify=True):
    destination = Path(destination).resolve()
    interpreter = str(Path(interpreter or sys.executable).resolve())
    server = str(Path(server or Path(__file__).with_name('server.py')).resolve())
    if verify:
        request = {'jsonrpc':'2.0','id':1,'method':'tools/list'}
        p = subprocess.run([interpreter, server], input=json.dumps(request)+'\n', capture_output=True, text=True, timeout=15, check=True)
        tools = json.loads(p.stdout)['result']['tools']
        if {t['name'] for t in tools} != {'list_messages','search_messages','read_message','list_mailboxes','prepare_draft'}:
            raise ValueError('Unexpected tools')
        if not all(t['annotations']['readOnlyHint'] for t in tools):
            raise ValueError('Tools must be read only')
    manifest = {'$schema':'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json',
                'name':'webglobe-mail-connector','version':VERSION,
                'description':'Local read-only Webglobe IMAP tools. This package uses the current Windows user account.',
                'homepage':'https://ad.amek.sk',
                'author':{'name':'Mgr. Peter Adámek','url':'https://ad.amek.sk'}}
    config = {'$schema':'https://agent-plugins.org/schemas/1.0.0/mcp.schema.json',
              'mcpServers':{'webglobe-mail':{'type':'stdio','command':interpreter,'args':[server],'cwd':str(Path(server).parent)}}}
    destination.mkdir(parents=True, exist_ok=True)
    archive = destination / 'Webglobe-pridat-doplnok.zip'
    temporary = archive.with_suffix('.tmp')
    with zipfile.ZipFile(temporary, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('plugin.json', json.dumps(manifest, ensure_ascii=False, indent=2))
        z.writestr('mcp.json', json.dumps(config, ensure_ascii=False, indent=2))
    with zipfile.ZipFile(temporary) as z:
        if z.testzip() is not None: raise ValueError('Invalid ZIP')
    temporary.replace(archive)
    # A plain text fallback avoids copying escaped JSON paths.
    instructions = ('WEBGLOBE - PRIDANIE DO DESKTOPOVEJ APLIKACIE\n\n'
        'V Nastavenia > Doplnky > Pridat vyberte import doplnku zo ZIP, ak ho aplikacia ponuka.\n'
        'Vyberte Webglobe-pridat-doplnok.zip a skontrolujte zobrazene opravnenia.\n'
        'Import v cielovej aplikacii este nie je overeny. Ak import chyba, pouzite formular vlastneho MCP:\n\n'
        'Meno: Webglobe Mail\nTyp: STDIO\nPrikaz na spustenie (cely riadok):\n'+interpreter+
        '\n\nJeden argument (cely riadok):\n'+server+'\n\nPracovny adresar:\n'+str(Path(server).parent)+
        '\n\nPremenne prostredia nechajte prazdne. Heslo sa sem nezadava.\n'
        'Tento vytvoreny ZIP je iba pre tento pocitac. Kolegom poslite povodny instalacny balik.\n'
        'Po pridani zapnite doplnok v chate. Najprv vyziadajte list_messages s limitom 3.\n'
        'Potom vyhladajte existujucu neskodnu spravu a poziadajte o jej suhrn. Nic neposielajte ani nemente.\n')
    (destination/'AKO-PRIDAT.txt').write_text(instructions, encoding='utf-8-sig')
    return archive

if __name__ == '__main__':
    print(build(Path(__file__).resolve().parent / 'Pridat-do-aplikacie'))
