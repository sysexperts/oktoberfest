# Animationen-Checkliste (alle Charaktere, Männer und Frauen)

Stand 2026-10-05. Alle Figuren des Creators teilen den Standardkörper und das Skelett (`scenes/figuren/basis.tscn`),
Animationen laufen also für beide Geschlechter. Frauen mit Dirndl zusätzlich gegen den Rock prüfen (Beine, Sitzen, Tanzen).

Legende: ✅ vorhanden (Clip, Mixamo-Clips heißen `mixamo/<Name>`) · 🔧 teilweise / prozedural (per Skript) · 🔴 in Paket 1 und 2 nicht dabei (bewusst weggelassen oder noch nicht besorgt) · ⬜ Paket 3 bis 5, noch nicht dran · ❓ im Spiel prüfen, ob schon gelöst

Die Zuordnung stammt aus einer Durchsicht von `scripts/figur.gd`, `scenes/figuren/basis.tscn` und `scripts/pruegel/`; wo ich
nicht sicher bin, steht ❓.

## 1. Grundbewegung
- ✅ Stehen (Idle_12)
- ✅ Idle-Varianten (Gewicht verlagern, umschauen, Arme verschränken, Gähnen) — damit Gäste nicht synchron wirken — **Dwarf_Idle, Idle, drunk_idle_variation**
- ✅ Gehen (Walking)
- ✅ Rennen (Running)
- ✅ Betrunken torkeln (Unsteady_Walk)
- ✅ Stark betrunken: Schwanken im Stehen, Wanken beim Anhalten — **drunk_idle, drunk_walk, drunk_run_forward**
- ✅ Rückwärts gehen, Seitschritte (Strafe) — **Walking_Backwards, drunk_walk_backwards (Seitschritte 🔴)**
- ✅ Drehen auf der Stelle (links/rechts) — **drunk_walking_turn (nur betrunken; normales Drehen 🔴, drunk_turn entfernt)**
- 🔴 Anlaufen / Abbremsen (Übergang Stehen ↔ Gehen ↔ Rennen)
- ✅ Treppen steigen (Emporen, `TREPPE`) — oder Gehen mit Anhebung (❓) — **Walking_Up_The_Stairs**
- ✅ Springen / Hüpfen (Absprung, Luft, Landung) — **Running_Jump (Sprung aus dem Rennen, ein Clip)**
- 🔴 Ducken, Hocken (z. B. unter Dingen durch, aufheben)

## 2. Sitzen
- ✅ Sitzen mit Trinken (Sit_and_Drink; Sitting_Drinking entfernt, drehte die Figur zur Seite)
- ✅ Sitzend ärgern — **Sitting_Angry**
- ✅ Sitzend grölen / rufen — **Sitting_Yell**
- ✅ Sitzend mitklatschen — **Sitting_Clap**
- ✅ Sitzend jubeln — **Cheering_While_Sitting**
- ✅ Sitzend ausweichen (Prügelei in der Nähe) — **Sitting_Dodges**
- 🔴 Hinsetzen (Übergang Stehen → Sitzen)
- 🔴 Aufstehen
- 🔴 Sitzen im Leerlauf (zuhören, wippen, Kopf auf die Hand)
- 🔴 Sitzen mit Essen (Hendl, Brezn)
- 🔴 Sitzen betrunken (Schwanken, Kopf nach vorn, Einschlafen)
- 🔴 Schunkeln im Sitzen (Arme einhaken)
- 🔴 Auf dem Tisch stehen und tanzen (Bank → Tisch)
- 🔧 Frauen: Rock beim Sitzen prüfen (die Beine ziehen den Saum in der Pose mit)

## 3. Bier und Essen
- 🔴 Maßkrug nehmen (Hand zum Krug)
- ✅ Trinken im Stehen (Krug heben, schlucken, absetzen) — **Drinking**
- 🔴 Zuprosten / Anstoßen (zwei Figuren)
- 🔴 Ex trinken (Krug ganz hoch, Kopf in den Nacken)
- 🔴 Bier verschütten / Krug fallen lassen
- 🔴 Krug leer anschauen, Krug auf den Tisch stellen
- 🔴 Hendl essen / abbeißen
- 🔴 Brezn essen
- 🔴 Mehrere Krüge tragen (Kellner: bis zu 10 in zwei Händen, Haltung stabil auch beim Laufen)
- 🔴 Krug abstellen / austeilen am Tisch
- 🔴 Rülpsen, Bauch halten

## 4. Arbeit im Zelt
- ⬜ Zapfen am Fass (Hahn aufdrehen, Krug füllen, Schaum abstreichen)
- ⬜ Fass rollen / tragen / anstechen
- ⬜ Tablett / Krüge tragen (siehe oben), Servieren
- ⬜ Kochen / Braten am Grill (Hendl wenden)
- ⬜ Bestellung aufnehmen (Notizblock)
- ⬜ Kassieren / Geld zählen / Wechselgeld geben
- ⬜ Putzen: Wischen, Besen, Eimer tragen (Putzschritt mit Dreck)
- ⬜ Aufräumen / Scherben aufheben (Bücken, Aufheben)
- ⬜ Tür auf- und zumachen
- ⬜ Dekorieren (Girlande aufhängen, Leiter steigen)
- ⬜ Bürotätigkeit (Tippen, Telefonieren, Papier lesen)
- ⬜ Zeitung lesen
- ⬜ Hände waschen, Klo benutzen (Warteschlange stehen, eintreten)

