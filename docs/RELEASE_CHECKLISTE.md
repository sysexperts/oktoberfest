# Release-Checkliste

Stand: 18.09.2026 (v188). ⚠️ = Pflicht vor der Veröffentlichung.
**Du** = Nutzer liefert/erledigt · **Ich** = Code.

Reihenfolge-Tipp: Maßkrug + Essen und Ton zuerst → Figuren + Map → parallel
früh Namensprüfung und Steamworks starten (dauern am längsten).

---

## 1. 3D-Modelle *(Du)*

Aktuell Platzhalter aus Grundformen (Box/Zylinder).

### Im Zelt
- [x] ⚠️ Maßkrug (leer + voll mit Schaum) — Spielerhand, Kellner-Tablett, Ausgabe, Tisch *(v128: krug.glb als Glas mit Füllstand)*
- [x] ⚠️ Essen auf Teller: Brezn, Würstl, Hendl *(v128)*
- [x] ⚠️ Bierfass mit Zapfhahn (ein Modell, Sorte per Farbe im Code) *(v128)*
- [x] ⚠️ Krugspender/-regal an der Theke *(v128/v129: Krugstapel + Regalwand mit leeren Gläsern)*
- [ ] ⚠️ Schanktheke (`scenes/schanktheke.tscn` ist Platzhalter)
- [x] Kochstelle/Grill für die Essensstationen *(v129: kochtheke.glb an der Rückwand)*
- [x] Bühne (Podest, Rückwand, Traverse) + Lautsprecher, Instrumente *(v128: buehne.glb)*
- [ ] Lager-Regal mit Bierkästen und Zutatenkisten
- [x] Computer am Schreibtisch *(v129: schreibtisch.glb im Büroraum)*
- [x] Stehlampe (Einrichtung) *(v185: dazu 11 Büromöbel, gebacken mit tools/bake_moebel.gd)*
- [ ] Pfütze und Erbrochenes (Bodenflecken) *(Dreck fürs Tutorial fertig: Laub, Scherben, Papier, Stroh, Staub, Planen, Müllsack)*
- [ ] Zeltteile in `scenes/tent.tscn` (12 Platzhalter-Meshes)

### Draußen
- [x] ⚠️ Wohnwagen (eigener + Nachbarn) *(v168)*
- [x] ⚠️ Lieferwagen *(v179: tools/bake_lieferwagen.gd, fährt die Allee, wendet, schleudert NPCs)*
- [ ] Paket/Lieferkiste
- [x] Wiesenbüro: Schreibtisch, Buchungskiosk, am besten kleines Bürogebäude *(v179: eingerichtet, hell)*
- [ ] „Zelt zu vermieten"-Schild
- [ ] Marktstand-Markise, Laterne, Lichterkette
- [ ] Riesenrad als echtes Modell (heute ~100 Einzelteile)

### Einrichtung zum Kaufen (Spätspiel)
- [ ] Maibaum
- [ ] Lebkuchenherz-Wand
- [x] Hirschgeweih *(v130: Geweih-Kronleuchter, deco_1)*
- [x] Fahnen / Wimpel *(v130: Banner deco_7, Wimpelkette deco_8)*
- [ ] Blumenkübel
- [x] Weitere Lampen (Kronleuchter, Laternen) *(v130: Kronleuchter, Lichtergirlande, Hängelaterne)*
- [x] Regal zum Umstellen *(v130: regal.glb)*
- [x] Weitere Deko *(v130: Hopfengirlande, Riesenbrezel, Deko-Fass)*
- [ ] Zeltthemen: andere Stoff-/Dachfarben (Texturen)

## 2. Figuren *(Du, Einbau: Ich)*

Heute 3 Figuren: Bean, charakter2 (Mann), charakter3 (Dirndl, kann nicht sitzen).

- [ ] ⚠️ Mindestens 6–8 Gästefiguren (Mann/Frau, jung/alt, Tracht/normal, Tourist, VIP)
- [ ] ⚠️ Dirndl-Figur mit Rock-Knochen (sonst Rock als Scheibe beim Sitzen)
- [ ] Personal: Kellnerin (Dirndl), Kellner, Koch mit Schürze, Putzkraft, Zapfer
- [ ] Künstler: Blaskapelle (Trompete, Tuba), Sänger, DJ
- [ ] 4 unterscheidbare Spielerfiguren für Koop
- [ ] Animationen je Figur — **ohne Root Motion**: Stehen, Gehen, Rennen, 2× Tanzen, Sitzen+Trinken, Tragen, Kotzen, Jubeln/Prost
- [ ] Gleiches Skelett wie charakter2 (28 Knochen) → Animationen teilbar
- [ ] *(Ich)* Jede neue Figur mit `tools/modell_info.gd`, `render_figuren`, `render_gaeste` prüfen

