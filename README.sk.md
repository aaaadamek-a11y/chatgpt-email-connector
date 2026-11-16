# Webglobe Mail Connector — návod po slovensky

**Autor:** Mgr. Peter Adámek | AI konzultant  
**Web:** https://ai-konzultant.sk/

Webglobe Mail Connector umožňuje prepojiť ChatGPT s poštovou schránkou cez lokálny MCP server. Podporuje čítanie, vyhľadávanie a sumarizáciu správ prostredníctvom IMAP alebo POP3 a po novom **voliteľné odosielanie cez SMTP**.

## Čo konektor dokáže

- **Čítať a vyhľadávať správy** bez zmeny stavu prečítania. Pri IMAP zobrazí aj dostupné priečinky vrátane odoslanej pošty; POP3 podporuje iba doručenú poštu.
- **Pripravovať návrhy** v konverzácii bez uloženia do e-mailovej schránky.
- **Voliteľne odosielať** textové správy, len ak si to používateľ na svojom počítači samostatne zapne a každé odoslanie potvrdí v grafickom okne.
- **Nikdy nemaže, nepresúva ani neoznačuje správy** ako prečítané.

## Jednoduchá inštalácia a aktualizácia (Windows)

1. Stiahni [aktuálny ZIP z GitHubu](https://github.com/aaaadamek-a11y/chatgpt-email-connector/archive/refs/heads/main.zip) a úplne ho rozbaľ.
2. Spusti **`NASTAVIT.cmd`**. V jednom okne zadaj **e-mailovú adresu a heslo**. Pre bežnú Webglobe schránku sa IMAP server `mail.webglobe.sk` (port 993, TLS) nastaví automaticky.
3. Ak chceš aj **odosielať**, zaškrtni príslušnú voľbu. SMTP je predvolene vypnuté, využije rovnakú e-mailovú adresu a heslo. Každé skutočné odoslanie ešte vyžaduje potvrdenie v samostatnom miestnom okne.
4. Pri staršom serveri Webglobe, inej e-mailovej službe alebo POP3 rozbaľ **Rozšírené nastavenia serverov**. Tu zmeníš IMAP/POP3 alebo SMTP server a zabezpečenie.
5. Klikni **Overiť a uložiť pripojenie**. Sprievodca pripraví lokálny balík `Webglobe-pridat-doplnok.zip`, ktorý potom použiješ na aktualizáciu existujúceho doplnku v kompatibilnom desktopovom klientovi ChatGPT/MCP. Heslo nezadávaj do chatu.

**Pri aktualizácii:** existujúci účet a nastavený server sa zachovajú. Ak nemeníš schránku, heslo môže zostať prázdne; pri prvom zapnutí SMTP ho však bude treba vyplniť. Staré príkazy `NASTAVIT-UCET.cmd` aj `NASTAVIT-ODOSIELANIE.cmd` teraz otvoria ten istý sprievodca.

Nový systém ukladá tajné údaje do systémovej kľúčenky. Na vypnutie SMTP opäť otvor `NASTAVIT.cmd` a zruš zaškrtnutie. Čítanie pošty zostane funkčné.

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

**Oprava 0.8.1:** Opravená chyba PowerShell `Cannot overwrite variable Host because it is read-only or constant` v nastavení účtu. Ak sa objavila, stiahni nový ZIP a znovu spusti `NASTAVIT.cmd`.
