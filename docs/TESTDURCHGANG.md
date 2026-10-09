# Testdurchgang vor dem Streamer-Samstag

Ablauf: Ich starte Punkt für Punkt das Spiel an der richtigen Stelle, Serdar schaut
und sagt **passt** (weiter) oder **Korrektur** (wir ändern, dann nochmal ansehen).
Danach Bot-Spieltest, Performance, Spacewar-Version.

Legende: [ ] offen · [x] passt · [~] korrigiert

## Teil 1 · Neu seit v400 (zuletzt umgesetzt)
- [x] 1 Start: Hauptmenü, Mauszeiger (Pfeil/Hand, v405), Ladebildschirm kommt durch (v409), Version unten
- [x] 2 Neues Spiel → Tutorial: Horst, Wohnwagen aussuchen (kostenlos, eigener Wagen, v399/400), Weg zurück zum Zelt
- [x] 3 Zelt jeden Morgen vorne am Eingang eröffnen, Horst erklärt es bei „Bediene“ (v402); keine Kirmes-Besucher am ersten Tag (v391)  ⚠ Teil geprüft: test_besucher_start OK (keine Besucher am ersten Tag); Vorführung gezeigt, wartet auf dein Passt
- [x] 4 Wohnwagen innen (Wände, Fenster, Küchenzeile, Bett, Spiegel, v398) und Schlafen: Mehrheit muss im Bett liegen (v401)  ✔ test_schlafen, test_wohnwagen, test_phase1 (Tür: alle 17 Wagen erreichbar) grün
- [x] 5 Festbüro und Computer: Desktop-Zeiger bleibt sichtbar (v404), Bestellung nur am Computer (v394/395)  ✔ test_buero_computer (neu, mit Fenster): Schreibtisch nicht ansprechbar, Computer ja, Zeiger bleibt sichtbar auch nach Klick ins Leere, Shop im Desktop
- [x] 6 Boden: Pfützen, Kotze, Dreck liegen auf dem Boden, nicht darin (v403); Müllsack werfen (v392/393)  ✔ Test grün: test_fleckabstand, test_muellwurf
- [x] 7 Mail-App: Quest-Angebot „Annehmen/Ablehnen“ beschriftet (v407), Quest-Angebote als Meldung (v406)  ✔ Test grün: test_story
- [x] 8 Kapitel 3 „Gewinn Konrads Wette“: Konrad ansprechen, Wette gilt automatisch, verlieren → Horst-Mail, am nächsten Tag neue Wette, gewinnen → nächste Quest (v407)  ✔ Test grün: test_wette (neu), test_kapitel3
- [x] 9 Konrads Zelt: volles Zelt, Kochtresen mit mehreren Portionen (auflegen, gar, verbrennt nach 20 s, Mülleimer), neue Grillmodelle (v406)  ✔ test_kochtresen (neu): 4 Plätze, gar nach 8 s, verbrannt nach 20 s, Mülleimer; Konrads Zelt braucht laut Serdar keine Funktion, nur Optik (Bilder gezeigt)
- [x] 10 Gefallen: Sau und Täter tragen wie Raufbold, Gehege auf freiem Platz; Sabotage lockt Konrads Gäste (v406)  ✔ Test grün: test_gefallen
- [x] 11 Aufheben-Töne leiser (v406)  ✔ im Code (scripts/sfx.gd): „pop“ spielt 8 dB leiser und höchstens alle 120 ms

