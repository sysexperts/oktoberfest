# Release-Plan: bis zum ersten Steam-Upload

Stand 30.09.2026, v284. App-ID **5327190**.

**Erledigt seit v251:** Ton (A1) komplett, Figuren (A2) mit zehn sitzfähigen
Gästefiguren, Steam-Upload läuft über `tools/steam_upload.sh`.
Block B (Recht, Store-Grafiken, Screenshots, Trailer, Steamworks), die Tests (A7)
und die Karte (Außengrenze, Hängenbleib-Ecken) sind laut Serdar erledigt.

**Offen vor dem Release:** nur noch das Nachspielen der Controller-Änderungen am
Gerät (A6). Verbindungsabbruch im Koop ist im Code abgedeckt (`Net._on_server_weg`
→ Hauptmenü mit Meldung, Host räumt gegangene Spieler auf), aber nicht neu getestet.

Das hier ist unsere Arbeitsliste. Wir gehen sie zusammen von oben nach unten
durch. `docs/STEAM_READY.md` bleibt die vollständige Bestandsaufnahme — dieser
Plan sagt, **in welcher Reihenfolge** wir was tun und **wann wir hochladen**.

**Ich** = Claude · **Du** = Serdar (Konto, Geld, Material, Entscheidung)

---

## Die Grundidee

Wir laden hoch, **sobald das Spiel verkaufsfähig ist** — nicht wenn es perfekt
ist. Danach gehen Änderungen als Steam-Update raus, und zwar ohne unseren
eigenen Update-Server: Steam liefert selbst aus.

Das teilt die Arbeit in drei Blöcke:

| Block | Was | Wann fertig |
|---|---|---|
| **A** | Was das Spiel zum Verkauf braucht | vor dem Upload |
| **B** | Was Steam zum Freischalten braucht | parallel zu A |
| **C** | Was nach dem Upload kommt | danach, laufend |

Ein Punkt gilt als erledigt, wenn er **im Spiel funktioniert und geprüft ist** —
nicht wenn der Code geschrieben ist.

---

## Block A · Das Spiel fertigstellen

### A1 ✅ Ton — erledigt (30.09.2026)

Ohne das wirkt jedes Video und jeder Stream kaputt. Heute gibt es **5 echte
Klänge**, alle für die Oberfläche. Diese acht sind Pieptöne aus `scripts/sfx.gd`:

| Klang | Wo man ihn hört |
|---|---|
| `pop` | Krug nehmen, Gegenstand aufheben |
| `ding` | Bestellung fertig, Meldung |
| `glug` | Zapfen (der häufigste Ton im Spiel) |
| `sizzle` | Grill, Küche |
| `scrub` | Putzen, Fegen |
| `splash` | Pfütze, Verschütten |
| `cheer` | Jubel am Tisch, Prost |
| `honk` | Lieferwagen |

Dazu fehlt **`assets/audio/ambiente/kirmes.ogg`** komplett — der Ordner ist leer,
draußen ist es still.

- [x] Die acht Klänge besorgen *(Du)* — lizenzfrei, kommerziell nutzbar
- [x] Kirmes-Ambiente als nahtlose Schleife, 1–2 min *(Du)*
- [x] Einbauen, Lautstärken abgleichen, mit `tools/test_musik` prüfen *(Ich)*
- [x] Zweiter Durchgang: kasse, zapfen, prost, schritte, tuer, muenzen, Regen — alle da (30.09.2026)
- `krug_voll` bleibt beim Ersatz `ding`, `fahrgeschaeft` entfällt (Serdar: unnötig)

**Merke:** Sobald die Dateien unter `assets/audio/sfx/<name>.ogg` liegen, nimmt
das Spiel sie automatisch statt der Pieptöne. Der Einbau ist also billig — das
Besorgen ist die Arbeit.

### A2 ✅ Figuren — erledigt (Serdar, 30.09.2026)