## 3. Map fertig machen *(Du im Editor, Ich helfe)*

- [ ] ⚠️ Außengrenze rundum ablaufen — nirgends raus, nirgends ins Leere fallen
- [ ] ⚠️ Unsichtbare Wände (Bound*) an allen Kanten
- [ ] ⚠️ Hängenbleib-Ecken zwischen Buden, Bänken, Bäumen beseitigen
- [ ] Schwebende/versunkene Objekte auf Bodenhöhe setzen
- [ ] Weg Wohnwagen → Zelt → Wiesenbüro klar erkennbar
- [ ] Gäste-Weg Haupttor → Zelt frei (Wegpunkte in `game_manager.gd` WEG_REIN/WEG_RAUS)
- [ ] Zelt: 24 Tischplätze kollidieren nicht mit Lager, Computer, Bühne, Klo-Container
- [ ] Klo-Container: Ausrichtung/Tür sieht von innen gut aus
- [ ] Nachtbeleuchtung: keine dunklen Löcher
- [ ] Horizont-Kulisse hinter der Grenze (Bäume, Zäune, Stadtsilhouette)
- [ ] Deko draußen: Bierbänke vor dem Zelt, Mülleimer, Absperrgitter, Schilder
- [ ] Ruckelstellen suchen (zu viele Lichter/Bäume auf einem Fleck)

## 4. Ton *(Du — Details in `docs/AUDIO.md`)*

Heute: 1 Musikstück, sonst Piepstöne.

- [ ] ⚠️ 3–5 Zeltstücke (2–4 min, Blasmusik/Party), GEMA-frei, Lizenz für Videospiele
- [ ] ⚠️ 1 Menüstück
- [ ] ⚠️ `ambiente/kirmes.ogg` (Loop, Stimmengewirr)
- [ ] ⚠️ Ersatz für Piepstöne: pop, ding, glug, sizzle, scrub, splash, cheer, honk
- [ ] Neu: kasse, zapfen, prost, schritte, tuer, muenzen, fahrgeschaeft
- [ ] Wunsch: Menü-Klick, Gemurmel im Zelt, Regen, Feierabend-Glocke, Blaskapelle live

## 5. Grafik und Oberfläche

- [ ] ⚠️ *(Du)* Entscheidung UI-Stil (2. Entwurf: dunkles Holz, Messing) → *(Ich)* Umbau
- [ ] *(Du)* Symbole statt Emojis: Bier, Brezn, Hendl, Geld, Beliebtheit, Sauberkeit, Personal
- [ ] ⚠️ *(Du)* Logo/Schriftzug für Menü und Store
- [ ] ⚠️ *(Du)* Spiel-Icon (.ico) für die exe → *(Ich)* einbauen
- [ ] *(Du)* Ladebildschirm-Bilder

## 6. Steam und Recht *(Du)*

- [ ] ⚠️ Namensprüfung „Oktoberfest"/„Wiesn" (Marken der Stadt München) — Anwalt, ggf. neuer Name
- [ ] ⚠️ Steamworks-Konto, App-ID → *(Ich)* Test-ID 480 ersetzen
- [ ] ⚠️ Store-Seite (Texte: `docs/steam/store_seite.md`)
- [ ] ⚠️ Store-Grafiken: Kapseln in allen Größen, Hintergrund, Bibliotheksbilder
- [ ] ⚠️ Mindestens 5 Screenshots (F12) + Trailer 30–60 s
- [ ] 23 Errungenschaften mit Symbolen anlegen (`docs/steam/errungenschaften.md`)
- [ ] Auto-Cloud einrichten
- [ ] ⚠️ KI-Angabe (Meshy-Modelle, KI-Musik)
- [ ] ⚠️ Alterseinstufung (Alkohol-Thema)
- [ ] ⚠️ Lizenznachweise in `docs/lizenzen/`: Kirmes-Pack, Meshy, AIMusic, jede neue Datei
- [ ] Impressum + Datenschutzerklärung (Koop-Server verarbeitet IP-Adressen)
- [ ] Steuer- und Bankdaten bei Steam

## 7. Testen *(Du)*

- [ ] ⚠️ Eine komplette Saison (16 Tage) allein
- [ ] ⚠️ Eine Saison im Koop
- [ ] ⚠️ 3–5 Außenstehende spielen lassen — zuschauen, nicht erklären
- [ ] ⚠️ Steam-Test: 2 Konten, 2 Rechner — Einladen, Beitreten, Overlay, Errungenschaften
- [ ] Schwacher Rechner (Laptop mit integrierter Grafik), möglichst Steam Deck
- [ ] Türkisch gegenlesen lassen, ggf. weitere Sprachen

