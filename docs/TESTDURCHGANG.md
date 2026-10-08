# Testdurchgang vor dem Streamer-Samstag

Ablauf: Ich starte Punkt für Punkt das Spiel an der richtigen Stelle, Serdar schaut
und sagt **passt** (weiter) oder **Korrektur** (wir ändern, dann nochmal ansehen).
Danach Bot-Spieltest, Performance, Spacewar-Version.

Legende: [ ] offen · [x] passt · [~] korrigiert

## Teil 1 · Neu seit v400 (zuletzt umgesetzt)
- [ ] 1 Start: Hauptmenü, Mauszeiger (Pfeil/Hand, v405), Ladebildschirm kommt durch (v409), Version unten
- [ ] 2 Neues Spiel → Tutorial: Horst, Wohnwagen aussuchen (kostenlos, eigener Wagen, v399/400), Weg zurück zum Zelt
- [ ] 3 Zelt jeden Morgen vorne am Eingang eröffnen, Horst erklärt es bei „Bediene“ (v402); keine Kirmes-Besucher am ersten Tag (v391)
- [ ] 4 Wohnwagen innen (Wände, Fenster, Küchenzeile, Bett, Spiegel, v398) und Schlafen: Mehrheit muss im Bett liegen (v401)
- [ ] 5 Festbüro und Computer: Desktop-Zeiger bleibt sichtbar (v404), Bestellung nur am Computer (v394/395)
- [ ] 6 Boden: Pfützen, Kotze, Dreck liegen auf dem Boden, nicht darin (v403); Müllsack werfen (v392/393)
- [ ] 7 Mail-App: Quest-Angebot „Annehmen/Ablehnen“ beschriftet (v407), Quest-Angebote als Meldung (v406)
- [ ] 8 Kapitel 3 „Gewinn Konrads Wette“: Konrad ansprechen, Wette gilt automatisch, verlieren → Horst-Mail, am nächsten Tag neue Wette, gewinnen → nächste Quest (v407)
- [ ] 9 Konrads Zelt: volles Zelt, Kochtresen mit mehreren Portionen (auflegen, gar, verbrennt nach 20 s, Mülleimer), neue Grillmodelle (v406)
- [ ] 10 Gefallen: Sau und Täter tragen wie Raufbold, Gehege auf freiem Platz; Sabotage lockt Konrads Gäste (v406)
- [ ] 11 Aufheben-Töne leiser (v406)

## Teil 2 · Der Rest vom Plan (aus PLAN_STORY.md, Abschnitt in Klammern)
- [ ] 12 Kernschicht: Krug füllen, zapfen, servieren, kassieren, Beschwerden, Klo-Warteschlange, Gäste in Gruppen und Wunschlieder (17)
- [ ] 13 Tagesablauf: Tagesziel, Bankrate, Bilanz, Bierpreis, Kalender, Wetter und Amt, Festkurier/Zeitung, Social Media (2, 29.3)
- [ ] 14 Kapitel 1: Eröffnung mit Logo und Kamerafahrt, Brief als Zeitungsblatt, Tutorial bis Feierabend (9)
- [ ] 15 Kapitel 2: Hauptquests, Sepps Schulden in der Bank-App, Nebenquests mit Frist, Krankmeldung, Konrads Angebot, Horsts Erinnerung 1 (10)
- [ ] 16 Personal und Stammgäste: Einstellen, Lohn, Akademie, Bräumeister Gerhard, Security als Personal (29.4, 10)
- [ ] 17 Horsts Gefallen auf der Kirmes: Spanner, Taschendieb, Sau, Spion, Brand, Sturm, Falschgeld, Krüge, Reporter, Hochzeit, Wettessen, Fahnen, Laternen, Ballons, Wasserrohrbruch, Notenständer; vier Security-Posten (18.1)
- [ ] 18 Kapitel 3: Wette, Stinkbombe-Quest, Saboteur fangen, Hinterzimmer, Strafe bei liegenden Quests, Horsts Erinnerung 2 (11)
- [ ] 19 Konrads Streiche und Gegenmaßnahmen: Abwerben, Fake-Bewertungen, Hygienekontrolle (Frau Wagner), Laster, Stromausfall, Diebe (11, 22.1)
- [ ] 20 Deine Sabotage: Händler Gustav, Werkzeuge, Tarnung, Ablauf in Konrads Zelt, Begrenzung, Konrads Kameras und Schloss (22.2, 23)
- [ ] 21 Konrads Zelt und Casino: Layout, Tanzfläche, Personal, Casino (Roulette, Blackjack, Watten, Würfel, Automaten), Pflichtquest (24, 25, 28)
- [ ] 22 Kapitel 4: Schlüssel, Braukeller, Rezepttafel/Rezeptbuch, Qualitätsstufen, eigenes Bier, Hopfenblockade, Horsts Erinnerung 3 (12)
- [ ] 23 Kapitel 5: Quests, Duell-Turnier (wiederholbar), großes Fest mit Feuerwerk, Konrads Auftritt, Abschlussbrief, Horsts Erinnerung 4 (13)
- [ ] 24 Kirmes: Minispiele, sieben Rekord-Quests, Lieferung, Mails der Budenbesitzer (14, 29.1)
- [ ] 25 Zwischenfälle (Heiratsantrag, Karaoke, Flirt, Bierunfall) und Happy Hour
- [ ] 26 Endgame: Fest-App, Festtag (Motto, Band, Feuerwerk, Fassanstich, Katastrophen), Festruhm, Meister-Liste, Meilensteine (19, 20, 21, 29.2)
- [ ] 27 Ausbau und Wohnwagen: Ausbau-App (Biergarten, VIP, Bühne, Bierhandel, Konrads Zelt aufkaufen, Buden, Filiale), Wagen-App (Farbe, Einrichtung, goldener Krug), Spiegel (20)
- [ ] 28 Hinweise im Moment (Hilfetexte zur richtigen Zeit), Brabbelton im Dialog (17, 15)
- [ ] 29 Koop: zwei Spieler (Spacewar-Lobby), Abstimmungen, Teamleiter, Drop-in
- [ ] 30 Einstellungen, Sprachen (DE/EN/TR), Controller (offen: Maulwurf mit Stick, Servieren/Putzen am Pad)
- Entfällt laut Plan, nicht testen: Saison/Finale, Skilltree, Hütchenspiel/Armdrücken/Tombola, Schnapsleichen/Hund/Pferde

## Teil 3 · Danach
- [ ] 31 Animationen mit Q: Emote-Rad (halten, wählen, loslassen) — alle Emotes (Tanzen, Jubel, Sitzen, Posen, Kotzen, Prost) durchgehen, Animationen anpassen wo es falsch aussieht (docs/ANIMATIONEN_CHECKLISTE.md); Hinweis nach dem ersten bedienten Gast und Ladetipp prüfen
- [ ] 32 Performance: Spiel fühlt sich nicht mehr flüssig an → messen (tools/perf_messen, scripts/sichtweite.gd), Ursachen suchen, beheben
- [ ] 33 Bot-Spieltest (tools/test_alle.sh, sim_saison, test_koop_bots) und Auswertung
- [ ] 34 Spacewar-Version für die Streamerin bauen (App-ID 480, ZIP), mit Anleitung (Steam muss laufen, Koop nur mit Spacewar-Freunden)
- [ ] 35 Letzter Start der ZIP-Version auf sauberem Ordner prüfen
