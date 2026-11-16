# Webglobe Mail Connector – dokumentácia v slovenčine

**Autor:** **Mgr. Peter Adámek**  
**Web autora:** **https://ai-konzultant.sk/**

> Nezávislý komunitný projekt. Nejde o oficiálny doplnok spoločnosti Webglobe a projekt nie je spoločnosťou Webglobe podporovaný ani schválený.

## Na čo slúži

Webglobe Mail Connector umožňuje ChatGPT alebo kompatibilnému lokálnemu MCP klientovi **čítať a vyhľadávať e-maily** v schránke cez zabezpečené IMAP alebo POP3 spojenie. Získané správy môže AI klient sumarizovať a vytvoriť návrh odpovede priamo v chate.

**Doplnok nikdy neposiela e-maily, nemaže ich, nepresúva ich ani nemení ich stav prečítania.** Návrhy sa neukladajú do priečinka Koncepty. HTML a prílohy sa nespracúvajú.

IMAP podporuje doručenú aj odoslanú poštu a ďalšie priečinky. POP3 podporuje iba INBOX a vyžaduje TLS (port 995), UIDL a TOP; vyhľadávanie je obmedzené na vzorku správ.

## Inštalácia na Windows

1. Stiahni ZIP repozitára z GitHubu a rozbaľ všetky súbory.
2. Spusti `NASTAVIT-UCET.cmd` a potvrď prípravu prostredia.
3. Vyber IMAP alebo POP3. Zadaj správny server poskytovateľa, svoju e-mailovú adresu a heslo **do lokálneho formulára**, nie do chatu.
4. Klikni na **Uložiť a overiť spojenie**. Heslo sa uloží do systémovej kľúčenky Windows.
5. V kompatibilnej desktopovej aplikácii pridaj lokálny MCP doplnok pomocou `mcp.json` alebo postupuj podľa `windows-connect.ps1` a `ZACNITE-TU.txt`.
6. Otvor nový chat a požiadaj o zobrazenie identifikátorov troch posledných správ.

Príklady otázok: „Zobraz dostupné poštové priečinky.“ „Vyhľadaj správy od dodávateľa a zhrň podstatné informácie.“ „Priprav návrh odpovede, ale nič neposielaj.“

## Bezpečnosť

Každý používateľ nastavuje **vlastnú schránku** na vlastnom počítači. Žiadne heslá, súkromné správy ani konfigurácie účtov nepatria do verejného repozitára. Komunikácia s poštovým serverom je šifrovaná. Obsah e-mailov načítaný do chatu spracúva použitá AI služba; neposielaj jej citlivú poštu bez príslušného súhlasu a interných pravidiel.

Inštalátor pri prvom spustení sťahuje `uv` od Astral, Python a závislosti. V spravovanom firemnom prostredí je vhodné najprv skontrolovať tento proces.

## Autorstvo

**Webglobe Mail Connector vytvoril Mgr. Peter Adámek.**  
Web: **https://ai-konzultant.sk/**

Projekt je dostupný pod licenciou **Apache License 2.0**. Pri distribúcii upravených verzií zachovajte požadované autorské oznámenia a súbor [NOTICE](NOTICE). Podmienky sú v [LICENSE](LICENSE).

Viac: [README.md](README.md), [SECURITY.md](SECURITY.md), [ZACNITE-TU.txt](ZACNITE-TU.txt).