Zehn Gästefiguren in `scripts/figuren.gd`: Bean, Wilhelm, Lisa, Alex und je
drei Varianten von Wilhelm und Alex (Kleidung, Hut, Bart, Brille). Lisa (Dirndl)
sitzt mit Sitzkorrektur (`assets/sitz_lisa.tres`), die Sitzanimationen hat
Serdar von Hand nachgezogen.

- [x] 4–6 weitere Gästefiguren
- [x] Dirndl-Figur sitzt (Sitzkorrektur statt Rock-Knochen)
- [x] Eigene Figur für Konrad (30.09.2026): character2 in Weinrot mit hohem Zylinderhut (Goldschnalle, Feder), zornigen Brauen, Zwirbelbart und Spitzbart — `scenes/figuren/konrad.tscn`, gebacken mit `tools/bake_zubehoer.gd` und `tools/bake_kleidung.gd`, Sichtprobe `tools/render_konrad.tscn`
- [x] Einbauen und mit `tools/render_gaeste` prüfen

**Untergrenze für den Upload:** 6 sitzfähige Figuren. Darunter fällt es auf.

### A3 Die ersten zehn Minuten *(Ich)* — entfällt, Tempo ist so in Ordnung (Serdar, 2026-09-25)

Gemessen: erster bedienter Gast nach **3,4 min**, erste Bilanz nach 7,5 min.
Genau dort steigen neue Spieler aus, und genau das sieht ein Rezensent.

- [x] Wege und Wartezeiten am Anfang kürzen
- [x] Erste Lieferung beschleunigen
- [x] Neu messen mit `tools/sim_saison`, Ziel unter 2 min

### A4 Wirtschaft ab Tag 7 *(Ich baue, Du entscheidest die Richtung)* — erledigt: Höchstsatz 300 €, Rest passt (2026-09-25)

Der Bot zeigt: Ab Tag 7 springen die Löhne auf 581 €/Tag und bleiben, der
Leerlauf fällt auf null, trotzdem gehen 70–85 Bestellungen daneben. Zweimal
Rettungskredit in elf Tagen.

- [x] Entscheidung: soll es so hart sein? *(Du)*
- [x] Lohnkurve und Gästeandrang nachziehen *(Ich)*
- [x] Gegenprobe über 30 Tage *(Ich)*

### A5 Das Spiel wird über eine lange Saison langsam *(Ich)* — Ursache war der Test-Bot (Lager-voll-Schleife), Spiel bleibt über 30 Tage bei ~1,45 GB

Bei Tag 21 belegte der Prozess 3 GB statt 1,5 GB, ein Spieltag dauerte über 45
Minuten statt zwei. Im Spiel gemessener Speicher wächst nur um 23 MB — der
Zuwachs steckt außerhalb von Godots Zählung.

- [x] Ursache finden (`tools/speicher_messen.sh`, Messung war angefangen)
- [x] Beheben und über 30 Tage gegenprüfen

**Warum das vor dem Upload muss:** Mit 8 GB Mindestanforderung wird das eng, und
es trifft genau die Spieler, die das Spiel mögen — die lange spielen.

### A6 Controller zu Ende bringen *(Ich, klein)*

Eingabe, Symbole für Xbox/PlayStation/Steam Deck und die Einstellungen stehen.
Offen:

