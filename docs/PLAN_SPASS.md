# Plan: Vom funktionierenden Spiel zum Spiel, das Spaß macht

Stand 2026-09-11, live v112. Grundlage: Code und Konstanten im Repo, nicht ein
echter Spieldurchlauf. **Wichtig:** Der Ablauf wurde bisher nur in Teilen per
Test und Simulation geprüft (Kaufen, Tragen, Gästeweg, Speichern, Beschriftungen).
Ob ein ganzer Tag flüssig läuft und ob Tag 20 noch Spaß macht, hat niemand
gemessen. Phase 0 holt das nach, bevor Inhalte gebaut werden.

Kennzeichnung: **Ich** = Claude baut es · **Du** = braucht dich ·
Aufwand S (≤ 1 Sitzung), M (2–3), L (mehr).

---

## Bestandsaufnahme

### Was es gibt

| Bereich | Inhalt |
|---|---|
| Tag | 07:00–22:00 in 300 s echter Zeit, Gäste ab 08:00, ab 19:00 ungeduldiger |
| Angebot | Helles, Weizen, Radler, Brezn, Würstl (4 Lizenzen) |
| Zelt | 3 Stufen, bis 12 Tische, Toilette, Werbung, Deko-Stufen, 5 Einrichtungsgegenstände |
| Personal | Koch, Kellner (trägt 1–12 Krüge), Reinigung — je 5 Stufen |
| Bühne | Straßenmusiker, Blaskapelle, Star-Act |
| Chaos | Pfützen ohne Klo, Erbrechen nach 4 Getränken, Beschwerden, Gäste gehen |
| Wirtschaft | Kosten +2 %/Tag, Preise +1,5 %/Tag, Bierpreis 50–200 %, Rettungskredit |
| Ziele | Tutorial (12 Schritte), 13 Meilensteine = Steam-Errungenschaften |
| Koop | 2–4 Spieler, Steam-Lobbys, Dedicated Server |

### Was fehlt oder bremst — ehrlich

1. **Jeder Tag ist gleich.** Keine Zufallsereignisse (die früheren sind nicht
   mehr im Code), keine Gästetypen, kein Wetter. Ab Tag 5 wiederholt sich alles.
2. **Kein Ende, kein Höhepunkt.** Endlos-Modus ohne Saisonziel, ohne Finale,
   ohne Bewertung. Wofür spielt man Tag 30?
3. **Stille.** Sounddateien fehlen komplett — Zapfen, Kasse, Jubel, Blasmusik.
   Ein Kirmesspiel ohne Ton wirkt kaputt, egal wie gut der Rest ist.
4. **Langer Leerlauf am Anfang.** Geschätzt 3–5 Minuten bis zum ersten
   bedienten Gast (Wege, 60 s Lieferung, 45–75 s nach dem Aufwachen). Genau dort
   springen neue Spieler ab.
5. **Wenig Rückmeldung beim Bedienen.** Man bekommt Geld, aber kaum Gefühl:
   keine Kombo, kein Jubel am Tisch, kein sichtbarer Stress-Höhepunkt.
6. **Mittelteil ist Verwaltung.** Nach dem Einstellen von Kellnern spielt sich
   das Zelt fast selbst — der Spieler steht daneben.
7. **Koop hat keine eigenen Momente.** Seit die Rollen weg sind, machen alle
   dasselbe; nichts zwingt oder belohnt Zusammenarbeit.
8. **Testschalter aktiv:** `ALWAYS_NIGHT := true` in `game_manager.gd` — es ist
   immer Nacht, Tag-/Abendstimmung fehlt.
9. **Figur „Frau" sitzt nicht** (Rock-Gewichtung) — weniger Vielfalt am Tisch.

---

## Phase 0 · Messen statt raten (zuerst!)

- [x] **0.1 Testschalter aus** — `ALWAYS_NIGHT = false`, Tageslicht prüfen. *Ich, S*
- [x] **0.2 Spielbot für ganze Tage** — `tools/sim_saison.tscn` spielt 30 Tage
      im Zeitraffer mit einer einfachen Strategie (bedienen, nachbestellen,
      ausbauen) und schreibt je Tag: Geld, Gäste, verpasste Bestellungen,
      Leerlauf-Sekunden des Spielers, Engpass (Bier leer? Kellner voll?).
      Ergebnis als Tabelle `build/saison.csv`. *Ich, M*
      → beantwortet: Ist das Spiel zu leicht/schwer? Wann ist man „fertig"?
