# Bauplan (Entwurf)

Stand 06.10.2026. Wie wir den Plan umsetzen, in welcher Reihenfolge, mit grober Aufwandsschätzung. **Gebaut wird erst auf dein Kommando.**
**Aufwand** in „Sitzungen" (eine Sitzung = ein zusammenhängender Arbeitsblock mit mir): **S** = 0,5 · **M** = 1 · **L** = 3 · **XL** = 5 · **XXL** = 8. Das sind Schätzungen, die sich beim Bauen verschieben. Summe unten.

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
| Namen angleichen: **Konrad**, **Festleiter Horst** (in EN/TR übersetzen), Stammgäste **Ludwig, Veronika, Katharina** | `locale/texte.csv`, `game_manager.gd` (STAMMGAESTE), Zeitung | S |
| Saison und Finale vollständig ausbauen (toter Code, Taste K, Abschlussbrief am Saisonende, Saison-Meilensteine) | `wirtschaft.gd`, `kalender.gd`, `game_manager.gd` | S |
| Datenformat für Quests und Mails festlegen (CSV oder JSON, mit Schlüsseln der Übersetzungstabelle) | neu `daten/` | S |
| Tutorial-Doppelbrief beheben (Vorarbeit für Kapitel 1) | `intro.gd`, `npc_festleiter.gd` | S |

**Test:** Spiel startet, Tutorial läuft wie vorher, keine Saison-Meldung mehr.

## P1 · Kern-Systeme (L)