## 8. Code *(Ich)*

- [ ] UI-Umbau im Wiesn-Stil (nach Entscheidung 5.)
- [ ] Controller-Unterstützung (Steam Deck)
- [ ] Rückmeldung: fliegende Geldzahlen, kleine Effekte (Plan 2.4)
- [ ] Betrunkene Gäste als Spielelement (Plan 2.5)
- [ ] Koop-Zusammenspiel: Krüge übergeben, gemeinsame Ereignisse (Plan 5.2/5.4)
- [ ] Schnellerer erster Tag, kürzere Wartezeiten (Plan 1.1/1.2)
- [ ] Demo Tag 1–3 fürs Steam Next Fest
- [ ] Rangliste (nach App-ID)
- [ ] Neue Modelle, Figuren, Sounds einbauen, sobald geliefert
- [ ] Letzter Balancing-Lauf mit dem Bot nach allen Änderungen

## 9. Stand Story und Inhalt (v186)

Fertig:
- Einleitung: Brief von Onkel Sepp, Überblende, Wiesnchef mit Ja/Nein-Frage, Huber erwähnt
- Tutorial als Rundgang des Wiesnchefs (14 Schritte): Zelt übernehmen, Planen abziehen, fegen,
  Müllsäcke vor die Tür, Büro, Lager, Schlafen, Zapfen, Personal …
- Tagesziele, Sepps Bankschulden (nach Schwierigkeit), Rettungskredit mit Huber-Reaktion
- Huber: NPC mit drei Akten, Wetten ab Tag 3, Sabotage ab Tag 5 (Fass-Leck, Stinkbombe),
  wirbt Personal ab, Finale „Maß-Wettschleppen" um Sepps Ehre, Abschlussbrief
- Wiesn-Kalender (K) mit Sondertagen: Anstich, Trachtenumzug, Familientag, Italiener-Wochenende
- Wiesn-Kurier nach Feierabend
- Personal mit Namen, Müdigkeit, Lohnwünschen, Kündigung, Teamliste
- Theke wächst mit den Lizenzen, Standpersonal geht nachts heim, Fahrgeschäfte stehen still
- Leistung: Sichtweite für Kartenteile (scripts/sichtweite.gd)

Noch offen (Code):
- [x] Stammgäste mit Namen und Wünschen über mehrere Tage *(v188)*
- [ ] Koop: Chaos-Ereignisse für alle *(abendliche Auszeichnungen fertig, v187)*
- [x] Saboteur im Zelt erwischen (Huber-Konzept) *(v187)*
- [ ] Eigene Figur für Huber (braucht ein Modell) — bis dahin Bean, etwas größer
- [ ] Buden-Meshes zusammenfassen (Leistung, nach der Sichtweite der nächste große Schritt)
- [ ] Koop-Test aller neuen Systeme (Rundgang, Putzen, Duell, Personal)

Werkzeuge zum Prüfen: tools/test_tutorial, test_rundgang, test_tagesziel, test_huber,
test_duell, test_lieferwagen, test_zeitung, test_kalender, test_moebel, test_personal,
test_saboteur, test_stamm,
perf_messen, sim_saison.

## 10. Oberfläche: ein Stil für alles (v204)

Hauptmenü und Einstellungen geben den Ton an: dunkle Tafeln, runde Ecken, Gold nur
als Akzent (assets/ui/menue_theme.tres, gebaut von tools/theme_bauen.gd). Der Rest der
Oberfläche zieht jetzt nach:

- **Symbole statt Emoji.** In `assets/ui/symbole/` liegen ~39 gleich gezeichnete
  Strichgrafiken (24er Raster, Goldton, Strichstärke 1,7). `scripts/ui/symbole.gd` macht
  aus einem Namen ein Bild: `Symbole.bild("bier")`, `Symbole.setze(%Symbol, "geld")`,
  `Symbole.rechteck("kiste", 22)`. Emoji sahen auf jedem System anders aus und passten
  nie zum Theme.
- Aus `locale/texte.csv` sind alle Emoji raus. Wo das Emoji die Bedeutung trug
  (COMP_GOODS_STOCK, WORLD_STORAGE), stehen jetzt Wörter.
- Umgestellt: HUD (Geld, Uhr/Mond, Lager, offene Bestellungen), Wiesenbüro (Kopf,
  Reitersymbole, jede Angebotszeile), Zeltcomputer, Koop-Lobby und Lobby (Abteilungen als
  Knopfsymbol), Einrichtungskatalog, Ping-Marker (Sprite3D statt Label3D), Meilensteine.