## 5. Tanzen, Feiern, Emotes
- ✅ Hip Hop Tanz (Hip_Hop_Dance, Hip_Hop_Dancing)
- ✅ Alberner Tanz — **Silly_Dancing**
- ✅ Breakdance — **breakdance_footwork_1, breakdance_footwork_2, breakdance_ready_3, breakdance_uprock, breakdance_uprock_var_1** (ready_3 auch als Tanz für NPCs vor der Bühne; der Rest war fehlerhaft und ist entfernt)
- ✅ Flair — **flair_2** (nur Männer, wegen des Rocks)
- ✅ Stehend ärgern — **Angry**
- ✅ YMCA (ymca_dance)
- ⬜ Schunkeln im Stehen (Arme einhaken, wiegen)
- ⬜ Polonaise / im Kreis tanzen
- ⬜ Auf der Bank mittanzen / Bierbank-Tanz
- ⬜ Paartanz / Schuhplattler (Klatschen auf Schenkel und Schuhsohle)
- ⬜ Mitklatschen, Mitsingen, Mitgrölen (Mund auf und zu)
- ⬜ Jubeln, Arme hoch, Fäuste ballen
- ⬜ Winken (Hallo, Tschüss)
- ⬜ Zeigen (Richtung, auf etwas)
- ⬜ Nicken / Kopfschütteln / Schulterzucken
- ⬜ Verbeugen / Hut ziehen
- ⬜ Daumen hoch / runter
- ⬜ Lachen (Bauch halten), Weinen, Ärgern (Fuß aufstampfen)
- ✅ Kopf kratzen (Confused_Scratch) — Extra beim Warten
- ⬜ Weitere Wartegesten: Uhr schauen, Hände in die Hüften, Fußwippen

## 6. Rausch, Übelkeit, Schlaf
- 🔧 Kotzen: Effekt vorhanden (`kotzt`), Körperanimation (Vorbeugen, Würgen, Aufrichten) ❓
- ⬜ Taumeln / hinfallen beim Betrunkensein
- ⬜ Liegen / Umkippen auf der Bank
- ⬜ Einschlafen im Sitzen / im Stehen (Wippen, Aufschrecken)
- ⬜ Schlafen im Liegen (Wohnwagen, Bett)
- ⬜ Aufwachen, Strecken

## 7. Schlägerei und K.o. (`scripts/pruegel/`)
- 🔧 Kampfhaltung und Armbewegung: prozedural in `kampf_pose.gd` (Haltung, Stoß, Zappeln) ❓ Qualität prüfen
- 🔴 Schlag rechts / links (mit Ausholen und Treffer)
- 🔴 Tritt
- 🔴 Packen / Würgegriff / Kopfnuss
- 🔴 Treffer bekommen (Kopf zurück, Zurückweichen) — bisher Kopfruck und Staub per Skript (`raufbold.gd`)
- 🔴 Blocken / Ausweichen / Wegducken
- 🔴 Geschleudert werden: durch die Luft fliegen (Arme rudern, Körper dreht sich)
- 🔴 Aufprall und Liegenbleiben (Landen, Rollen, Liegen)
- 🔴 K.o. gehen: Taumeln und Zusammensacken
- 🔴 K.o. liegen (Idle im Liegen, Atmen)
- 🔴 Aufstehen nach Treffer (benommen, Kopf schütteln)
- 🔴 Wegtragen / am Kragen hinausziehen (Sicherheitsdienst: Packen, Tragen, Schleifen)
- 🔴 Rauswerfen (Schwung, Wurf)
- 🔴 Knäuel in der Massenschlägerei (viele Figuren, wiederholte Schläge, Variation)
- 🔴 Zuschauen / Anfeuern am Rand

## 8. Interaktion mit Dingen
- ⬜ Aufheben (vom Boden / vom Tisch)
- ⬜ Tragen: Fass, Kiste, Sack, Tablett (Haltungen je Objekt) ❓ vorhandene Haltungen prüfen
- ⬜ Werfen (Ausholen, Loslassen)
- ⬜ Fangen
- ⬜ Schieben / Ziehen (Wagen, Tisch)
- ⬜ Anlehnen, Auf die Theke stützen
- ⬜ Schalter / Hebel / Knopf drücken
- ⬜ Telefon / Handy

## 9. Kirmes und Minispiele
- ⬜ Schießbude: Anlegen, Zielen, Abdrücken, Rückstoß
- ⬜ Hau den Lukas: Hammer heben, Schlag, Zusehen
- ⬜ Dosenwerfen / Ringwerfen: Wurfbewegung
- ⬜ Karussell / Fahrgeschäft: Sitzen, Festhalten, Hände hoch, Schreien
- ⬜ Riesenrad: Einsteigen, Sitzen
- ⬜ Gewinnen / Verlieren: Jubeln, Enttäuscht, Preis halten
- ⬜ Wettschleppen (Krüge schleppen, Anstrengung, Zusammenbrechen)
- ⬜ Steh-/Treppen-Laufen mit Last

