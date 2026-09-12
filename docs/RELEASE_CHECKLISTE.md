# Release-Checkliste

Stand: 12.09.2026 (v130). ⚠️ = Pflicht vor der Veröffentlichung.
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
- [ ] Stehlampe (Einrichtung)
- [ ] Pfütze und Erbrochenes (Bodenflecken)
- [ ] Zeltteile in `scenes/tent.tscn` (12 Platzhalter-Meshes)

### Draußen
- [ ] ⚠️ Wohnwagen (eigener + Nachbarn)
- [ ] ⚠️ Lieferwagen
- [ ] Paket/Lieferkiste
- [ ] Wiesenbüro: Schreibtisch, Buchungskiosk, am besten kleines Bürogebäude
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
