# Release-Plan: bis zum ersten Steam-Upload

Stand 25.09.2026, v251. App-ID **5327191**.

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

### A1 ⚠️ Ton — der größte sichtbare Mangel *(Du lieferst, ich baue ein)*

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
- [ ] Zweiter Durchgang: kasse, zapfen, prost, schritte, tuer, muenzen *(Du, danach)* — schritte + Regen da

**Merke:** Sobald die Dateien unter `assets/audio/sfx/<name>.ogg` liegen, nimmt
das Spiel sie automatisch statt der Pieptöne. Der Einbau ist also billig — das
Besorgen ist die Arbeit.

### A2 ⚠️ Figuren — vier Gesichter im vollen Zelt *(Du)*

24 Tische, drei Gesichter. Das sieht man auf jedem Screenshot. `charakter3` kann
nicht sitzen (Rock ohne Knochen) und steht deshalb als Stehgast herum.

- [ ] 4–6 weitere Gästefiguren *(Du)*
- [ ] Dirndl-Figur mit Rock-Knochen — ersetzt den Stehgast-Notbehelf *(Du)*
- [ ] Eigene Figur für Huber (heute Bean, nur größer) *(Du)*
- [ ] Einbauen und mit `tools/render_gaeste` prüfen *(Ich)*

**Untergrenze für den Upload:** 6 sitzfähige Figuren. Darunter fällt es auf.

### A3 Die ersten zehn Minuten *(Ich)*

Gemessen: erster bedienter Gast nach **3,4 min**, erste Bilanz nach 7,5 min.
Genau dort steigen neue Spieler aus, und genau das sieht ein Rezensent.

- [ ] Wege und Wartezeiten am Anfang kürzen
- [ ] Erste Lieferung beschleunigen
- [ ] Neu messen mit `tools/sim_saison`, Ziel unter 2 min

### A4 Wirtschaft ab Tag 7 *(Ich baue, Du entscheidest die Richtung)*

Der Bot zeigt: Ab Tag 7 springen die Löhne auf 581 €/Tag und bleiben, der
Leerlauf fällt auf null, trotzdem gehen 70–85 Bestellungen daneben. Zweimal
Rettungskredit in elf Tagen.

- [ ] Entscheidung: soll es so hart sein? *(Du)*
- [ ] Lohnkurve und Gästeandrang nachziehen *(Ich)*
- [ ] Gegenprobe über 30 Tage *(Ich)*

### A5 Das Spiel wird über eine lange Saison langsam *(Ich)*

Bei Tag 21 belegte der Prozess 3 GB statt 1,5 GB, ein Spieltag dauerte über 45
Minuten statt zwei. Im Spiel gemessener Speicher wächst nur um 23 MB — der
Zuwachs steckt außerhalb von Godots Zählung.

- [ ] Ursache finden (`tools/speicher_messen.sh`, Messung war angefangen)
- [ ] Beheben und über 30 Tage gegenprüfen

**Warum das vor dem Upload muss:** Mit 8 GB Mindestanforderung wird das eng, und
es trifft genau die Spieler, die das Spiel mögen — die lange spielen.

### A6 Controller zu Ende bringen *(Ich, klein)*

Eingabe, Symbole für Xbox/PlayStation/Steam Deck und die Einstellungen stehen.
Offen:

- [ ] Menüs mit Controller durchspielen: Schieberegler, Auswahlfelder, Umbelegen
- [ ] Automatisch pausieren, wenn der Controller ausgeht (Steam-Kriterium)
- [ ] Am echten Gerät testen *(Du)* — der Gerätename steht in den Einstellungen

### A7 Letzter Durchgang *(Du)*

- [ ] Eine komplette Saison allein durchspielen, ohne dass ich eingreife
- [ ] Eine Saison im Koop zu viert
- [ ] 3–5 Außenstehende spielen lassen, zuschauen, nichts erklären
- [ ] Schwacher Rechner mit eingebauter Grafik
- [ ] Türkisch und Englisch gegenlesen lassen

---

## Block B · Was Steam braucht

Läuft parallel zu A. Manches dauert extern lange, deshalb früh anfangen.

### B1 ⚠️ Rechtliches — kann dich am längsten aufhalten *(Du)*

- [ ] **Markenfrage klären.** „Wiesn" und „Oktoberfest" sind raus, aber lass
      einen Anwalt draufschauen, bevor der Store-Eintrag steht
- [ ] **Lizenznachweise** — 5 Zeilen in `docs/lizenzen/README.md` stehen auf ⚠️:
      Kirmes-Pack, Meshy (Rechnung + Erzeugungsdatum), Suno, UI-Grafiken,
      Steamworks SDK
- [ ] **Alterseinstufung** — das Spiel handelt von Alkohol, es wird getrunken,
      gekotzt und geprügelt
- [ ] **KI-Angabe** im Content Survey: Meshy (Modelle), Suno (Musik), ChatGPT
      (UI-Grafiken)
- [ ] **Impressum und Datenschutz** — der Koop-Vermittler verarbeitet IP-Adressen
- [ ] Steuerformular und Bankdaten bei Valve

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

- [ ] Mindestens 5 Screenshots 1920×1080 — Spielstand liegt auf Platz 3
      (`bash tools/screenshot_stand.sh 3`), ich kann sie aufnehmen
- [ ] Trailer hochladen — liegt fertig in `build/trailer_ohne_musik.mp4`

### B3 Errungenschaften *(Du pflegt ein, ich habe die Texte)*

23 Stück sind im Code fertig und lösen aus. In Steamworks existieren sie nicht.

- [ ] 23 Einträge anlegen — API-Namen **genau** wie in
      `docs/steam/errungenschaften_texte.md`
- [ ] 46 Symbole (erreicht + grau, je 256×256)
- [ ] Mit zwei Konten prüfen, dass sie wirklich auslösen

### B4 Technisches in Steamworks *(Du)*

- [ ] Depot anlegen, Build hochladen (erst in den Zweig `beta`)
- [ ] `steam_appid.txt` **nicht** mit hochladen — der Export legt sie nicht nach
      `build/steam/`, also passt es, solange du diesen Ordner nimmst
- [ ] Auto-Cloud für `user://saves/` einrichten
- [ ] Rich Presence hochladen (`docs/steam/*.vdf` liegen bereit)
- [ ] Preis und Regionalpreise
- [ ] Systemanforderungen eintragen (stehen in `docs/steam/store_seite.md`)

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