- Fraktur nur noch dort, wo sie gehört: Logo, Zeitung, Kalender, Kino, Schilder in der
  Welt. Die Fenster im Spiel (Abstimmung, Lobby, Koop-Lobby, Schichtbeginn) nutzen die
  normale Schrift wie das Hauptmenü.
- Kalte Farbreste gewärmt: Kontrollkästchen, Schalterknopf, Reglerknopf, HUD-Hinweise.
- Die Dialogknöpfe nutzen nicht mehr das alte `theme.tres`.

Kontaktbogen aller Symbole: `Godot.exe --path . res://tools/symbol_blatt.tscn`
→ `user://symbole.png`. Einzelne Fenster ansehen:
`Godot.exe --path . res://tools/szene_schuss.tscn -- res://scenes/ui/<szene>.tscn <name>`

Bewusst nicht angefasst: Sprechblasen über den Gästen und Schilder in der Welt — dort
sind die bunten Emoji auf Entfernung besser lesbar als dünne Striche.

## 11. Updates: zwei Pakete statt eines (v205)

Bis v204 ging bei jedem Deploy ein einziges `game.pck` mit **815 MB** raus — hoch,
zur Kontrolle in Schritt 8 wieder runter, und dann zu jedem Spieler. Eine geänderte
Textzeile kostete 815 MB. Seit v205 sind es zwei Pakete:

| Paket | Inhalt | Größe | wie oft |
|---|---|---|---|
| `inhalt.pck` | voller Export (Modelle, Figuren, Musik, godotsteam) | ~860 MB | nur wenn sich `assets/models`, `assets/character`, `assets/music` oder `addons` ändern — in v183–v204 kein einziges Mal |
| `spiel.pck` | alles außer diesen drei Ordnern | ~61 MB | jeder Deploy |

`scripts/boot.gd` lädt beide, **inhalt zuerst, spiel zuletzt** — das zuletzt geladene
Paket gewinnt bei Dateien, die in beiden stecken. `version.json` führt drei Zahlen:

```json
{"version": 205, "spiel": 212, "inhalt": 205}
```

`spiel` und `inhalt` sind für aktuelle .exe. `version` bleibt für immer auf 205
eingefroren — alte .exe (Programm-Generation ≤ 3) kennen nur diesen Schlüssel und
`game.pck`. Beides bleibt unberührt auf dem Server liegen, damit sie nicht bei jedem
Deploy 815 MB ziehen; `scripts/menu_eingang.gd` zeigt ihnen den Hinweis zum
Neu-Herunterladen (Generation 4).

Ob `inhalt.pck` neu muss, entscheidet `deploy.sh` an den Blob-Hashes der großen Ordner
aus dem Git-Index (`git ls-files -s`), verglichen mit `inhalt.quelle` auf dem Server —
deterministisch, anders als der Export selbst.

**Nach Änderungen an der Aufteilung immer prüfen**, ob die Pakete zusammen noch ein
lauffähiges Spiel ergeben — das fängt kaputte `uid://`-Verweise und fehlende Modelle ab:

```
Godot.exe --headless --path . --export-pack "Windows Desktop" build/probe_inhalt.pck
  (mit exclude_filter="" — beide Probepakete brauchen tools/)
Godot.exe --headless --main-pack build/probe_inhalt.pck res://tools/paket_test.tscn -- <absoluter Pfad zu probe_spiel.pck>
```

Im normalen Deploy läuft das nicht mit, weil die Release-Pakete `tools/` nicht enthalten.

Einmaliger Übergang (v205): `bash tools/deploy.sh --altpaket --mit-zip` — frischt
`game.pck` ein letztes Mal auf und stellt die neue ZIP online. Danach nie wieder nötig.

## 12. Koop ohne Teamleiter (v211)

