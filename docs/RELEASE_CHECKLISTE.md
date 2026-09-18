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
