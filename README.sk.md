# Webglobe Mail Connector — návod po slovensky

**Autor:** Mgr. Peter Adámek | AI konzultant  
**Web:** https://ai-konzultant.sk/

Webglobe Mail Connector umožňuje prepojiť ChatGPT s poštovou schránkou cez lokálny MCP server. Podporuje čítanie, vyhľadávanie a sumarizáciu správ prostredníctvom IMAP alebo POP3 a po novom **voliteľné odosielanie cez SMTP**.

## Čo konektor dokáže

- **Čítať a vyhľadávať správy** bez zmeny stavu prečítania. Pri IMAP zobrazí aj dostupné priečinky vrátane odoslanej pošty; POP3 podporuje iba doručenú poštu.
- **Pripravovať návrhy** v konverzácii bez uloženia do e-mailovej schránky.
- **Voliteľne odosielať** textové správy, len ak si to používateľ na svojom počítači samostatne zapne a každé odoslanie potvrdí v grafickom okne.
- **Nikdy nemaže, nepresúva ani neoznačuje správy** ako prečítané.

## Ako zapnúť odosielanie

1. Najprv nastavte čítanie pošty cez `NASTAVIT-UCET.cmd`.
2. Spustite **`NASTAVIT-ODOSIELANIE.cmd`**. Predvolene je voľba odosielania **vypnutá**.
3. Zaškrtnite „Povoliť odosielanie e-mailov“, nastavte SMTP server, zabezpečenie (SSL port 465 alebo STARTTLS port 587), používateľské meno rovnaké ako nastavená schránka a heslo.
4. Uložte nastavenia; overí sa SMTP autentifikácia bez poslania skúšobného e-mailu. Heslo sa uloží oddelene do systémovej kľúčenky Windows.
5. Obnovte alebo znovu importujte vytvorený lokálny MCP doplnok. V chate sa môžete spýtať na `sending_status`.
6. Ak požiadate ChatGPT o odoslanie konkrétnej správy, vždy sa zobrazí samostatné **lokálne okno s príjemcami, predmetom a celým textom**. Musíte kliknúť na tlačidlo „Potvrdzujem – ODOSLAŤ“. Ak okno zatvoríte alebo zrušíte, nič sa neodošle.

**Vypnutie:** Opäť spustite `NASTAVIT-ODOSIELANIE.cmd`, zrušte zaškrtnutie a uložte. Funkcie čítania zostanú aktívne. Každý kolega má svoje vlastné nastavenie.

### Webglobe SMTP

Pre bežné schránky je uvádzaný server `mail.webglobe.sk`, port `465` (SSL) alebo `587` (STARTTLS). Pri inej platforme overte presný hostname u poskytovateľa. Pripojenie na nezašifrovanom porte 25 konektor nepodporuje.

### Bezpečnosť a obmedzenia

- SMTP vyžaduje šifrovanie a prihlásenie; nemôže odoslať správu v mene ľubovoľnej cudzej adresy.
- Doplnok odosiela iba čistý text bez príloh; maximálne 20 adresátov celkovo.
- Obsah e-mailov je nedôveryhodný. Pokyny obsiahnuté v prijatých správach **nesmú** spustiť odosielanie.
- E-mail prijatý SMTP serverom nemusí byť automaticky uložený do priečinka Odoslané. Ak spojenie zlyhá, najprv overte stav pred opakovaním odoslania.
- Heslá nezadávajte do chatu ani ich nikdy nezverejňujte v GitHube.
- Funkcia odosielania musí byť otestovaná na reálnom Windows zariadení s Webglobe SMTP. Automatické testy nepredstavujú potvrdenie odoslania v produkcii.

## Autorstvo a licencia

**Original author: Mgr. Peter Adámek | AI konzultant**  
**Website: https://ai-konzultant.sk/**

Licencia **Apache 2.0** vyžaduje pri ďalšej distribúcii zachovať príslušné licenčné a autorské oznámenia. Pozri [LICENSE](LICENSE) a [NOTICE](NOTICE).

Toto je nezávislý komunitný projekt, nejde o oficiálny produkt Webglobe.
