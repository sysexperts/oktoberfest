# Steam-Ready: was bis zur Veröffentlichung fehlt

Stand: 24.09.2026, v250. Steamworks ist genehmigt.

Grundlage ist der geprüfte Zustand im Repo, nicht die ältere
`docs/RELEASE_CHECKLISTE.md` — wo beide sich widersprechen, gilt diese Datei.

**Ich** = Claude erledigt es im Code · **Du** = braucht dich (Konto, Geld,
Dateien, Entscheidung, Anwalt).

Reihenfolge: A blockiert alles andere. B und E dauern extern am längsten und
sollten parallel früh starten. C und D lassen sich bis zuletzt schieben.

---

## A · Blocker — ohne das kein Release

### A1 ⚠️ Der Name ist inkonsistent und markenrechtlich riskant *(Du entscheidest, ich setze um)*

Im Spiel heißen drei verschiedene Dinge unterschiedlich:

| Ort | Wert |
|---|---|
| `project.godot` → `config/name` | Oktoberfest Simulator |
| `export_presets.cfg` (beide Presets) → `product_name`, `file_description` | Oktoberfest Simulator |
| `locale/texte.csv` → `GAME_TITLE` | Oktoberfest Simulator (alle drei Sprachen) |
| Sepps Brief im Spiel (`texte.csv` Zeile 686 ff.) | Sloptoberfest |
| Logo (`scripts/ui/logo_animiert.gd`, `assets/ui/ui_bogen.png`) | Sloptoberfest |

„Oktoberfest" und „Wiesn" sind Marken der Landeshauptstadt München. Das steht
seit der alten Checkliste als Pflichtpunkt drin und ist bis heute offen.
Entscheidung nötig: heißt das Spiel überall **Sloptoberfest**, dann müssen
Fenstertitel, exe-Metadaten und `GAME_TITLE` nachziehen — und der Store-Eintrag
wird unter diesem Namen angelegt. Danach ist der Name auf Steam nur noch mit
Aufwand änderbar.

- [ ] Entscheidung: endgültiger Name *(Du)*
- [ ] Anwaltliche Einschätzung, ob „Oktoberfest" im Beschreibungstext auftauchen darf *(Du)*
- [ ] `config/name`, beide Export-Presets, `GAME_TITLE` in drei Sprachen angleichen *(Ich)*
- [ ] Prüfen, wo der alte Name sonst noch steht (Speicherordner `user://`, ZIP-Namen, Servertexte) *(Ich)*

### A2 ⚠️ Das Spiel läuft auf Steams Test-App 480 *(Du lieferst App-ID, ich baue ein)*

`project.godot` hat `[steam] app_id=480` — das ist Valves öffentliche Test-App
„Spacewar". Damit funktionieren Lobbys und Overlay zwar zum Ausprobieren, aber:
keine echten Errungenschaften, keine Cloud, kein Kauf, und `restartAppIfNecessary`
ist bewusst abgeschaltet (`autoload/steam_dienst.gd:64`).

- [ ] Echte App-ID aus Steamworks *(Du)*
- [ ] `app_id` eintragen, `steam_appid.txt` für lokale Tests anlegen (nicht ins Depot!) *(Ich)*
- [ ] Prüfen, dass `restartAppIfNecessary` mit echter ID greift *(Ich)*

### A3 ⚠️ Die exe hat kein Icon

Beide Export-Presets haben `application/icon=""`. Die exe zeigt damit Godots
Standardsymbol — im Store, in der Taskleiste und in der Bibliothek.

- [ ] Icon als `.ico` (256, 128, 64, 48, 32, 16 px in einer Datei) *(Du)*
- [ ] In beide Presets eintragen, Export prüfen *(Ich)*

### A4 ⚠️ Der Ton ist zur Hälfte Platzhalter

Musik ist da: 13 Stücke in `assets/music/` (Suno). Bei den Effekten sieht es
anders aus — echte Dateien gibt es nur fünf, alle für die Oberfläche
(`ui_hover`, `ui_klick`, `ui_schalter`, `ui_wechsel`, `ui_zurueck`).

Alles andere erzeugt `scripts/sfx.gd` als Piepton: **pop, ding, glug, sizzle,
scrub, splash, cheer, honk** — also Zapfen, Kasse, Kochen, Putzen, Jubel, Hupe.
Das sind genau die Geräusche, die man in einer Schicht hundertmal hört.