Die Abteilungen („Teamleiter") sind weg. Jeder Spieler darf alles im Wiesenbüro
buchen und Personal einstellen, niemand ist mehr für einen Bereich gesperrt.
Damit entfielen auch die kleinen Tempo-Boni (Zapfen, Kochen, Putzen, Tragen) —
alle arbeiten gleich schnell.

- Warteraum (`scenes/ui/koop_lobby.tscn`): neues Layout mit Kopfzeile
  (Titel, Code-Karte, Kopieren, Verlassen), Spielerliste links, Name und drei
  große Figurkarten rechts, Aktionsleiste unten. Nur noch Name und Figur zur Wahl.
- Lobby im Spiel (`scenes/ui/lobby.tscn`): Name und Namensfarbe als Karten,
  darunter wer schon dabei ist und die Kurzanleitung.
- Der Zelt-Computer öffnet die Lobby jetzt als „Name und Farbe ändern" (COMP_LOBBY).
- Die Menümusik läuft auch im Warteraum: `scripts/ui/menue_musik.gd` lädt das
  Stück, Hauptmenü und Warteraum haben je einen `%MenueMusik`-Knoten. Beim
  Szenenwechsel stirbt der Spieler der alten Szene — darum startet ihn jede
  Szene selbst.
- Vermittler (`tools/server/vermittler.py`): `abt` ist aus `/setzen` und der
  Raumansicht raus, `LOBBY_ERR_DEPT_TAKEN` gibt es nicht mehr. Server mit
  deployen, sonst schicken alte Räume noch das alte Feld (stört nicht, ist aber
  toter Ballast).
- Bilder: `godot --path . res://tools/render_koop_lobby.tscn --resolution 1280x720`
  und `res://tools/render_lobby.tscn`.

## 13. Abdeckplanen im Tutorial greifbar machen (v211)

Beim Schritt „Zelt putzen" stand am Regal immer „Regal bewegen" statt „Plane
abziehen". Zwei Ursachen, beide behoben:

- Gemessen wurde bis zum Mittelpunkt der Plane. Die Regalplane ist 9 m lang —
  an ihren Enden war der Mittelpunkt weiter weg als `Player.INTERACT_RANGE`
  (3 m), also fiel sie aus der Auswahl. `Mess.naechster_punkt()` liefert jetzt
  die nächstgelegene Stelle der Plane, `player.gd` misst dorthin.
- Das Möbel unter der Plane war weiter ansprechbar und hat wegen des besseren
  Winkels gewonnen. `Mess.deckt()` sagt, ob ein Punkt unter der Plane liegt;
  `player.gd` überspringt zugedeckte `Lager`, `Einrichtung` und `BeerTable`,
  solange die Plane liegt. Stationen (Fass, Herd, Computer) bleiben erreichbar.

Geprüft in `tools/test_phase1` unter „Abdeckplanen": Reichweite am Planenende,
Zudecken, und der Ernstfall — Spieler vor dem zugedeckten Regal bekommt
`HINT_PLANE`, nach dem Abziehen wieder das Regal.

Sichtprobe im laufenden Spiel: `godot --path . res://tools/render_plane.tscn
--resolution 1280x720` stellt den Spieler vor das zugedeckte Regal und legt
`tools/plane_regal.png` ab — dort muss „[E] halten: Plane abziehen" stehen.

## 14. Putzen: Wegweiser und Mülltonne (v211)

- **Wegweiser:** Liegt eine Plane oder ein Dreckhaufen länger als
  `Mess.MAHN_ZEIT` (30 s) herum, schwebt ein kleiner goldener Pfeil darüber.
  Immer nur über dem *nächstgelegenen* Stück (`Mess._ist_wegweiser`, Prüftakt
  0,4 s) — bei einem Pfeil je Haufen stand sonst ein Pfeilwald im Zelt.
  Bierlachen und Erbrochenes während der Schicht bekommen keinen.
- **Mülltonne** statt Pfosten mit Schild: `tools/bake_muelltonne.gd` backt
  Korpus und Deckel getrennt (`assets/dreck/muelltonne.tres`,
  `muelltonne_deckel.tres`). Beim Abgeben klappt der Deckel auf, der Sack fliegt
  im Bogen hinein (`Muellplatz.einwerfen`, vom Server per
  `_net_muell_geworfen` an alle). Der Füllstand steht im Deckelspalt: je Sack
  ein Stück weiter offen, höchstens drei Zipfel schauen heraus. Gestapelt wird
  nichts mehr — damit sind auch die verrutschten Stapel weg.
- **Zählfehler:** `net_muell_abgeben` nahm jede Meldung an. Gaben zwei Spieler
  gleichzeitig ab, lief der Zähler über die Zahl der gefegten Haufen hinaus.
  Jetzt bricht der Server ab, sobald `_muell_entsorgt >= _muell_erzeugt`.
- Die Tonne steht vorn rechts am Rand des Vorplatzes (x=6, z=17.5) — die Stelle
  ist mit einer Rastersuche über die Geometrie gewählt, nicht geschätzt.

Geprüft in `tools/test_phase1` („Wegweiser…", „Mülltonne") und als Sichtprobe
mit `tools/render_plane.tscn` (`plane_regal.png`, `dreck_pfeil.png`,
`muelltonne.png`).