## Teil 2 · Der Rest vom Plan (aus PLAN_STORY.md, Abschnitt in Klammern)
- [x] 12 Kernschicht: Krug füllen, zapfen, servieren, kassieren, Beschwerden, Klo-Warteschlange, Gäste in Gruppen und Wunschlieder (17)  ✔ Test grün: test_zapfsperre, test_krugstapel, test_gaeste
- [ ] 13 Tagesablauf: Tagesziel, Bankrate, Bilanz, Bierpreis, Kalender, Wetter und Amt, Festkurier/Zeitung, Social Media (2, 29.3)  ⚠ test_tagesziel veraltet (feste Bankrate entfällt), Kalender/Zeitung ohne Urteil → im Fenster ansehen
- [x] 14 Kapitel 1: Eröffnung mit Logo und Kamerafahrt, Brief als Zeitungsblatt, Tutorial bis Feierabend (9)  ✔ Test grün: test_tutorial, test_story
- [x] 15 Kapitel 2: Hauptquests, Sepps Schulden in der Bank-App, Nebenquests mit Frist, Krankmeldung, Konrads Angebot, Horsts Erinnerung 1 (10)  ✔ Test grün: test_kapitel2
- [x] 16 Personal und Stammgäste: Einstellen, Lohn, Akademie, Bräumeister Gerhard, Security als Personal (29.4, 10)  ✔ Test grün: test_personal, test_braeumeister, test_stamm, test_abwerben
- [x] 17 Horsts Gefallen auf der Kirmes: Spanner, Taschendieb, Sau, Spion, Brand, Sturm, Falschgeld, Krüge, Reporter, Hochzeit, Wettessen, Fahnen, Laternen, Ballons, Wasserrohrbruch, Notenständer; vier Security-Posten (18.1)  ✔ Test grün: test_gefallen
- [x] 18 Kapitel 3: Wette, Stinkbombe-Quest, Saboteur fangen, Hinterzimmer, Strafe bei liegenden Quests, Horsts Erinnerung 2 (11)  ✔ Test grün: test_kapitel3
- [x] 19 Konrads Streiche und Gegenmaßnahmen: Abwerben, Fake-Bewertungen, Hygienekontrolle (Frau Wagner), Laster, Stromausfall, Diebe (11, 22.1)  ✔ Test grün: test_streiche, test_kontrolle, test_fakes, test_abwerben
- [x] 20 Deine Sabotage: Händler Gustav, Werkzeuge, Tarnung, Ablauf in Konrads Zelt, Begrenzung, Konrads Kameras und Schloss (22.2, 23)  ✔ Test grün: test_sabotage, test_gustav, test_saboteur
- [ ] 21 Konrads Zelt und Casino: Layout, Tanzfläche, Personal, Casino (Roulette, Blackjack, Watten, Würfel, Automaten), Pflichtquest (24, 25, 28)  ⚠ Blackjack und Watten OK, Würfel OK; Spielautomat: „Walzen laufen aus“ schlägt fehl → prüfen
- [x] 22 Kapitel 4: Schlüssel, Braukeller, Rezepttafel/Rezeptbuch, Qualitätsstufen, eigenes Bier, Hopfenblockade, Horsts Erinnerung 3 (12)  ✔ Test grün: test_kapitel4, test_braeumeister
- [x] 23 Kapitel 5: Quests, Duell-Turnier (wiederholbar), großes Fest mit Feuerwerk, Konrads Auftritt, Abschlussbrief, Horsts Erinnerung 4 (13)  ✔ Test grün: test_kapitel5 (Duell, Fest, Abschlussbrief)
- [ ] 24 Kirmes: Minispiele, sieben Rekord-Quests, Lieferung, Mails der Budenbesitzer (14, 29.1)  ⚠ test_kirmesquests OK, Minispiele laufen (Trefferquote 59/819), Spielgefühl noch ansehen
- [x] 25 Zwischenfälle (Heiratsantrag, Karaoke, Flirt, Bierunfall) und Happy Hour  ✔ Test grün: test_zwischenfaelle, test_happyhour
- [x] 26 Endgame: Fest-App, Festtag (Motto, Band, Feuerwerk, Fassanstich, Katastrophen), Festruhm, Meister-Liste, Meilensteine (19, 20, 21, 29.2)  ✔ Test grün: test_fest, test_meister, test_meilensteine
- [x] 27 Ausbau und Wohnwagen: Ausbau-App (Biergarten, VIP, Bühne, Bierhandel, Konrads Zelt aufkaufen, Buden, Filiale), Wagen-App (Farbe, Einrichtung, goldener Krug), Spiegel (20)  ✔ Test grün: test_ausbau, test_wohnwagen
- [ ] 28 Hinweise im Moment (Hilfetexte zur richtigen Zeit), Brabbelton im Dialog (17, 15)
- [ ] 29 Koop: zwei Spieler (Spacewar-Lobby), Abstimmungen, Teamleiter, Drop-in  ⚠ test_netz: Spieler erscheint nicht in 60 s (vermutlich zu knappe Wartezeit), alte Server-Tests veraltet → mit Steam/Spacewar prüfen
- [ ] 30 Einstellungen, Sprachen (DE/EN/TR), Controller (offen: Maulwurf mit Stick, Servieren/Putzen am Pad)  ⚠ test_pad und test_pad_menue OK; test_pad_neu (3 Fehler) und test_pad_spiel nur mit Fenster → prüfen
- Entfällt laut Plan, nicht testen: Saison/Finale, Skilltree, Hütchenspiel/Armdrücken/Tombola, Schnapsleichen/Hund/Pferde

