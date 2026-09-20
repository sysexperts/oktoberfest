extends SceneTree
## Erzeugt die UI-Klänge nach assets/audio/sfx/. Es gab keine Sounddateien, und
## ein Holz-"Tock" passt zum Wiesn-Thema besser als ein Piepser.
##
##   Godot.exe --headless --script tools/ui_klaenge_bauen.gd
##
## Klangmodell: zwei gedämpfte Sinusschwingungen (Grundton + Oberton) mit sehr
## kurzer Hüllkurve, dazu ein winziger Rauschanteil am Anfang für das Anschlag-
## geräusch. Das klingt nach angeschlagenem Holz statt nach Systemton.

const RATE := 44100
const ORDNER := "res://assets/audio/sfx"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ORDNER))
	# name, Grundton Hz, Oberton Hz, Dauer s, Lautstärke, Rauschanteil
	_tock("ui_hover", 780.0, 1560.0, 0.045, 0.16, 0.05)
	_tock("ui_klick", 520.0, 1180.0, 0.085, 0.38, 0.10)
	_tock("ui_wechsel", 660.0, 1320.0, 0.075, 0.30, 0.07)
	_tock("ui_zurueck", 340.0, 700.0, 0.100, 0.32, 0.09)
	_tock("ui_schalter", 900.0, 1400.0, 0.055, 0.26, 0.12)
	print("UI-Klänge erzeugt in %s" % ORDNER)
	quit()

func _tock(name: String, grund: float, ober: float, dauer: float, pegel: float, rauschen: float) -> void:
	var anzahl := int(RATE * dauer)
	var daten := PackedByteArray()
	daten.resize(anzahl * 2)
	var zufall := RandomNumberGenerator.new()
	zufall.seed = hash(name)
	for i in anzahl:
		var t := float(i) / RATE
		var fortschritt := float(i) / anzahl
		# Schneller Abfall — je höher der Anteil, desto kürzer klingt es nach
		var huelle := exp(-fortschritt * 9.0)
		# Ganz kurzes Einblenden, sonst knackst der Anfang
		huelle *= minf(1.0, float(i) / (RATE * 0.002))
		var wert := sin(TAU * grund * t) * 0.7 + sin(TAU * ober * t) * 0.3
		# Anschlaggeräusch nur in den ersten Millisekunden
		wert += zufall.randf_range(-1.0, 1.0) * rauschen * exp(-fortschritt * 60.0)
		var probe := int(clampf(wert * huelle * pegel, -1.0, 1.0) * 32767.0)
		daten.encode_s16(i * 2, probe)
	var klang := AudioStreamWAV.new()
	klang.format = AudioStreamWAV.FORMAT_16_BITS
	klang.mix_rate = RATE
	klang.stereo = false
	klang.data = daten
	klang.save_to_wav("%s/%s.wav" % [ORDNER, name])