| System | Beschreibung | Aufwand |
|---|---|---|
| **Kapitel-Fortschritt** | Kapitelnummer und Story-Ziele im Spielstand, Server hält ihn, Clients bekommen Updates | M |
| **Quest-System** | Quest-Daten laden, Zustände (offen, erfüllt, verfallen), Auslöser, Bedingungen messen (z. B. „1 Kellner eingestellt"), Fristen in Spieltagen, Belohnungen, Limit (1 Haupt + 3 andere) | L |
| **Post-System** | Postfach pro Spielstand (gemeinsam im Koop), Absender, Betreff, Text, Antworten mit Folgen, gelesen/ungelesen | M |
| **Hinweis-im-Moment** | Einmalige Hinweise beim ersten Auftreten, gemerkt im Spielstand | S |
| **Kapitelwechsel-Logik** | Abschlussmeldung, Mail am selben Abend, Freischaltungen | S |

**Test:** `tools/test_quests` (Quest erfüllen, verfallen, Reihenfolge), `tools/test_post`.

## P2 · Computer-Desktop (XL)

| Teil | Aufwand |
|---|---|
| **Übergangs-Animation** am Büro-Computer (E drücken, Kamera fährt zum Bildschirm) | M |
| **Desktop-Shell:** Symbole, Fenster, Schließen, Freischalten je Kapitel | M |
| **E-Mail-App** (Posteingang, Absender, Lesen, Antworten) | M |
| **Shop** (aus dem Festbüro-Menü: Zelt, Tische, Ware, Lizenzen, Künstler, Einrichtung) | M |
| **Quests-App** (aktive, Meilensteine, später Meister-Liste) | S |
| **Bank, Personal, Bilanz, Bierpreis** (aus Festbüro und Zeltcomputer) | M |
| **Kalender-App** (aus `kalender.gd`) | S |
| **Wetter und Amt**, **Social Media** (mittelwichtig) | M |
| **Laptop im Wohnwagen** (derselbe Desktop) | S |

**Wiederverwendung:** `festbuero.gd` (467 Zeilen), `zeltcomputer.gd`, `kalender.gd`, `zeitung.gd`.
**Test:** Desktop öffnen/schließen im Koop, Kamera ohne Fehler, Shop kauft wie vorher.

## P3 · Kapitel 1 (L) — erster spielbarer Schnitt

| Aufgabe | Aufwand |
|---|---|
| Kurzszene am Kirmestor und Titel | M |
| Brief (einmal), Horst-Dialoge neu, Frage Ja/Nein | M |
| Tutorial auf die Quests 1.0 bis 1.9 umstellen, Computer-Einführung | M |
| Mails M1-01 bis M1-03 und Kapitelabschluss | S |
| Texte DE/EN/TR für Kapitel 1 | S |

**Danach:** Ein Spieler kann vom Start bis zum ersten Feierabend spielen. Hier entscheidet sich, ob sich das neue Spiel richtig anfühlt.

## P4 · Kapitel 2 (L)

| Aufgabe | Aufwand |
|---|---|
| Quests 2.1 bis 2.6 mit Mails und Freischaltungen | M |
| Nebenquest-Generator (zufällig per Mail, Fristen) | M |
| Krankmeldungen und Lohnwünsche als Mails mit Antworten | S |
| Bank-Abzahlung selbst (Bank-App, Rate, Schulden-Stand) | S |
| Konrads Mails, Wetter-/Amt-Mails | S |
| Texte DE/EN/TR | S |

## P5 · Gefallen, Security, Kirmes (XL)

| Aufgabe | Aufwand |
|---|---|
| **Gefallen-Generator** (alle paar Tage zufällig per Mail, Pool von 16) | M |
| **Täter-Figuren** (Spanner, Taschendieb, Betrunkener, Raufbolde, Fälscher, Dieb) über den Creator | M |
| **Packen, Tragen, Übergeben** an Security (vorhandene Raufbold-Mechanik erweitern) | M |
| **Security-Posten** verteilt auf der Kirmes (feste Figuren), **Security als Personal** (Rolle fünf) | M |
| Gefallen-Quests umsetzen (Sau, Brand, Sturm, Reporter, Lieferung usw.) | XL |
| **Neue Modelle:** Sau (Tier), Eimer, Feuer-Effekt, Planen | M |

## P6 · Kapitel 3: Konrad, Sabotage, Casino (XXL)

| Aufgabe | Aufwand |
|---|---|
| **Konrad-Streiche reaktivieren** (Wette, Fass-Leck, Stinkbombe, Saboteur, Abwerben; Code vorhanden) | M |
| **Überraschungskontrolle** (Frau Wagner als Figur im Zelt) | M |
| **Social-Media-Fake-Bewertungen** und Melden | S |
| **Konrads Zelt umbauen:** gleiche Tische/Theke/Ausgabe/Küche wie unser Zelt, anderes Layout, Konrad läuft zufällig durchs Zelt, Gäste und Personal | XL |
| **Casino im Keller:** Treppe/Kellertür, Türsteher, saubere Kollision, kein Clipping | L |
| **Casino-Spiele:** Roulette, Blackjack, Karten, weitere einfache Spiele | XL |
| **Händler Gustav** und **Sabotage-System:** Werkzeuge, Tarnung (Mantel, Komplettset, Schnauzer-Brille), Blickfeld und Verdächtig-Balken, Bußgeld, Kunden verschieben | XL |
| Quests 3.1 bis 3.6, Mails M3-xx, Horsts Erinnerung 2 | M |
| **Neue Modelle/Figuren:** Gustav, Türsteher, Croupier, Frau Wagner, Roulette-/Kartentische, Sicherungskasten, Kellertreppe | L |

**Risiko:** Konrads Zelt und das Casino sind die größten Posten. Wir sollten sie in Etappen bauen (erst Zelt, dann Keller, dann Spiele).

## P7 · Kapitel 4: Brauen (L)

| Aufgabe | Aufwand |
|---|---|
| Braukeller überarbeiten (aufräumen, Rezepttafel, Tür) | M |
| Qualitätsstufen und drei Rezeptseiten, Rezeptbuch in der Quests-App | M |
| Eigenes Bier: Preis, Kosten, Geduld, Premium-Verkauf | S |
| Bräumeister Gerhard als Personal (Rolle sechs) | M |
| Quests 4.1 bis 4.7, Mails, Streiche (Zutaten blockieren, Lieferwagen, Diebe, Stromausfall) | M |

## P8 · Kapitel 5 (L)

| Aufgabe | Aufwand |
|---|---|
| **Duell-Turnier** reaktivieren (Wettschleppen, Code vorhanden), Stufen 1 bis 5 | M |
| Riesenzelt (Zeltstufe 4, vorhanden), Quests 5.1 bis 5.7 | M |
| **Großes Fest:** Cutscene, Star-Act, Feuerwerk, Konrads Auftritt, Brief, Meldung | L |

## P9 · Endgame (XL)

| Aufgabe | Aufwand |
|---|---|
| **Fest-App:** Motto, Band, Feuerwerk, Dekoration, Werbung, Aushilfen | L |
| **Festtag-System:** Ereignis, Wettbewerbe (Fassanstich, Maßkrug-Stemmen), Katastrophen und Gegenmittel, Festruhm, Festränge | L |
| **Meister-Liste** (100 %) | S |
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
