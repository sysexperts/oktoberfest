# Leistung mitschreiben (für den Spieltest)

1. Im Spiel **F3** drücken: oben rechts erscheint die Leistungsanzeige, und das Spiel schreibt ab jetzt alle 5 Sekunden eine Zeile mit.
2. Ganz normal spielen, bis das Zelt voll ist (mindestens eine Runde, gern einen ganzen Tag).
3. Spiel beenden und die Datei schicken: `%APPDATA%\Godot\app_userdata\Sloptoberfest\leistung_log.csv`
   (Windows-Taste, `%APPDATA%\Godot\app_userdata\Sloptoberfest` eintippen, Enter).
4. Pro Rechner eine eigene Datei, den Namen des Rechners (Grafikkarte steht in der Datei) dazuschreiben.

Spalten: Spielzeit, Tag, Restzeit der Phase, FPS, längstes Bild (ms), Skripte, Physik, Render-CPU, GPU (alle ms),
Zeichenaufrufe, Objekte, Dreiecke, Knoten, Gäste, Dreck, Spieler, Grafikstufe, Auflösung, Grafikkarte.
Die Datei wächst an (neue Sitzungen hängen unten an); zum Neustart die Datei löschen.

## Rangliste: welches Skript kostet?
Bei eingeschalteter Anzeige (F3) im späten Spiel **F7** drücken. Das Spiel schaltet nacheinander die Skripte aus, misst die Skriptzeit
und schreibt `leistung_skripte.txt` in denselben Ordner wie `leistung_log.csv`. Dauert einige Minuten, nichts anfassen
(Anzeige: „Rangliste n/m“). Bitte die Datei auch schicken, am besten bei vollem Zelt.

## Zerlegung: wo bleibt die Zeit? (F8)
Bei eingeschalteter Anzeige (F3) im späten Spiel bei vollem Zelt **F8** drücken. Das Spiel misst rund eine Minute lang die Bildzeit und schaltet
nacheinander Teile ab (Lichter, Effekte, Bäume, Zelt, 3D komplett …); am Ende stehen die Werte als Liste im Bild und in `leistungstest.txt`
im selben Ordner wie `leistung_log.csv`. Bitte nichts anfassen, bis „Fertig“ steht, und die Datei schicken (oder einen Screenshot).