Dazu fehlt `assets/audio/ambiente/kirmes.*` komplett — der Ordner existiert
nicht. Draußen ist es dadurch still.

- [ ] 8 Effektdateien als Ersatz für die Pieptöne *(Du)*
- [ ] Kirmes-Ambiente als Schleife *(Du)*
- [ ] Wunschliste aus `docs/AUDIO.md`: kasse, zapfen, prost, schritte, tuer, muenzen, fahrgeschaeft *(Du)*
- [ ] Einbauen und Lautstärken abgleichen *(Ich)*

### A5 ⚠️ Lizenznachweise fehlen

Aus `docs/lizenzen/README.md` stehen fünf Zeilen auf ⚠️, und das Register ist
nicht mehr aktuell (es nennt AIMusic.so, im Projekt liegt Suno-Musik):

- [ ] Kirmes-Pack: Kaufbeleg + Lizenztext ablegen, auf „Editorial Use Only" prüfen *(Du)*
- [ ] Meshy: Abo-Rechnung, Lizenzseite mit Datum, Erzeugungsdatum der Modelle *(Du)*
- [ ] Musik: Suno-Tarif klären (kommerzielle Rechte), Nachweis ablegen — das Register auf Suno umschreiben *(Du + Ich)*
- [ ] Modelle vom 12.09.: Herkunft bestätigen *(Du)*
- [ ] UI-Grafiken aus ChatGPT: Tarif und Datum ablegen *(Du)*
- [ ] Register aktualisieren, sobald die Belege da sind *(Ich)*

### A6 ⚠️ Alterseinstufung und KI-Angabe

Das Spiel dreht sich um Alkohol, es wird getrunken, man wird betrunken, es gibt
Erbrechen und Prügeleien. Valve verlangt dazu Angaben im Content Survey, ebenso
zu KI-erzeugten Inhalten (Meshy-Modelle, Suno-Musik, ChatGPT-UI-Grafiken).

- [ ] Content Survey ausfüllen *(Du)*
- [ ] KI-Angabe formulieren — alle drei Quellen nennen *(Du, Vorlage von mir)*

---

## B · Steamworks-Backend *(überwiegend Du)*

### B1 Store-Seite
- [ ] Beschreibung in drei Sprachen einpflegen (Entwurf liegt vor)
- [ ] Kurzbeschreibung (max. 300 Zeichen) — fehlt noch
- [ ] Systemanforderungen (ausgefüllt, Speicherplatz noch schätzen: echten Export messen)
- [ ] Genre, Schlagwörter, Kategorien
- [ ] Release-Datum oder „demnächst"

### B2 Store-Grafiken — alle Pflichtgrößen
- [ ] Kopfkapsel 460×215 und 920×430
- [ ] Kleine Kapsel 231×87
- [ ] Hauptkapsel 616×353
- [ ] Vertikale Kapsel 374×448
- [ ] Seitenhintergrund 1438×810
- [ ] Bibliothek: Hochformat 600×900, Held 3840×1240, Logo 1280×720 (transparent)
- [ ] Mindestens 5 Screenshots 1920×1080 — Spielstand dafür liegt auf Platz 3 (`tools/screenshot_stand.sh`)

### B3 Trailer
- [ ] Trailer in **1920×1080** neu rendern — die aktuelle Fassung ist 1440×810, weil `--resolution` im Aufnahmemodus ignoriert wird *(Ich)*
- [ ] Lieferwagen-Szene reparieren: `render_trailer.gd` ruft `VAN_START`/`VAN_DROP`/`VAN_END`, die API heißt heute `VAN_REIN`/`VAN_RAUS`/`DROP_POINT` *(Ich)*
- [ ] Musik unter den Trailer legen — erst wenn A5 geklärt ist *(Du + Ich)*
- [ ] Hochladen, Sprachfassungen zuordnen

### B4 Errungenschaften
23 Stück sind im Code fertig (`scripts/meilensteine.gd`), inklusive Auslöser und
Steam-Aufruf (`steam_dienst.errungenschaft`). In Steamworks existieren sie noch nicht.

- [ ] 23 Einträge anlegen, API-Namen exakt wie die IDs im Code *(Du, Liste in `docs/steam/errungenschaften.md`)*
- [ ] 46 Symbole (je freigeschaltet/gesperrt, 256×256) *(Du)*
- [ ] Namen und Beschreibungen in drei Sprachen *(Ich liefere Texte)*
- [ ] Mit zwei Konten prüfen, dass sie wirklich auslösen