## Teil 3 · Danach
- [ ] 31 Animationen mit Q: Emote-Rad (halten, wählen, loslassen) — alle Emotes (Tanzen, Jubel, Sitzen, Posen, Kotzen, Prost) durchgehen, Animationen anpassen wo es falsch aussieht (docs/ANIMATIONEN_CHECKLISTE.md); Hinweis nach dem ersten bedienten Gast und Ladetipp prüfen  ⚠ test_clipping/test_animationen: 3 von 43 Animationen mit Durchstoß → welche, dann anpassen
- [ ] 32 Performance: Spiel fühlt sich nicht mehr flüssig an → messen (tools/perf_messen, scripts/sichtweite.gd), Ursachen suchen, beheben
- [ ] 33 Bot-Spieltest (tools/test_alle.sh, sim_saison, test_koop_bots) und Auswertung
- [ ] 34 Spacewar-Version für die Streamerin bauen (App-ID 480, ZIP), mit Anleitung (Steam muss laufen, Koop nur mit Spacewar-Freunden)
- [ ] 35 Letzter Start der ZIP-Version auf sauberem Ordner prüfen

## Ergebnis Testlauf (2026-10-09, alle 75 Tests headless)
OK: 33 · Befunde: 19 (siehe unten) · davon veraltet/ohne Fenster/ohne Urteil: 14
Neu geschrieben: tools/test_wette.gd (Quest 3.1, OK).
**Echte offene Punkte:** Animationen mit Durchstoß (3 von 43) · Kollision vor der Wohnwagentür · Spielautomat-Walzen · test_pad_neu · Koop-Test mit zwei Instanzen · Performance.
**Veraltete Tests (Spiel unverändert in Ordnung):** test_duell (altes Finale), test_tagesziel (feste Bankrate), test_wagen (alte Wagen-API), test_spielerfigur (Figurenpfad), test_huber (Wette erst ab Kapitel 3), test_code_beitritt/test_live_beitritt/test_koop_bot (alter Server).
**Brauchen Fenster, nicht headless:** test_fussspuren, test_meldungen, test_putzziele, test_passend, test_spielerliste, test_moebel, test_zeitung, test_rundgang, test_pad_spiel, test_creator_menue.

## Stand 2026-10-09 (Streamer morgen)
Erledigt seit dem Testlauf: Quest-Wette, Wohnwagen-Text, Horst startet am Büro, Konrads Zelt nur bei offenem Zelt, Q-Hinweis,
Leistung (Zelt 13.200 → 2.100 Aufrufe, Tor 15.200 → 10.600, FPS 20 → ca. 40), Animations-Stufe für alle Figuren,
Besucher 24/48/80 mit Heimgehen nach 22 Uhr, NPC-Kleidung (Verkäufer) behoben, F3/F4-Leistungsanzeige.
Offen für morgen: Bot-Saison (läuft), Konrads Zelt/Casino ansehen, Emotes (Q), Spacewar-ZIP (zuletzt), Buden-Leistung weiter.
