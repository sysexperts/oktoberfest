extends SceneTree
## Backt umgefärbte Kleidungs-Texturen für Figur-Varianten. Die Kleidung wird
## über ihren Farbton erkannt (Haut, Haare, Hemd, Knöpfe haben andere Farbtöne
## oder sind fast farblos) und in die neue Farbe gebracht — Helligkeit und
## Stoffstruktur bleiben erhalten. Die Varianten setzen die Textur per
## Figur.textur (scenes/figuren/*.tscn).
## Aufruf: godot --headless --path . --script res://tools/bake_kleidung.gd
##         (mit "-- histogramm" nur Farbtöne der Quellen ausgeben)

const C2 := "res://assets/character/character2/character2_texture_0.png"
const ALEX := "res://assets/character/character4/alex_Walking_withSkin_texture_0.png"
## Lisa (Dirndl): die Farbtextur steckt als Bild 0 neben dem glb (4096², wird für die Varianten halbiert)
const C3 := "res://assets/character/character3/character3_Image_0.jpg"

## Regel: Farbton-Mitte (Grad), halbe Breite (Grad), Mindestsättigung,
## Höchsthelligkeit, Zielfarbe. Die Zielfarbe gilt für die mittlere Helligkeit
## des Stoffs (bezug), dunklere/hellere Stellen werden entsprechend skaliert.
const VARIANTEN := {
	"res://assets/character/character2/varianten/schwarz.png": [C2, [
		{"ton": 50.0, "breite": 16.0, "saett": 0.15, "hell_max": 0.52, "bezug": 0.38, "farbe": Color(0.085, 0.08, 0.08)},
	]],
	# Konrad, der Rivale: dunkles Weinrot wie sein Zelt
	"res://assets/character/character2/varianten/konrad.png": [C2, [
		{"ton": 50.0, "breite": 16.0, "saett": 0.15, "hell_max": 0.52, "bezug": 0.38, "farbe": Color(0.3, 0.035, 0.055)},
	]],
	"res://assets/character/character4/varianten/rot_braun.png": [ALEX, [
		{"ton": 206.0, "breite": 22.0, "saett": 0.12, "hell_max": 0.62, "bezug": 0.37, "farbe": Color(0.55, 0.1, 0.1)},
		{"ton": 92.0, "breite": 26.0, "saett": 0.15, "hell_max": 0.5, "bezug": 0.24, "farbe": Color(0.3, 0.19, 0.1)},
	]],
	"res://assets/character/character4/varianten/gruen_schwarz.png": [ALEX, [
		{"ton": 206.0, "breite": 22.0, "saett": 0.12, "hell_max": 0.62, "bezug": 0.37, "farbe": Color(0.18, 0.33, 0.2)},
		{"ton": 92.0, "breite": 26.0, "saett": 0.15, "hell_max": 0.5, "bezug": 0.24, "farbe": Color(0.09, 0.08, 0.08)},
	]],
	"res://assets/character/character4/varianten/grau_braun.png": [ALEX, [
		{"ton": 206.0, "breite": 22.0, "saett": 0.12, "hell_max": 0.62, "bezug": 0.37, "farbe": Color(0.4, 0.4, 0.4)},
		{"ton": 92.0, "breite": 26.0, "saett": 0.15, "hell_max": 0.5, "bezug": 0.24, "farbe": Color(0.36, 0.24, 0.13)},
	]],
	# Lisa: Dirndl umgefärbt. Das Rot des Dirndls ist fast gesättigt (0,96), Haut und Haare
	# liegen bei 0,4 — daran lassen sie sich trennen. Das helle Rosa der Stickerei hat
	# einen etwas anderen Farbton (340°) und wird gesondert mitgenommen.
	"res://assets/character/character3/varianten/blau.png": [C3, [
		{"ton": 355.0, "breite": 35.0, "saett": 0.8, "hell_max": 0.95, "bezug": 0.54, "farbe": Color(0.1, 0.22, 0.62)},
		{"ton": 340.0, "breite": 14.0, "saett": 0.4, "hell_max": 1.0, "bezug": 0.7, "farbe": Color(0.4, 0.55, 0.92)},
	]],
	"res://assets/character/character3/varianten/gruen.png": [C3, [
		{"ton": 355.0, "breite": 35.0, "saett": 0.8, "hell_max": 0.95, "bezug": 0.54, "farbe": Color(0.09, 0.4, 0.2)},
		{"ton": 340.0, "breite": 14.0, "saett": 0.4, "hell_max": 1.0, "bezug": 0.7, "farbe": Color(0.45, 0.8, 0.5)},
	]],
	"res://assets/character/character3/varianten/lila.png": [C3, [
		{"ton": 355.0, "breite": 35.0, "saett": 0.8, "hell_max": 0.95, "bezug": 0.54, "farbe": Color(0.42, 0.14, 0.52)},
		{"ton": 340.0, "breite": 14.0, "saett": 0.4, "hell_max": 1.0, "bezug": 0.7, "farbe": Color(0.75, 0.55, 0.88)},
	]],
}