### B5 Rich Presence
Die drei `.vdf`-Dateien liegen in `docs/steam/` und werden im Code schon benutzt.
- [ ] In Steamworks hochladen (sonst zeigt die Freundesliste nur Rohtokens)

### B6 Cloud
Spielstände liegen in `user://saves/slot_1..3.json`, Einstellungen in
`user://einstellungen.cfg`.
- [ ] Auto-Cloud einrichten, Pfadmuster eintragen
- [ ] Prüfen, dass der Wechsel zwischen zwei Rechnern keinen Stand zerschießt

### B7 Depots und Build
- [ ] Depot anlegen, Steam-Preset exportieren (`custom_features="steam"`)
- [ ] `steam_api64.dll` neben die exe ins Depot (liegt in `addons/godotsteam/win64/`)
- [ ] Startoptionen eintragen
- [ ] Erst in den Zweig `beta` hochladen, dort testen, dann `default`
- [ ] Prüfen, dass der Steam-Build **nichts** von unserem Server nachlädt (`scripts/boot.gd` überspringt das bei `OS.has_feature("steam")` — im echten Build gegenprüfen)

### B8 Geschäftliches
- [ ] Steuerformular und Bankdaten
- [ ] Preis festlegen, Regionalpreise prüfen
- [ ] 30 Tage Vorlauf: Store-Seite muss vor dem Release freigegeben sein

---

## C · Code und Technik *(Ich)*

### C1 Steam Deck und Controller — fehlt komplett
`project.godot` hat keinen `[input]`-Abschnitt; Tasten werden zur Laufzeit
angelegt (`scripts/player.gd:103`, `autoload/einstellungen.gd`). Gamepad kommt
nirgends vor. Damit ist das Spiel auf dem Steam Deck nicht spielbar und fällt
bei der Deck-Prüfung durch.

- [ ] Eingabekarte um Joypad-Ereignisse erweitern
- [ ] Zielen und Menüführung mit Stick
- [ ] Bildschirmtastatur für Namenseingabe
- [ ] Steam-Input-Konfiguration hinterlegen
- [ ] Entscheidung: gehen wir auf „Deck verifiziert" oder reicht „spielbar"? *(Du)*

### C2 Erste zehn Minuten
Aus `docs/PLAN_SPASS.md`: erster bedienter Gast nach 3,4 min, erste Tagesbilanz
nach 7 min — Ziel war 2 min. Genau dort steigen neue Spieler aus, und genau das
sehen Rezensenten.
- [ ] Neu messen (`tools/sim_saison.tscn`), danach kürzen

### C3 Balancing-Lauf zum Schluss
Der letzte dokumentierte Bot-Lauf ist von 09/2026 und lief in eine Todesspirale.
Seitdem kamen Story, Personal, Braukeller, Minispiele dazu.
- [ ] 30 Tage Bot laufen lassen, Kurve prüfen
- [ ] Schwierigkeitsgrade gegenprüfen

### C4 Fehlerbild im Betrieb
- [ ] Was passiert bei Verbindungsabbruch mitten in der Schicht? (Koop, Vermittler weg)
- [ ] Was passiert, wenn der Spielstand beschädigt ist? (JSON kaputt → heute stiller Neustart)
- [ ] Absturzberichte: wenigstens eine Logdatei in `user://`, die man sich schicken lassen kann

### C5 Speicherformat einfrieren
`Net.SAVE_FORMAT = 1`. Nach Release ändert sich das Format nicht mehr ohne
Migration — sonst verlieren Käufer ihre Stände.
- [ ] Alle Felder durchgehen, die noch fehlen könnten, **vor** dem Release ergänzen
- [ ] Migrationspfad schreiben, falls doch etwas dazukommt

### C6 Leistung
- [ ] Buden-Meshes zusammenfassen (steht seit v188 offen)
- [ ] Messung auf schwacher Hardware (`tools/perf_messen`, Render-ms vergleichen — FPS im Testfenster ist unbrauchbar)
- [ ] Mindestanforderungen danach korrigieren