- [x] **0.3 Erste-10-Minuten-Messung** — Zeit von „Neues Spiel" bis erster
      bedienter Gast, bis erste Tagesbilanz. Ziel festlegen (siehe Messlatte). *Ich, S*

**Ergebnis Bot, 30 Tage (2026-09-11, `build/saison.csv`, `tools/sim_saison.tscn`):**
- Erster bedienter Gast nach **3,4 min**, erste Tagesbilanz nach **7 min** (Ziel ≤ 2 min).
- **Kein Fortschritt:** nach 30 Tagen immer noch kleines Zelt, 4 Tische, 1,5–2,5 k €.
  Gewinn nur 50–350 € pro Tag, Zeltstufe 2 (3.000 €) nie erreichbar.
- **Beliebtheit fällt ab Tag 4 auf 5 %** und bleibt dort (Pfützen ohne Klo,
  Beschwerden, verpasste Bestellungen) → Todesspirale: wenig Gäste, wenig Geld.
- Nur ~30–38 Bestellungen pro Tag trotz 24 Plätzen; ab Tag 20 bis 20 verpasste.
- Rund 60 s Leerlauf pro Schicht.
- Einschränkung: einfache Bot-Strategie (keine Werbung, Klo erst spät).
  Trotzdem klar: **Wirtschaft zu knapp, Strafen zu hart, Mittelspiel fehlt.**
  → Phase 1 zusammen mit 6.2 (Balancing) vorziehen.

**Behoben nach Bot-Läufen 2–8 (2026-09-11):**
- Beschwerde-Schleife (jeder Gast alle 6 s erneut) → einmal pro Gast
- Tagesende doppelt (Tag +2, Miete doppelt) → gesperrt
- Sauberkeit sank 3× zu schnell, kostete bis 60 % Einnahmen → max. 30 %
- Preise 18/16 €, Trinkgeld 2–8, Klo 1.000, Zelt 2.000/6.000, Miete 220/450, Lieferung 30 s
- Kellner trägt ab Stufe 1 zwei Krüge, Essen einer Runde zählt einmal
- Beliebtheit: Untergrenze 10, nächtliche Erholung Richtung 40, Verlust durch
  verpasste Bestellungen max. 20/Tag
- **Neu: Zapfer** (Nutzerwunsch) — zapft vor und stellt Krüge auf die Ausgabe
  an der neuen Platzhalter-Theke; Koch stellt Essen dorthin. Spieler/Kellner
  nehmen Fertiges mit, ohne selbst zu zapfen.
- Ergebnis Lauf 8: Zelt 2 an Tag 8, Zelt 3 an Tag 14, Beliebtheit bis Zelt 2 ~95 %.
- [ ] **0.4 Echter Spieltest** — du spielst 2 Tage allein und 1 Tag im Koop,
      F12 an jeder Stelle, die hakt oder langweilt, danach 5 Sätze Notiz. *Du, S*
- [ ] **0.5 Außenstehende** (Plan 6.2) — 3 Leute, die das Spiel nie gesehen
      haben. Zuschauen, nicht erklären. Notieren: wo sie hängen, wann sie aufs
      Handy schauen. *Du, M*

**Messlatte (Vorschlag):**

| Messpunkt | Ziel |
|---|---|
| Neues Spiel → erster bedienter Gast | ≤ 2 Minuten |
| Leerlauf ohne Aufgabe am Stück | ≤ 20 Sekunden |
| Ein Tag inkl. Pause | 8–12 Minuten |
| Neues freischaltbares Ding | mindestens alle 2 Spieltage |
| Spielzeit bis Saisonende | 4–6 Stunden, danach Wiederspielwert |

---

## Phase 1 · Reibung raus (die ersten 15 Minuten)

