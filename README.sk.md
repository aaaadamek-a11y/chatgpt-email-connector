# Webglobe Mail Connector — návod po slovensky

**Autor:** Mgr. Peter Adámek | AI konzultant  
**Web:** https://ai-konzultant.sk/

Webglobe Mail Connector umožňuje prepojiť ChatGPT s poštovou schránkou cez lokálny MCP server. Podporuje čítanie, vyhľadávanie a sumarizáciu správ prostredníctvom IMAP alebo POP3 a po novom **voliteľné odosielanie cez SMTP**.

## Čo konektor dokáže

- **Čítať a vyhľadávať správy** bez zmeny stavu prečítania. Pri IMAP zobrazí aj dostupné priečinky vrátane odoslanej pošty; POP3 podporuje iba doručenú poštu.
- **Pripravovať návrhy** v konverzácii bez uloženia do e-mailovej schránky.
- **Voliteľne odosielať** textové správy, len ak si to používateľ na svojom počítači samostatne zapne a každé odoslanie potvrdí v grafickom okne.
- **Nikdy nemaže, nepresúva ani neoznačuje správy** ako prečítané.

**Oprava 0.8.2:** Inštalátor obsahuje knižnice potrebné pre Windows Credential Manager aj bez prístupu na PyPI. Ak už máš funkčné Python prostredie, nebude ich znova sťahovať. Ak zlyhá príprava závislostí, zobrazí cestu k diagnostickému súboru `dependency-stderr.log` v priečinku `%LOCALAPPDATA%\WebglobeMailConnector`. Súbor pred zdieľaním skontroluj na osobné údaje. Pri chybe 0.8.1 si stiahni novší EXE z Releases.

## Jednosúborová inštalácia pre Windows (EXE)

Pre bežných používateľov je pripravený **inštalátor pozostávajúci z jedného súboru** `Webglobe-Mail-Connector-Setup-0.8.2.exe`. Zdrojový kód a dokumentácia zostávajú verejné na GitHube.

- **[GitHub Releases](https://github.com/aaaadamek-a11y/chatgpt-email-connector/releases)** – tu bude dostupný EXE po úspešnom zostavení, otestovaní a vydaní verzie.
- **[GitHub Actions – zostavenie EXE](https://github.com/aaaadamek-a11y/chatgpt-email-connector/actions/workflows/build-windows-exe.yml)** – zostavené súbory sú dostupné ako artefakty úspešného behu. GitHub môže vyžadovať prihlásenie.
- EXE rozbalí potrebné súbory do používateľského profilu a po dokončení ponúkne otvorenie jedného nastavenia. **Nie je nutné manuálne rozbaľovať zdrojový ZIP.**
- Pri prvom nastavení sa môže stiahnuť `uv`, Python a závislosti; používateľ ich nemusí inštalovať ručne.
- Osobné nastavenia a heslá zostávajú oddelené od inštalátora. SMTP je predvolene vypnuté; odoslanie vyžaduje lokálne potvrdenie a mazanie správ nie je podporované.
- Inštalátor zatiaľ nie je digitálne podpísaný, preto môže Windows SmartScreen zobraziť upozornenie. Sťahujte ho iba z oficiálneho repozitára a overte jeho pôvod.
- Po nastavení sa môže vyžadovať import alebo aktualizácia vygenerovaného lokálneho MCP balíka priamo v ChatGPT. Inštalátor nevykonáva automatické zásahy do účtu ChatGPT.

**Pre vývojárov** zostáva zachovaný postup so zdrojovým ZIP. Skript na vytvorenie EXE je `installer/webglobe.iss`, automatická zostava je v `.github/workflows/build-windows-exe.yml`. Reálne pripojenie ku konkrétnemu poštovému serveru treba otestovať samostatne.

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

**Oprava 0.8.2:** Opravená chyba PowerShell `Cannot overwrite variable Host because it is read-only or constant` v nastavení účtu. Ak sa objavila, stiahni nový ZIP a znovu spusti `NASTAVIT.cmd`.
