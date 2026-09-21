extends RefCounted
## Hauptmusik des Spiels (assets/music/Gamesound.*) für alle Menü-Szenen.
## Hauptmenü und Koop-Warteraum sind eigene Szenen — beim Wechsel stirbt der
## AudioStreamPlayer der alten Szene, darum startet ihn jede Szene selbst.
## Ohne Musikdatei bleibt es still.

## Reihenfolge wie früher in menu.gd: erst das Hauptstück, dann die Ersatzmusik.
const PFADE := ["res://assets/music/Gamesound%s", "res://assets/audio/musik/menue%s"]
const ENDUNGEN := [".ogg", ".wav", ".mp3"]

## Lädt das erste vorhandene Stück in den Spieler und startet es in Schleife.
static func starten(spieler: AudioStreamPlayer) -> void:
	if spieler == null or spieler.playing:
		return
	for pfad: String in PFADE:
		for endung: String in ENDUNGEN:
			var pfad_voll: String = pfad % endung
			if not ResourceLoader.exists(pfad_voll):
				continue
			spieler.stream = load(pfad_voll)
			# MP3 und OGG können selbst in Schleife laufen; sonst neu starten
			if spieler.stream is AudioStreamMP3:
				(spieler.stream as AudioStreamMP3).loop = true
			elif spieler.stream is AudioStreamOggVorbis:
				(spieler.stream as AudioStreamOggVorbis).loop = true
			elif not spieler.finished.is_connected(spieler.play):
				spieler.finished.connect(spieler.play)
			spieler.play()
			return