- [x] Einstellungen am Controller (30.09.2026, `tools/test_pad_menue`): jedes Bedienelement erreichbar, LB/RB blättern die Kategorien, Regler laufen beim Halten, Umbelegen verliert den Fokus nicht mehr und lässt sich mit einem Knopf abbrechen
- [x] Pause liegt am Controller auf Start — B ist Springen und schloss vorher zugleich als ui_cancel das Pausemenü auf
- [x] Knopf „Logordner öffnen" in den Einstellungen
- [x] Belegung durchgesehen und mit nachgestellten Controller-Eingaben durchgespielt (30.09.2026, `tools/test_pad_spiel`, mit Fenster starten): Laufen, Umsehen, Springen, Pause, Festbüro, Zeltcomputer, elf Kirmesbuden
  - RT = zweites „Benutzen" und Auslösen in den Buden (mit A kann man nicht gleichzeitig zielen), LT halten = Bestellungen als Text und Luft anhalten an der Schießbude, R3 = Schulterkamera
  - Zielen mit dem rechten Stick blieb stehen (3°/s statt rund 20°/s): die nachgebildete Mausbewegung schaltete die Controller-Erkennung ab
  - Im offenen Fenster lief die Figur mit dem Stick los und A löste zusätzlich „Benutzen" aus; B schloss ein Fenster und sprang danach
  - Brief/Kino blätterte mit A zwei Seiten; Schichtbeginn liess sich nur mit Enter schliessen; Zeltname und Koop-Code ohne Bildschirmtastatur
  - Hilfe (Steuerkreuz links) zeigt am Controller die Controller-Belegung
  - Zweiter Durchgang: alle zwölf Buden gespielt (Zielen, Auslösen, Luft anhalten, Verlassen), dazu Krug nehmen, Zapfen, Fenster über die Welt öffnen, Gespräch mit Ja/Nein-Frage, Bezahlen beim Budenbesitzer
  - Stick-Zielen hing an der Auflösung (4K halb so schnell wie Full HD) — ausgeglichen; Zeiger im Fenstermodus über Bildkoordinaten statt Fensterpixel
- [ ] Am Gerät nachspielen *(Du)*: Maulwurf (Zeiger mit dem Stick — im Test liess sich der Zeiger nicht setzen, ungeprüft), Servieren/Putzen in einer offenen Schicht, Spielgefühl
- [x] Automatisch pausieren, wenn der Controller ausgeht (Steam-Kriterium)
- [x] Am echten Gerät testen *(Du)* — der Gerätename steht in den Einstellungen

### A7 ✅ Letzter Durchgang — erledigt (Serdar, 30.09.2026)

- [x] Eine komplette Saison allein durchspielen, ohne dass ich eingreife
- [x] Eine Saison im Koop zu viert
- [x] 3–5 Außenstehende spielen lassen, zuschauen, nichts erklären
- [x] Schwacher Rechner mit eingebauter Grafik
- [x] Türkisch und Englisch gegenlesen lassen

---

## Block B · Was Steam braucht — ✅ komplett erledigt (Serdar, 30.09.2026)

Läuft parallel zu A. Manches dauert extern lange, deshalb früh anfangen.

### B1 ⚠️ Rechtliches — kann dich am längsten aufhalten *(Du)*

- [x] **Markenfrage klären.** „Wiesn" und „Oktoberfest" sind raus, aber lass
      einen Anwalt draufschauen, bevor der Store-Eintrag steht
- [x] **Lizenznachweise** — 5 Zeilen in `docs/lizenzen/README.md` stehen auf ⚠️:
      Kirmes-Pack, Meshy (Rechnung + Erzeugungsdatum), Suno, UI-Grafiken,
      Steamworks SDK
- [x] **Alterseinstufung** — das Spiel handelt von Alkohol, es wird getrunken,
      gekotzt und geprügelt
- [x] **KI-Angabe** im Content Survey: Meshy (Modelle), Suno (Musik), ChatGPT
      (UI-Grafiken)
- [x] **Impressum und Datenschutz** — der Koop-Vermittler verarbeitet IP-Adressen
- [x] Steuerformular und Bankdaten bei Valve

### B2 ⚠️ Store-Grafiken *(Du)*

Der Text ist fertig (`docs/steam/store_seite.md`), die Bilder fehlen alle:

| Was | Größe |
|---|---|
| Kopfkapsel | 460×215 und 920×430 |
| Kleine Kapsel | 231×87 |
| Hauptkapsel | 616×353 |
| Vertikale Kapsel | 374×448 |
| Seitenhintergrund | 1438×810 |
| Bibliothek Hochformat | 600×900 |
| Bibliothek Held | 3840×1240 |
| Bibliothek Logo | 1280×720, transparent |