- [ ] **1.1 Schnellstart** — erster Tag: Zelt ist schon gemietet, 2 Tische
      stehen, 2 Pakete Bier liegen im Regal. Das Tutorial beginnt mit Zapfen und
      Bedienen (dem Spaß), Verwaltung kommt ab Tag 2 Schritt für Schritt. *Ich, M*
- [ ] **1.2 Wartezeiten kürzen** — erste Lieferung sofort, später 30 s statt
      60 s; erste Gäste am Tag 1 nach 15 s. Wartezeit sichtbar (Countdown über
      dem Tor/Lieferwagen). *Ich, S*
- [ ] **1.3 Wiesenbüro näher ans Zelt** oder zweiter Schreibtisch im Zelt —
      38 m Weg für jeden Einkauf nervt. *Ich, S (Map: Du entscheidest Platz)*
- [x] **1.4 „Warum?" sichtbar machen** *(v115: 😤 bei verpasster Bestellung,
      😠 wenn ein Gast genervt geht; Bilanz nennt bis zu 3 Tipps. Offen: 💸 zu teuer)* — Gast geht: Symbol über dem Kopf
      (😠 zu lange gewartet, 🤢 schmutzig, 💸 zu teuer). Tagesbilanz nennt die
      größten 3 Verlustgründe mit Tipp. *Ich, M*