### C7 Aufräumen
- [ ] `tools/` bleibt aus den Release-Paketen draußen (prüfen)
- [ ] Debug-Ausgaben und Testschalter suchen (`ALWAYS_NIGHT` war schon mal an)
- [ ] Keine CI vorhanden: wenigstens ein Skript, das alle 19 `tools/test_*.tscn` nacheinander laufen lässt und Fehler sammelt

---

## D · Inhalt und Assets *(Du liefert, ich baue ein)*

### D1 Figuren — der sichtbarste Mangel
Es gibt vier: `bean`, `charakter2`, `charakter3`, `alex`. Davon kann
`charakter3` nicht sitzen (Rock ohne Knochen, spreizt zur Scheibe) und wird
deshalb als Stehgast behandelt (`scripts/figuren.gd:16`). Im vollen Zelt sitzen
also 24 Tische voll mit drei Gesichtern.

- [ ] 6–8 Gästefiguren
- [ ] Dirndl-Figur mit Rock-Knochen (ersetzt den Stehgast-Notbehelf)
- [ ] Eigene Figur für Huber (heute Bean, nur größer)
- [ ] Personal optisch unterscheidbar (Koch, Kellner, Reinigung, Zapfer)
- [ ] 4 unterscheidbare Spielerfiguren für Koop

### D2 Modelle, die noch Platzhalter sind
- [ ] Schanktheke (`scenes/schanktheke.tscn`)
- [ ] Lager-Regal mit Kästen
- [ ] Paket/Lieferkiste
- [ ] Riesenrad als echtes Modell (heute ~100 Einzelteile — auch ein Leistungsthema)

### D3 Karte
- [ ] Außengrenze ablaufen: nirgends raus, nirgends ins Leere fallen
- [ ] Hängenbleib-Ecken zwischen Buden, Bänken, Bäumen
- [ ] Schwebende und versunkene Objekte
- [ ] Nachtbeleuchtung: keine dunklen Löcher

### D4 Ladebildschirm
- [ ] Bilder statt nur Tipp-Text

---

## E · Recht und Betrieb *(Du)*

- [ ] Impressum und Datenschutzerklärung — der Vermittler (`tools/server/vermittler.py`) verarbeitet IP-Adressen, das ist meldepflichtig
- [ ] Entscheidung: bleibt der eigene Koop-Server nach Release an? Wer zahlt ihn, wie lange, was passiert mit laufenden Spielen, wenn er abgeschaltet wird
- [ ] Steam-Version: läuft Koop dort ausschließlich über Steam-Lobbys, oder bleibt der Einladungscode parallel? Zwei Wege heißt zweimal testen
- [ ] AGB/EULA — Standard von Valve reicht meist, einmal prüfen

---

## F · Testen *(Du, teils mit mir)*

- [ ] Eine komplette Saison allein durchspielen, ohne Eingriff von mir
- [ ] Eine Saison im Koop zu viert
- [ ] Steam-Test: zwei Konten, zwei Rechner — Einladung, Beitritt, Overlay, Errungenschaften, Cloud
- [ ] 3–5 Außenstehende spielen lassen, zuschauen, nichts erklären
- [ ] Schwacher Rechner mit integrierter Grafik
- [ ] Steam Deck, falls C1 gemacht wird
- [ ] Türkisch und Englisch gegenlesen lassen (1013 Zeilen, keine Lücken, aber ungeprüft)
- [ ] Aus der fertigen Steam-exe testen, nicht aus dem Editor

---

## G · Danach, nicht vorher

- [ ] Demo Tag 1–3 fürs Next Fest
- [ ] Rangliste
- [ ] Weitere Sprachen
- [ ] Koop-Chaos-Ereignisse (`docs/RELEASE_CHECKLISTE.md` Abschnitt 9)

---

## Was mich am meisten beunruhigt

1. **Der Name** (A1). Er hängt an allem: Store-Eintrag, exe, Marke. Und er ist
   der einzige Punkt, bei dem ein Fehler teuer wird statt nur lästig.
2. **Die Pieptöne** (A4). Ein Kirmesspiel ohne Ton wirkt kaputt, egal wie gut der
   Rest ist. Das sieht man in jedem Trailer und hört es in jedem Let's Play.
3. **Drei Gesichter im vollen Zelt** (D1). Das fällt auf den Screenshots auf, die
   wir gerade gemacht haben.
4. **Steam Deck** (C1). Kein Blocker für den Release, aber ohne Controller fällt
   ein großer Teil der Käufer weg.