## 10. Personal, Stammgäste, Besondere Figuren
- ⬜ Festleiter: Rundgang, Zeigen, Begrüßen, Rede halten
- ⬜ Kapelle / Musiker (Blasinstrument, Trommel, Dirigent) — sofern im Spiel
- ⬜ Künstler / Bühne (`artist.gd`): Singen, Posieren, Verbeugen
- ⬜ Wiesn-Kurier: Zeitung austeilen / zustellen
- ⬜ Huber-Finale: Cutscene-Gesten (Reden, Wutausbruch, Abgang) ❓
- ⬜ Kino (Fraktur-Schilder / Leinwand): Zuschauen, Popcorn

## 10b. Mixamo-Clips im Spiel (Stand 2026-10-05)
Rund 30 Clips aus `assets/animationen_mixamo/` sind auf den Standardkörper umgerechnet (`assets/character/standard/mixamo_animationen.res`) und hängen
in `scenes/figuren/basis.tscn` als Bibliothek `mixamo`. Abspielen: `figur.abspielen("mixamo/Sitting_Drinking")` (Männer und Frauen gleich).
Neu umrechnen nach neuen Dateien: `godot --headless --path . --script res://tools/bake_animationen.gd -- mixamo`.
Kontaktbogen zum Ansehen: `godot --path . res://tools/mixamo_blatt.tscn --resolution 2000x700 -- 0.4 Idle Walking Drinking`.
Beim Umrechnen werden Hände und Ellbogen aus Rumpf und Kopf herausgedreht und die Kopfneigung begrenzt (`tools/bake_animationen.gd`, `_korrigieren`). `NUR_MAENNER` in `scripts/figur.gd` listet Clips, die Frauen nicht bekommen.
Im Spiel eingehängt (scenes/figuren/basis.tscn, scripts/figur.gd): sitzende Gäste wechseln ab und zu zu Cheering_While_Sitting und Sitting_Angry
(Sitting_Clap und Sitting_Yell sind vorerst draußen: in einzelnen Bildern steckt die Hand im Oberschenkel), stehende Figuren haben mit 45 % Dwarf_Idle
oder Idle, Betrunkene stehen mit drunk_idle und gehen mit drunk_walk, getanzt wird auch Silly_Dancing und Hip_Hop_Dancing, vor der Bühne am Boden
breakdance_ready_3, uprock, uprock_var_1. Nicht eingehängt: Treppen, Rückwärtsgehen, Sprung, flair_2, breakdance_footwork_1/_2 (Hand steckt in einzelnen Bildern im Bein).
Noch nicht im Spiel eingehängt: Die Clips sind abspielbar, aber noch keiner Spielsituation zugeordnet (Sitzen, Trinken, Torkeln usw. laufen weiter mit den alten Clips).

## 11. Technik und Qualität
- ⬜ Alle Clips beim Rock (Dirndl lang/kurz) auf Durchstöße prüfen: `tools/test_clipping.tscn` um neue Animationen erweitern (`POSEN` in `tools/test_clipping.gd`)
- ⬜ Neue Animationen in die Animationsbibliothek (`geliehen/…`) aufnehmen und die Namen in `scenes/figuren/basis.tscn` zuordnen
- ⬜ Übergänge (Blending) zwischen den Clips (aktuell harte Wechsel ❓)
- ⬜ Mischen von Ober- und Unterkörper (z. B. Gehen + Krug halten + Prosten) — Ebenen im Animationsbaum
- ⬜ Animation-Tempo und Fußaufsetzen an Gehgeschwindigkeit anpassen (kein Rutschen)
- ⬜ Zufällige Startphase pro Gast, damit Menschenmengen nicht synchron laufen
- ⬜ Leistung: viele Figuren gleichzeitig (Animations-LOD in der Ferne, siehe `scripts/sichtweite.gd`)
- ⬜ Netzwerk: Zustand der Animation synchron übertragen (Koop), kein Ruckeln bei Sitzen / Tanzen / K.o.
- ⬜ Sitzhöhe und Bankposition für Frauen (Rock) wie für Männer prüfen
- ⬜ Quelle und Lizenz jeder neuen Animation festhalten (aktuell „geliehen“, siehe `scripts/figur.gd`, `leih_animationen`)

## Empfohlene Reihenfolge
1. Sitzen komplett (Hinsetzen, Aufstehen, Leerlauf), Trinken im Stehen, Tragen von Krügen — das sieht jeder Spieler ständig.
2. Prügelei: Schlag, Treffer, Fliegen, Aufprall, K.o., Wegtragen — der Kern der Wiesn-Stimmung und bester Trailer-Stoff.
3. Arbeit: Zapfen, Servieren, Putzen.
4. Emotes und Idle-Varianten.
5. Kirmes-Minispiele.