- [x] Mindestens 5 Screenshots 1920×1080 — Spielstand liegt auf Platz 3
      (`bash tools/screenshot_stand.sh 3`), ich kann sie aufnehmen
- [x] Trailer — wird gerade Szene für Szene neu gebaut (`tools/trailer`, Renders in `build/trailer/clips`)

### B3 Errungenschaften *(Du pflegt ein, ich habe die Texte)*

23 Stück sind im Code fertig und lösen aus. In Steamworks existieren sie nicht.

- [x] 23 Einträge anlegen — API-Namen **genau** wie in
      `docs/steam/errungenschaften_texte.md`
- [x] 46 Symbole (erreicht + grau, je 256×256) — `tools/bake_errungenschaften.gd` → build/errungenschaften
- [x] Mit zwei Konten prüfen, dass sie wirklich auslösen

### B4 Technisches in Steamworks *(Du)*

- [x] Depot anlegen, Build hochladen — `bash tools/steam_upload.sh`
- [x] `steam_appid.txt` **nicht** mit hochladen — der Export legt sie nicht nach
      `build/steam/`, also passt es, solange du diesen Ordner nimmst
- [x] Auto-Cloud für `user://saves/` einrichten
- [x] Rich Presence hochladen (`docs/steam/*.vdf` liegen bereit)
- [x] Preis und Regionalpreise
- [x] Systemanforderungen eintragen (stehen in `docs/steam/store_seite.md`)

**Wichtig zur Planung:** Die Store-Seite muss **30 Tage vor dem Verkaufsstart**
freigegeben sein. Das ist meist der längste Einzelposten.

---

## Block C · Nach dem Upload

Erst wenn A und B stehen. Diese Punkte sind **kein** Grund zu warten.

- [ ] Steam-Eingabe-API vollständig (die 200 Controller-Modelle) — braucht zwei
      Eingabewege, weil die ZIP-Version von deiner Website kein Steam kennt
- [ ] Minispiele und Baumodus richtig auf Controller umbauen statt über den
      Mauszeiger (17 Stellen, zwei davon brauchen einen Stick-Cursor)
- [ ] Demo für das Next Fest (Tag 1–3)
- [ ] Rangliste
- [ ] Buden-Meshes zusammenfassen (Leistung)
- [ ] Weitere Sprachen
- [ ] Koop-Chaos-Ereignisse

---

## Die Reihenfolge, die ich vorschlage

**Diese Woche**
1. Du: Ton besorgen (A1) — das blockiert am meisten und dauert extern
2. Du: Lizenznachweise zusammensuchen (B1) — reine Sucharbeit, kann nebenher laufen
3. Ich: Speicherproblem (A5) — das ist der einzige technische Blocker

**Danach**
4. Ich: erste zehn Minuten (A3) und Wirtschaft (A4)
5. Du: Figuren (A2)
6. Ich: Controller zu Ende (A6)

**Wenn das Spiel steht**
7. Du + ich: Screenshots und Store-Grafiken (B2)
8. Du: Steamworks ausfüllen (B1, B3, B4)
9. Du: Durchspielen und Fremdtest (A7)
10. Upload in den Beta-Zweig, testen, dann freigeben

---

## Woran wir merken, dass wir fertig sind

- Eine komplette Saison läuft ohne Absturz und ohne dass das Spiel langsam wird
- Ein Fremder versteht in den ersten zwei Minuten, was zu tun ist
- Der Ton trägt eine Schicht, ohne dass es nervt
- Im vollen Zelt sieht man mindestens sechs verschiedene Gesichter
- Ein Controller reicht, um von der Startseite bis zum Schlafengehen zu kommen
- Jede Zeile in `docs/lizenzen/README.md` steht auf ✅