func _init() -> void:
	if "histogramm" in OS.get_cmdline_user_args():
		for q in [C2, ALEX, C3]:
			_histogramm(q)
		quit()
		return
	var geladen := {}
	for ziel: String in VARIANTEN:
		var quelle: String = VARIANTEN[ziel][0]
		if not geladen.has(quelle):
			geladen[quelle] = Image.load_from_file(quelle)
		var bild: Image = (geladen[quelle] as Image).duplicate()
		# Große Quellen (Lisa, 4096²) für die Varianten halbieren — die Figur ist klein im Bild
		if bild.get_width() > 2048:
			bild.resize(2048, 2048, Image.INTERPOLATE_LANCZOS)
		var geaendert := _umfaerben(bild, VARIANTEN[ziel][1])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ziel.get_base_dir()))
		bild.save_png(ProjectSettings.globalize_path(ziel))
		print("  %s: %.1f %% umgefärbt" % [ziel, 100.0 * geaendert / (bild.get_width() * bild.get_height())])
	print("Kleidung gebacken.")
	quit()

func _umfaerben(bild: Image, regeln: Array) -> int:
	var anzahl := 0
	for y in bild.get_height():
		for x in bild.get_width():
			var c := bild.get_pixel(x, y)
			for r: Dictionary in regeln:
				var abstand := absf(wrapf(c.h * 360.0 - float(r.ton), -180.0, 180.0))
				# weiche Ränder, damit an Nähten keine Kanten entstehen
				var w := 1.0 - smoothstep(float(r.breite) * 0.7, float(r.breite), abstand)
				w *= smoothstep(float(r.saett) * 0.7, float(r.saett), c.s)
				w *= 1.0 - smoothstep(float(r.hell_max) - 0.06, float(r.hell_max), c.v)
				if w <= 0.0:
					continue
				var ziel: Color = r.farbe
				var faktor := c.v / float(r.bezug)
				var neu := Color(clampf(ziel.r * faktor, 0, 1), clampf(ziel.g * faktor, 0, 1), clampf(ziel.b * faktor, 0, 1))
				bild.set_pixel(x, y, c.lerp(neu, w))
				anzahl += 1
				break
	return anzahl

func _histogramm(pfad: String) -> void:
	var bild := Image.load_from_file(pfad)
	var toene := {}
	for y in range(0, bild.get_height(), 4):
		for x in range(0, bild.get_width(), 4):
			var c := bild.get_pixel(x, y)
			if c.v < 0.08 or c.s < 0.1:
				continue
			var k := int(c.h * 36.0) * 10
			var e: Array = toene.get(k, [0, 0.0, 0.0])
			toene[k] = [e[0] + 1, e[1] + c.s, e[2] + c.v]
	print(pfad)
	var ks := toene.keys()
	ks.sort()
	for k in ks:
		var e: Array = toene[k]
		if e[0] > 200:
			print("  Ton %3d°: %6d  Sätt. %.2f  Hell. %.2f" % [k, e[0], e[1] / e[0], e[2] / e[0]])
