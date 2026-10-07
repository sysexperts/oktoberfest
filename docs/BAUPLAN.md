# Bauplan (Entwurf)

Stand 06.10.2026. Wie wir den Plan umsetzen, in welcher Reihenfolge, mit grober Aufwandsschätzung. **Gebaut wird erst auf dein Kommando.**
**Aufwand** in „Sitzungen" (eine Sitzung = ein zusammenhängender Arbeitsblock mit mir): **S** = 0,5 · **M** = 1 · **L** = 3 · **XL** = 5 · **XXL** = 8. Das sind Schätzungen, die sich beim Bauen verschieben. Summe unten.

## ÜBERGABE: Stand und Arbeitsweise (für die nächste KI oder Sitzung)

**Stand 07.10.2026, Version v356.** Die Story von Kapitel 1 bis 5 ist als Daten und Logik spielbar und per Tests belegt. Offene Arbeit steht in den Tabellen oben (☐ und ◐). Gebaut wird **selbständig weiter**, der Nutzer (Serdar) will nach jedem Schritt in diesem Bauplan sehen, was erledigt ist (✔, ◐ teilweise, ☐ offen).

### Regeln des Nutzers (unbedingt einhalten)
- **Immer Deutsch antworten, kurz und ohne Fachwörter-Flut.** Rückfragen nur, wenn wirklich nötig.
- **Alles als Szenen/Knoten (.tscn) im Editor-Stil**, keine prozedural gebauten Oberflächen (Zeilen aus instanzierten Szenen sind die Ausnahme).
- **Nur echte deutsche Namen** (Horst, Konrad, Gerhard, Herr Schneider, Frau Wagner, Dieter Maier, Gustav). Nie erfundene Mundartnamen. Das Wort **„Wiesn" ist geschützt** und darf nirgends vorkommen (Zeitung heißt „Festblatt", Bank „Festbank").
- **Festleiter Horst** (in allen Sprachen), Konrad ohne Nachnamen. Horst gehört das Festbüro nicht, es ist das **Festbüro des Spielers** („dein Festbüro"). In Mails des Amts: „Sehr geehrte Herren und Damen", nie „Herr".
- Texte immer **Deutsch, Englisch, Türkisch** in `locale/texte.csv` (Spalten: Schlüssel, de, en, tr). Du-/Ihr-Form: Schlüssel mit `_DU` und `_IHR` (Koop), sonst ein neutraler Schlüssel.
- **Committen und pushen** nach jedem fertigen Schritt (Version in `project.godot` unter `config/version` hochzählen, Commit-Text endet mit `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`). **Steam-Upload nur, wenn der Nutzer es verlangt** (`bash tools/steam_upload.sh`, BuildID nennen; Branch setzt der Nutzer in Steamworks). Zum Upload gehört ein `git push`. Die zwei ZIPs in `assets/animationen_mixamo` nie mit hinzufügen (`git add -A -- . ':!assets/animationen_mixamo'`).
- **3D-Modelle** selbst in Blender bauen (`"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/<name>.py`, Beispiel `tools/blender/sau.py`) oder kostenlose CC0-Sets suchen und Quelle und Lizenz in `docs/lizenzen` festhalten. Kein Meshy.
- Beim Spielstart darf es **nicht ruckeln** (Besucher werden gestaffelt gebaut, siehe `scripts/crowd.gd`).

### Werkzeuge und Pfade
- Godot: `"C:/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe"` (Version 4.7.2). Nach Änderungen an Szenen/Skripten zuerst `... --headless --import`, dann Tests. Zufällige „Could not preload"-Fehler beim Headless-Start sind ein bekannter Fehlalarm bei parallelen Godot-Prozessen: einfach wiederholen.
- **Heredocs in der Bash-Shell zerstören Backslashes** (`\n` wird zu einem Zeilenumbruch). Längere Skripte immer mit dem Write-Werkzeug als Datei schreiben und ausführen, nicht per Heredoc. Python-Patch-Skripte liegen als Beispiele in `build/p*_*.py`.
- Keine neuen `class_name`s (Server-Klassencache). Einbinden per `preload`. Neue Dinge in der Welt erkennt der Spieler **per Methoden** (Duck-Typing): `hinweis_text(geschlossen)`, `gefallen_aktion(spieler)`, `wohnwagen_aktion(spieler)`, `interact_point()`. Beispiele: `scripts/gefallen_taeter.gd`, `scripts/security_posten.gd`, `scripts/wohnwagen_ding.gd`.
- **Achtung:** Seit v341 sind einige Desktop-Szenen von Hand geändert (Rezeptbuch in `desktop_quests.tscn`, Melden-Knopf in `social_post.tscn`, Fest-App `desktop_fest.tscn` mit eigenem Generator-Skript im Scratchpad, Icons/Kacheln in `desktop.tscn`). Den Generator `build/gen_desktop4.py` nicht mehr ausführen, sonst gehen diese Änderungen verloren. Ursprünglich: Desktop-Oberflächen werden von `build/gen_desktop4.py` erzeugt (Teile in `build/gen_*_teil.py`). Die alten Fenster (Festbüro, Zeltcomputer) kommen aus `build/orig/*.tscn` über `build/p2_legacy.py` und `tools/remap_app_farben.py`: **Quelle in `build/orig` ändern, dann `python build/p2_legacy.py`**. Look: nachtblaues Glas, Akzentfarbe je App, Farbbanner (siehe Speicher `desktop-app-look`).
- Bilder zum Ansehen: `tools/render_desktop.tscn` (Desktop-Apps), `tools/shot_kino_start.tscn` (Eröffnung), `tools/shot_gefallen.tscn`, `tools/render_wohnwagen.tscn`; Ausgabe in `build/*.png`. Leistung messen: `tools/perf_bereiche.tscn` (FPS im Testfenster sind unbrauchbar, Render-Zeiten vergleichen).

### Tests (müssen grün bleiben, Aufruf `--headless --path . res://tools/<name>.tscn`)
`test_story`, `test_kapitel2`, `test_kapitel3`, `test_kapitel4`, `test_kapitel5`, `test_braeumeister`, `test_streiche`, `test_kontrolle`, `test_fakes`, `test_abwerben`, `test_gustav`, `test_sabotage`, `test_blackjack`, `test_happyhour`, `test_fest`, `test_meister`, `test_gefallen`, `test_wohnwagen`, `test_tutorial` (nicht headless, mit `SHOT_DIR=build`), `test_phase1` (bekannter Fehler: `WORLD_MUELLTONNE` unübersetzt, kann am Zeitlimit abbrechen).

### Wo was liegt
- **Story-Kern:** `scripts/story/story.gd` (Kapitel, Quests mit Zuständen angeboten/offen/erfüllt/verfallen, Post, Hinweise, Flaggen), Daten in `daten/quests.json`, `daten/mails.json`, `daten/hinweise.json` (Texte per Schlüssel in der CSV). Messwerte für Quest-Bedingungen: `GameManager._story_messwerte()`. Neue Quest = Eintrag in `quests.json` (+ Mail + Texte), Flaggen setzt `_story.ereignis("name")`. Gespräche, die Flaggen setzen: Tabellen `STORY_GESPRAECHE` in `scripts/npc_festleiter.gd`, Konrad-Dialoge in `scripts/npc_huber.gd`, Server-RPC `net_story_flag` (Whitelist im GameManager).
- **Kapitelfreischaltung Desktop:** `scripts/ui/desktop.gd` (`FREI`), Apps als eigene Szenen `scenes/ui/desktop_*.tscn`.
- **Gefallen:** `scripts/gefallen.gd` (Server-Ablauf; Arten `spanner`, `dieb`, `sau`, `spion`, `punkte` mit Varianten `sturm`, `feuer`), Daten im Quest-Feld `gefallen`. Neue Arten brauchen nur Quest, Mail, Texte und ein Verhalten in `scripts/gefallen_taeter.gd`.
- **Security:** Rolle 5 (`ROLE_SECURITY`), Posten `scenes/gefallen/security_posten.tscn`.
- **Wohnwagen-Innenraum:** `scenes/wohnwagen_innen.tscn` (liegt bei z=600, Eintritt über die Tür, Bett, Laptop).
- **Tutorial:** Schritte 0 bis 9 = Kapitel 1 (`QUEST_COUNT := 10` im GameManager), danach führt die Story-Hauptquest (Anzeige im HUD).

### Nächste Schritte (Vorschlag, in dieser Reihenfolge)
1. ✔ **Kapitel 5 abgerundet** (Feuerwerk, Kamerafahrt, Konrads Auftritt, Stufenanzeige, v340).
2. **P6 Rest:** Konrads Zelt umbauen (XL), Casino-Kartentisch und weitere Spiele, Händler Gustav und Sabotage-System mit Tarnung (XL).
3. ✔ **P7 fertig** (Qualität, Rezeptbuch, Gerhard, Streiche; offen nur Geduld-Bonus fürs eigene Bier).
4. **P5 Rest:** Gefallen Hochzeit und Wettessen (Muster siehe `gefallen.gd`; Falschgeld, Krüge, Reporter sind seit v353 drin).
5. ✔ **P4 fertig** (Happy Hour v354).
6. **P9 bis P11:** Fest-App und Festtag-System, Meister-Liste, Wohnwagen je Spieler, Late-Game-Ausgaben, Kirmes-Quests, Meilensteine, Zeitung, Brabbelton, Balancing mit `tools/sim_saison`, **Koop-Test aller Systeme** (bisher nur Einzelspieler-Tests!), Übersetzungen prüfen, Leistung.
7. Vor jedem Steam-Upload: alle Tests oben laufen lassen, Version hochzählen, `git push`.

### Bekannte Lücken und Risiken
- Alle Kapitel sind **nur im Test** durchgespielt, nicht von Hand und nicht im Koop. Ein Bot-Durchlauf (`tools/sim_saison`) für die ganze Story fehlt.
- Quest 5.4 verlangt jetzt ein abgefülltes Fass Meisterbräu. Quest 3.4 fängt den Saboteur direkt statt ihn zu einem Security zu tragen.
- Die Schulden stehen bei 5.000 € (`SCHULDEN_START`), Quest 2.5 verlangt davon 1.500 € zurück. Beträge sind Platzhalter fürs Balancing.
- Bank-Texte, Mails und Quest-Texte sind Entwürfe: Ton warm und humorvoll, nach dem Testspielen glätten.
- `docs/PLAN_STORY.md` und die `TEXTE_K1` bis `K5` sind der Plan und enthalten teils noch das Wort „Wiesn" (nicht ins Spiel übernehmen).

---

## Fortschritt (laufend gepflegt)

**Legende:** ✔ fertig · ◐ teilweise · ☐ offen. Stand 07.10.2026, Version v333.

| Phase | Stand | Version |
|---|---|---|
| P0 Vorbereitung | ✔ fertig | v320 |
| P1 Kern-Systeme | ✔ fertig | v321 |
| P2 Computer-Desktop | ✔ fertig (Apps, Laptop mit begehbarem Wohnwagen) | v322 bis v324 |
| P3 Kapitel 1 | ✔ fertig (spielbar bis zum ersten Feierabend) | v325 |
| P4 Kapitel 2 | ✔ fertig | v329 bis v332 |
| P5 Gefallen und Security | ◐ (Security als Personal ✔ v334) System plus sechs Gefallen (Spanner, Taschendieb, Sau, Konrads Spion, Sturmwarnung, Brand) und vier Security-Posten fertig; 5 weitere Gefallen (Falschgeld, gestohlene Krüge, Hochzeit, Reporter, Wettessen), Security als Personal offen | v330 bis v333 |
| P6 Kapitel 3 | ◐ Streiche und Quests 3.1 bis 3.6 spielbar (ohne Casino); Konrads Zelt, Casino, Sabotage-System, Frau Wagner offen | v334 |
| P7 Kapitel 4 | ✔ Quests 4.1 bis 4.7, Qualität, Rezeptbuch, Bräumeister, Streiche (Geduld-Bonus offen) | v343 |
| P8 Kapitel 5 | ✔ Quests 5.1 bis 5.7, großes Fest mit Feuerwerk, Kamerafahrt, Konrads Auftritt, Duell-Stufenanzeige | v336 |
| P9 bis P11 | ☐ offen | |

---

## Grundsätze
- **Vorhandenes wiederverwenden:** Der Rundgang (Tutorial), das Festbüro-Menü, die Zeitung, der Kalender, der Braukeller, das Packen und Tragen von Raufbolden, die tote Konrad-Handlung (Wette, Saboteur, Duell, v269 abgeschaltet), der Charakter-Creator, die Einrichtung.
- **`game_manager.gd` hat fast 7000 Zeilen.** Neue Systeme kommen in eigene Skripte (Kapitel, Quests, Post, Sabotage, Casino, Fest), der GameManager ruft sie nur auf.
- **Keine neuen `class_name`** (Server-Neuindizierung), Einbindung per `preload`.
- **Alles als Szenen/Knoten im Editor** (deine Regel), keine prozedural gebauten Oberflächen.
- **Koop von Anfang an:** Quests, Mails und Konto sind gemeinsam. Der Server entscheidet, die Clients zeigen.
- **Texte in drei Sprachen**, Du-/Ihr-Form, über die vorhandene Übersetzungstabelle.
- Nach jeder Phase ein **spielbarer Stand** und ein Test (Skript unter `tools/`).

---

## Phasen im Überblick

| Phase | Inhalt | Abhängig von | Aufwand |
|---|---|---|---|
| **P0** | Vorbereitung: Namen, Aufräumen, Datenformat | – | M |
| **P1** | Kern: Kapitel, Quests, Post, Hinweise | P0 | L |
| **P2** | Computer-Desktop und Apps | P1 | XL |
| **P3** | Kapitel 1 komplett (erster spielbarer Schnitt) | P1, P2 | L |
| **P4** | Kapitel 2 | P3 | L |
| **P5** | Gefallen, Security, Kirmes-Security | P4 | XL |
| **P6** | Kapitel 3: Konrad, Sabotage, Gustav, Konrads Zelt, Casino | P5 | XXL |
| **P7** | Kapitel 4: Brauen vertiefen | P4 | L |
| **P8** | Kapitel 5: Turnier, Riesenzelt, großes Fest | P6, P7 | L |
| **P9** | Endgame: Fest-App, Festruhm, Wohnwagen, Meister | P8 | XL |
| **P10** | Kirmes-Quests, Meilensteine, Zeitung, Social, Brabbelton | P9 | L |
| **P11** | Balancing, Koop-Test, Übersetzung, Politur | alles | L |

---

## P0 · Vorbereitung (M)

| Aufgabe | Wo | Aufwand |
|---|---|---|
| ✔ Namen angleichen: **Konrad**, **Festleiter Horst** (in EN/TR übersetzen), Stammgäste **Ludwig, Veronika, Katharina** | `locale/texte.csv`, `game_manager.gd` (STAMMGAESTE), Zeitung | S |
| ✔ Saison und Finale vollständig ausbauen (toter Code, Taste K, Abschlussbrief am Saisonende, Saison-Meilensteine) | `wirtschaft.gd`, `kalender.gd`, `game_manager.gd` | S |
| ✔ Datenformat für Quests und Mails festlegen (CSV oder JSON, mit Schlüsseln der Übersetzungstabelle) | neu `daten/` | S |
| ✔ Tutorial-Doppelbrief beheben (Vorarbeit für Kapitel 1) | `intro.gd`, `npc_festleiter.gd` | S |

**Test:** Spiel startet, Tutorial läuft wie vorher, keine Saison-Meldung mehr.

## P1 · Kern-Systeme (L)

| System | Beschreibung | Aufwand |
|---|---|---|
| ✔ **Kapitel-Fortschritt** | Kapitelnummer und Story-Ziele im Spielstand, Server hält ihn, Clients bekommen Updates | M |
| ✔ **Quest-System** | Quest-Daten laden, Zustände (offen, erfüllt, verfallen), Auslöser, Bedingungen messen (z. B. „1 Kellner eingestellt"), Fristen in Spieltagen, Belohnungen, Limit (1 Haupt + 3 andere) | L |
| ✔ **Post-System** | Postfach pro Spielstand (gemeinsam im Koop), Absender, Betreff, Text, Antworten mit Folgen, gelesen/ungelesen | M |
| ✔ **Hinweis-im-Moment** | Einmalige Hinweise beim ersten Auftreten, gemerkt im Spielstand | S |
| ✔ **Kapitelwechsel-Logik** | Abschlussmeldung, Mail am selben Abend, Freischaltungen | S |

**Test:** `tools/test_quests` (Quest erfüllen, verfallen, Reihenfolge), `tools/test_post`.

## P2 · Computer-Desktop (XL)

| Teil | Aufwand |
|---|---|
| ✔ **Übergangs-Animation** am Büro-Computer (E drücken, Kamera fährt zum Bildschirm) | M |
| ✔ **Desktop-Shell:** Symbole, Fenster, Schließen, Freischalten je Kapitel | M |
| ✔ **E-Mail-App** (Posteingang, Absender, Lesen, Antworten) | M |
| ✔ **Shop** (aus dem Festbüro-Menü: Zelt, Tische, Ware, Lizenzen, Künstler, Einrichtung) | M |
| ✔ **Quests-App** (aktive, Meilensteine, später Meister-Liste) | S |
| ✔ **Bank, Personal, Bilanz, Bierpreis** (aus Festbüro und Zeltcomputer) | M |
| ✔ **Kalender-App** (aus `kalender.gd`) | S |
| ✔ **Wetter und Amt**, **Social Media** (mittelwichtig) | M |
| ✔ **Laptop im Wohnwagen** (derselbe Desktop) | S |

**Wiederverwendung:** `festbuero.gd` (467 Zeilen), `zeltcomputer.gd`, `kalender.gd`, `zeitung.gd`.
**Test:** Desktop öffnen/schließen im Koop, Kamera ohne Fehler, Shop kauft wie vorher.

## P3 · Kapitel 1 (L) — erster spielbarer Schnitt

| Aufgabe | Aufwand |
|---|---|
| ✔ Kurzszene am Kirmestor und Titel | M |
| ✔ Brief (einmal), Horst-Dialoge neu, Frage Ja/Nein | M |
| ✔ Tutorial auf die Quests 1.0 bis 1.9 umstellen, Computer-Einführung | M |
| ✔ Mails M1-01 bis M1-03 und Kapitelabschluss | S |
| ✔ Texte DE/EN/TR für Kapitel 1 | S |

**Danach:** Ein Spieler kann vom Start bis zum ersten Feierabend spielen. Hier entscheidet sich, ob sich das neue Spiel richtig anfühlt.

## P4 · Kapitel 2 (L)

| Aufgabe | Aufwand |
|---|---|
| ✔ Quests 2.1 bis 2.6 mit Mails und Freischaltungen | M |
| ✔ Nebenquest-Generator (zufällig per Mail, Fristen) — alle 5 Nebenquests, Happy Hour seit v354 | M |
| ✔ Krankmeldungen und Lohnwünsche als Mails mit Antworten | S |
| ✔ Bank-Abzahlung selbst (Bank-App, Rate, Schulden-Stand) | S |
| ✔ Konrads Mails, Wetter-/Amt-Mails | S |
| ✔ Texte DE/EN/TR | S |

## P5 · Gefallen, Security, Kirmes (XL)

| Aufgabe | Aufwand |
|---|---|
| ◐ **Gefallen-Generator** (alle paar Tage zufällig per Mail, Pool von 16) — Zufall und Mail laufen, Pool: 9 von 11 | M |
| ✔ **Täter-Figuren** (Spanner, Taschendieb, Betrunkener, Raufbolde, Fälscher, Dieb) über den Creator | M |
| ✔ **Packen, Tragen, Übergeben** an Security (vorhandene Raufbold-Mechanik erweitern) | M |
| ✔ **Security-Posten** verteilt auf der Kirmes (feste Figuren), **Security als Personal** (Rolle fünf) | M |
| ◐ Gefallen-Quests umsetzen (Sau, Brand, Sturm, Reporter, Lieferung usw.) | XL |
| ✔ **Neue Modelle:** Sau (Tier, Blender), Brunnen, Feuer-Effekt, Planen, Gehege | M |

## P6 · Kapitel 3: Konrad, Sabotage, Casino (XXL)

| Aufgabe | Aufwand |
|---|---|
| ◐ **Konrad-Streiche reaktivieren** (Wette, Fass-Leck, Stinkbombe, Saboteur, Abwerben ✔) | M |
| ✔ **Überraschungskontrolle** (Frau Wagner als Figur im Zelt, geht ihre Runde, Urteil danach; ab Kapitel 3 auch unangekündigt, v344) | M |
| ✔ **Social-Media-Fake-Bewertungen** und Melden (v345) | S |
| ◐ **Konrads Zelt umbauen:** ✔ Schanktheke, Personal (Zapfer, 2 Kellner auf Runde) und 15 Gäste (v347); ☐ Küche, Layout, Konrad läuft selbst durchs Zelt, Anbau fürs Casino | XL |
| ✔ **Casino hinter Konrads Zelt** (Anbau mit Wänden, Kollision, Tür gesperrt bis der Türsteher einlässt, Zutritt nur mit Tarnung, v350) | L |
| ◐ **Casino-Spiele:** ✔ Roulette (Rot/Schwarz, 50 €, Kessel dreht sich, Modell aus Blender); ✔ Blackjack am Kartentisch (Modell aus Blender, Karte/Halten, Blackjack zahlt 3:2, v352); ☐ Schafkopf/Watten, weitere | XL |
| ◐ **Händler Gustav** (✔ Figur am Riesenrad, Koffer mit Mantel, Komplettset, Fassbohrer, Zange, Stinkbombe, Juckpulver, Tarnung an/aus, v348) und **Sabotage-System** (✔ Einsatz in Konrads Zelt: vier Ziele, Konrad patrouilliert mit Blickfeld, Erwischt = Bußgeld und Rauswurf, Rache am nächsten Tag, v349; ✔ Mantel und Maske sichtbar am Spieler (Filzhut, Janker, Schnauzer, Brille, v351), ☐ Kameras/Schlösser): Werkzeuge, Tarnung (Mantel, Komplettset, Schnauzer-Brille), Blickfeld und Verdächtig-Balken, Bußgeld, Kunden verschieben | XL |
| ✔ Quests 3.1 bis 3.6 und 3.4b „Das Hinterzimmer“, Mails M3-xx (ohne Horsts Erinnerung 2) | M |
| **Neue Modelle/Figuren:** Gustav, Türsteher, Croupier, Frau Wagner, Roulette-/Kartentische, Sicherungskasten, Kellertreppe | L |

**Risiko:** Konrads Zelt und das Casino sind die größten Posten. Wir sollten sie in Etappen bauen (erst Zelt, dann Keller, dann Spiele).

## P7 · Kapitel 4: Brauen (L)

| Aufgabe | Aufwand |
|---|---|
| ◐ Braukeller überarbeiten (aufräumen, Rezepttafel, Tür) — Keller und Brauen laufen wie zuvor, Abfüllen neu | M |
| ✔ Qualitätsstufen (Hausbier, Festbier, Meisterbräu je Rezeptseite) und Rezeptbuch in der Quests-App (v341) | M |
| ◐ Eigenes Bier (✔ Abfüllen, Lager, Zählung, Aufschlag je Maß nach Güte; ☐ Geduld) | S |
| ✔ Bräumeister Gerhard als Personal (Rolle sechs, braut von allein im Keller, v342) | M |
| ◐ Quests 4.1 bis 4.7, Mails (✔); Streiche: Zutaten blockieren ✔, Lieferwagen, Diebe, Stromausfall ✔ (v343) | M |

## P8 · Kapitel 5 (L)

| Aufgabe | Aufwand |
|---|---|
| ◐ **Duell-Turnier** reaktivieren (✔ in der Story ab 5.2 wiederholbar, Konrad wird je Sieg schneller; ✔ Stufenanzeige „Runde x von 5“ (v339)) | M |
| ✔ Riesenzelt (Zeltstufe 4, vorhanden), Quests 5.1 bis 5.7 | M |
| ✔ **Großes Fest:** ✔ Star-Act-Bedingung, Brief, Meldung; ✔ Feuerwerk (v337), Konrads Auftritt (v338), Kamerafahrt (v340) | L |

## P9 · Endgame (XL)

| Aufgabe | Aufwand |
|---|---|
| ✔ **Fest-App** (ab Kapitel 6: Motto, Band, Feuerwerk, Dekoration, Werbung, Aushilfen planen und bezahlen, v355) | L |
| ◐ **Festtag-System:** ✔ Ereignis „Fest“ alle 10 Tage (mehr Gäste, Band, Feuerwerk um 21 Uhr), Festruhm und fünf Festränge, Konrads Festruhm als Vergleich (v355); ☐ Wettbewerbe (Fassanstich, Maßkrug-Stemmen), Katastrophen und Gegenmittel, Motto-Gäste | L |
| ✔ **Meister-Liste** (13 Einträge in der Quests-App, 100 % = Titel Fest-Meister, v356; goldener Krug am Wohnwagen ☐) | S |
| **Wohnwagen je Spieler** (Wohnwagenplatz, Anpassung innen/außen, Schlafqualität, Status) | XL |
| **Late-Game-Ausgaben:** Zelt-Ausbauten (Empore, VIP-Lounge, Biergarten), Brauerei verkaufen, Buden und Zweitzelt | XL |

## P10 · Kirmes-Quests, Meilensteine, Zeitung (L)

| Aufgabe | Aufwand |
|---|---|
| Kirmes-Quests (6 bis 8), Buden-Besitzer-Texte | M |
| Meilensteine neu, **Steam-Errungenschaften** | M |
| Zeitung (Wiesn-Blatt) mit neuen Themen | S |
| **Brabbelton** je Figur im Dialog | M |
| Gäste: Gruppen, Wunschlieder, mehr Chaos | L |

## P11 · Balancing und Politur (L)

| Aufgabe | Aufwand |
|---|---|
| Geld, Preise, Schulden, Belohnungen, Fristen, Bußgeld (mit `tools/sim_saison`, Testspielen) | M |
| Koop-Test aller Systeme (Quests, Mails, Desktop, Casino, Sabotage) | M |
| Übersetzungen EN/TR prüfen, Texte der noch fehlenden ca. 50 Mails | M |
| Performance (viele Gäste, Konrads Zelt, Casino), Bugs, Clipping | M |

---

## Summe der Schätzung

| Phase | Aufwand | Sitzungen (ca.) |
|---|---|---|
| P0 | M | 1 |
| P1 | L | 3 |
| P2 | XL | 5 |
| P3 | L | 3 |
| P4 | L | 3 |
| P5 | XL | 5 |
| P6 | XXL | 8 |
| P7 | L | 3 |
| P8 | L | 3 |
| P9 | XL | 5 |
| P10 | L | 3 |
| P11 | L | 3 |
| **Gesamt** | | **ca. 45 Sitzungen** |

Die Schätzung ist grob. Phase 6 (Konrads Zelt, Casino, Sabotage) ist am unsichersten. Sie kann deutlich länger dauern.

## Assets (neu zu erstellen)

| Typ | Was | Phase |
|---|---|---|
| Figuren (Creator) | Gustav, Türsteher, Croupier, Frau Wagner, Täter (Spanner, Taschendieb, Betrunkener, Fälscher, Dieb), Brautpaar, Reporter, Bräumeister Gerhard | P5, P6, P7 |
| Creator-Teile | Schnauzer-Brille mit dicken Augenbrauen, Mantel | P6 |
| 3D-Modelle (**selbst gebaut oder freie Sets**) | Sau, Eimer, Feuer, Roulette-Tisch, Blackjack-Tisch, Kartentisch, Slot-Maschine, Sicherungskasten, Schloss, Kamera, Rezeptbuch, Hopfen- und Malzsäcke, Feuerwerk | P5 bis P8 |
| Räume | Casino-Keller, Konrads Zelt (Umbau), Wohnwagenplatz, Laptop und Spiegel | P6, P9 |
| UI-Symbole | Desktop-Apps (nach dem Symbole-Stil) | P2 |
| Audio | Brabbelton, Feuerwerk, Roulette, Karten, Casino-Ambiente | P8, P10 |

## Risiken
1. **Konrads Zelt und Casino** (Layout, Kollision, Clipping, Wegfindung) sind der größte Aufwandsposten.
2. **Koop-Synchronisation** der neuen Systeme (Quests, Mails, Sabotage, Casino) braucht Zeit beim Testen.
3. **Texte in drei Sprachen** (ca. 110 Mails, ca. 120 Dialogzeilen, ca. 100 Quests) sind viel Handarbeit.
4. **Balancing** hängt an allem, bleibt deshalb ans Ende.
5. **`game_manager.gd`** wird nicht größer, neue Logik gehört in eigene Skripte.

## Entscheidungen (Serdar: „Entscheide du", von Claude getroffen)
1. **Steam-Test:** Nach **P3 (Kapitel 1)** laden wir einen Stand auf Steam hoch (Beta-Branch, du setzt den Branch in Steamworks), damit der neue Einstieg früh getestet wird. Danach nach jeder weiteren Kapitelphase.
2. **Modelle (✔ Serdar: kein Meshy-Abo mehr, „baue selbst"):** Ich baue alle Modelle **selbst in Blender** (auch Sau, Roulette-, Blackjack- und Kartentische, Slot-Maschine, Feuerwerk). Wo es sich lohnt, **recherchiere ich online nach kostenlosen Sets** (bevorzugt **CC0/kommerziell nutzbar**: Kenney, Quaternius, Poly Pizza, OpenGameArt) und lade sie herunter, wenn Lizenz und Stil passen. Jede Quelle kommt mit Lizenz in `docs/lizenzen`. Vor jedem Download nenne ich Quelle, Datei und Größe.
3. **Reihenfolge:** **P5 (Gefallen und Security) bleibt vor P6 (Kapitel 3)**, weil Kapitel 3 die Pack- und Übergabe-Mechanik und den Security braucht.

## Offene Punkte
1. Wann starten wir mit P0? (Auf dein Kommando.)