- [x] **1.5 Pausephase führen** *(v115: „💡 Tipps für morgen" in der Tagesbilanz)* — nach Feierabend ein kurzer Bildschirm
      „Morgen: …" mit 1–2 Empfehlungen (Bier reicht nicht, Kellner lohnt sich). *Ich, S*
- [ ] **1.6 Ton (Pflicht)** — mindestens 12 Sounds: Zapfen, Krug abstellen,
      Kasse, Trinkgeld, Jubel/Prost, Beschwerde, Kotzen, Putzen, Lieferwagen,
      Tür/Tor, Menüklick, Feierabend-Glocke; dazu 2–3 Blasmusik-Stücke und
      Stimmengewirr. Namen stehen in `docs/AUDIO.md`. *Du: Dateien kaufen, Ich: einbauen, M*

## Phase 2 · Bedienen fühlt sich gut an (Moment zu Moment)

- [x] **2.1 Kombo & Hektik-Bonus** *(v116: ab 3 schnellen Bedienungen „🔥 Kombo ×n", +2 € Trinkgeld je Stufe, max. +10 €)* — mehrere Gäste schnell hintereinander
      bedienen gibt eine Kombo-Anzeige und steigendes Trinkgeld; reißt nach 8 s ab. *Ich, M*
- [x] **2.2 Tische reagieren** *(v114: bei guter Stimmung tanzen 2–3 Gäste je Tisch auf dem Tisch)* — bediente Tische stoßen an („Prost!"), ab
      19:00 steigen Gäste auf die Bänke und schunkeln; volle Stimmung = sichtbare
      Wirkung (mehr Trinkgeld). *Ich, M*
- [x] **2.3 Mehrere Krüge tragen (Spieler)** *(v123: bis zu 3 volle Krüge, je Krug 12 % langsamer, passender Krug wird automatisch serviert)* — Spieler kann 2, mit Aufstufung
      bis 4 Krüge tragen, dafür langsamer laufen. Belohnt Planung. *Ich, M*
- [ ] **2.4 Saft & Rückmeldung** — Geld-Zahlen fliegen zur Anzeige, kurze
      Kamera-Wackler bei Kotzen, Konfetti bei Meilenstein, Zapfhahn-Füllanzeige
      am Krug. *Ich, S–M*
- [ ] **2.5 Betrunkene Gäste als Spielelement** — Sturzpegel: torkeln,
      umfallen, Krüge verschütten; Spieler kann „Wasser" bringen oder den Gast
      vor die Tür begleiten. *Ich, M*

## Phase 3 · Jeder Tag anders (Abwechslung)

- [x] **3.1 Tagesereignisse** *(v116: Touristenbus, Hygienekontrolle, Happy Hour, Fass kaputt,
      Prosit-Tag, Promi — ab Tag 3 zu 70 %, Anzeige in der HUD-Leiste. Offen: Regen, Stromausfall, Junggesellenabschied)* — morgens wird eins angekündigt (max. 1 pro Tag,
      ab Tag 3): *Ich, M–L*
      - 🌧 **Regen** — doppelt so viele Gäste, alle kommen nass rein (mehr Dreck)
      - 📸 **Promi-Besuch** — ein VIP-Tisch, wird er perfekt bedient: +20 % Beliebtheit
      - 🚨 **Hygienekontrolle** um 15:00 — Sauberkeit unter 60 % kostet Strafe
      - ⚡ **Stromausfall** 10 Minuten — Zapfhähne gehen nur per Hand langsamer, dunkel
      - 🎉 **Junggesellenabschied** — laute Gruppe, bestellt viel, kotzt viel
      - 🥨 **Brezn-Tag** — Essen doppelt so gefragt
      - 🍺 **Fass kaputt** — eine Sorte fällt aus, Gäste umstimmen
      - 🎺 **„Ein Prosit"** — alle 30 Min. stehen alle auf: 20 s alle Bestellungen doppelt
- [x] **3.2 Gästetypen** *(v122: Stammgast, Tourist, Trachtler, VIP — Symbol in der Blase)* — Stammgast (geduldig, gibt viel Trinkgeld, merkt sich
      schlechten Service), Tourist (ungeduldig, bestellt Essen), Trachtler (nur
      Helles, bleibt lange), Kater-Gast (wird schnell übel), VIP. Aussehen über die
      Figuren. *Ich, M*
- [ ] **3.3 Reservierungen** — morgens Anfragen „Tisch für 6 um 18:00" annehmen
      oder ablehnen; freihalten oder Strafe. Planungsspaß in der Pause. *Ich, M*
- [ ] **3.4 Wetter & Tageslicht** — Sonne/Wolken/Regen beeinflusst Andrang;
      Abendstimmung mit Lichtern (hängt an 0.1). *Ich, S–M*

## Phase 4 · Ein Ziel und ein Grund weiterzuspielen (Langzeit)

- [x] **4.1 Saison statt endlos** *(v117: Wiesn = 16 Tage, Tag 16 Finale mit Star-Act gratis und
      1,3× Andrang, danach Bewertung 1–5 Maßkrüge und die nächste Wiesn; Tageszähler läuft weiter,
      Kosten steigen. HUD „Tag 5/16". Neue Meilensteine SAISON_1, WIESN_WIRT_5)* — eine Wiesn dauert **16 Tage**; letzter Tag
      ist das große Finale (voller Andrang, Star-Act umsonst). Danach Bewertung
      mit 1–5 Maßkrügen (Umsatz, Beliebtheit, Sauberkeit, Meilensteine). *Ich, M*
- [x] **4.2 Nächstes Jahr** *(v124: je weiterer Wiesn +20 % Miete, −6 % Geduld, +10 % Gäste.
      Anlass: Bot-Lauf mit Gästetypen — ab Tag 12 alles ausgebaut, Geld stieg bis Tag 30 auf 21.000 €.
      Offen: echte Geldsenken/Freischaltungen 4.3, Personal-Eigenschaften 4.4)* — nach der Saison geht es weiter mit Bonus
      (Startgeld, freigeschaltete Dinge bleiben), aber schwerer: teurere Miete,
      anspruchsvollere Gäste. Endlosmodus bleibt als Option. *Ich, M*
- [ ] **4.3 Freischaltungen über Saisons** — neues Essen (Hendl, Obatzda,
      Radi), Getränke (Alkoholfrei, Spezi), Zeltthemen (Hofbräu-Blau, Hacker-Rot),
      Kostüme für den Spieler, weitere Einrichtung (Maibaum, Lebkuchenherzen,
      Hirschgeweih). *Ich, M–L · Du: Modelle*
- [x] **4.4 Personal mit Eigenschaften** *(v125: Flink, Gemütlich, Charmeur, Schluckspecht, Unauffällig — zufällig beim Einstellen, wird gespeichert; Lohn verhandeln offen)* — Bewerber haben 1 Eigenschaft
      („schnell", „trinkt heimlich", „Charmeur: +Trinkgeld"), Lohn verhandeln. *Ich, M*
- [x] **4.5 Mehr Meilensteine** *(v120: 15 → 23, u. a. Tanzen, Kotzbrocken-Zelt, Kombo ×10, Tage ohne Pfütze)* — 13 → 30, darunter witzige („100 Mal
      gekotzt wurde in deinem Zelt", „Schließe einen Tag ohne Pfütze"). *Ich, S*
- [ ] **4.6 Rangliste** — Steam-Bestenliste „bester Saisonumsatz". *Ich, S (braucht App-ID)*

## Phase 5 · Koop mit eigenen Momenten

- [x] **5.1 Andrang wächst mit Spielerzahl** *(v119: +50 % je weiterem Spieler)* — 2 Spieler = 1,5× Gäste,
      4 Spieler = 2,5×, sonst ist Koop zu leicht. *Ich, S*
- [ ] **5.2 Zusammenarbeit belohnen** — Übergabe von Krügen zwischen Spielern,
      „Team-Kombo" wenn verschiedene Spieler am selben Tisch bedienen. *Ich, M*
- [x] **5.3 Ping-System** *(v121: Taste R markiert Gast/Pfütze/Paket für alle, 5 s, Farbe je Spieler)* — Taste markiert Gast/Pfütze/Paket für Mitspieler. *Ich, S*
- [ ] **5.4 Koop-Ereignisse** — z. B. Schlägerei am Tisch: zwei Spieler
      gleichzeitig nötig. *Ich, M*

## Phase 6 · Balancing & Schwierigkeit

- [x] **6.1 Schwierigkeitsstufen** *(v119: Auswahl beim neuen Spiel; Startgeld, Geduld, Andrang, Miete)* beim neuen Spiel: *Gemütlich* (geduldige
      Gäste, kein Kredit-Druck), *Normal*, *Wiesn-Wahnsinn*. *Ich, S*
- [ ] **6.2 Wirtschaft nach Bot-Daten einstellen** (aus 0.2): Ausbau-Zeitpunkte
      so, dass man etwa alle 2 Tage etwas Neues kaufen kann; Zeltstufe 3 um Tag 12. *Ich, M*
- [ ] **6.3 Weiche Niederlagen** — Pleite nicht nur Kredit, sondern witziges
      Ereignis („Die Brauerei schickt ihren Neffen als Aufpasser"). *Ich, S*

## Phase 7 · Finalisieren

- [ ] **7.1 Figur Frau mit Rock-Knochen** — Modell in Blender nachrüsten, dann
      darf sie sitzen. *Du (Blender) oder neues Modell, Ich: einbauen*
- [ ] **7.2 Controller-Unterstützung** (Steam Deck!) *Ich, M*
- [ ] **7.3 Leistung auf schwachen Rechnern** messen (Plan B2) *Du: Rechner, Ich: Anpassen*
- [ ] **7.4 Lokalisierung neuer Texte** de/en/tr, Muttersprachler gegenlesen *Ich + Du*
- [ ] **7.5 Store-Material** mit F12-Screenshots aus Phase 2–4 *Du*
- [ ] **7.6 Demo** — Tag 1–3 als kostenlose Demo fürs Steam Next Fest *Ich, S*

---

## Reihenfolge und Begründung

1. **Phase 0** zuerst — ohne Messung bauen wir womöglich Inhalte gegen das
   falsche Problem.
2. **Phase 1 + Ton** — entscheidet, ob Leute nach 10 Minuten noch spielen.
   Steam-Rückgaben passieren in den ersten 2 Stunden.
3. **Phase 2** — macht jede Minute besser, auch alles, was danach kommt.
4. **Phase 3** — gegen Langeweile ab Tag 5.
5. **Phase 4** — gegen „Wofür eigentlich?" ab Tag 10.
6. **Phase 5, 6** — Feinschliff, Koop-Wert fürs Marketing.
7. **Phase 7** — Release-Reife.

**Größte Hebel pro Aufwand:** 0.1 Testschalter · 1.1 Schnellstart · 1.6 Ton ·
2.1 Kombo · 3.1 Ereignisse · 4.1 Saisonziel.

**Was ich als Nächstes vorschlage:** 0.1 bis 0.3 (Testschalter, Spielbot,
Messung der ersten 10 Minuten), danach entscheiden wir mit echten Zahlen über
Phase 1.
