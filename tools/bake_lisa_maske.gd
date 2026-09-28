extends SceneTree
## Haar- und Kopfmaske für Lisa (character3, Rot = Haare, Grün = Kopf): Haare und Haut haben in der Textur dieselbe
## Farbe, darum werden die Haar-Dreiecke über ihre Lage im Modell bestimmt
## (Kopf oberhalb des Halses, ohne das Gesicht vorn) und in UV-Koordinaten in
## eine Maske gemalt. Der Farbshader (assets/shader/figur_farbe.gdshader) färbt
## dann nur dort die Haare um.
## Aufruf: godot --headless --path . --script res://tools/bake_lisa_maske.gd

const ZIEL := "res://assets/character/character3/haar_maske.png"
const GROESSE := 1024
## Kopfbereich (Ruhelage, Meter): ab Halsansatz aufwärts
const KOPF_UNTEN := 1.13
## Gesicht: vorn (+z) unterhalb der Haarlinie bleibt Haut
const GESICHT_Z := 0.07
const HAARLINIE := 1.36
## halbe Gesichtsbreite: weiter außen sind vorn schon Haare
const GESICHT_BREITE := 0.15

func _init() -> void:
	var n: Node = load("res://assets/character/character3/character3.glb").instantiate()
	var mi: MeshInstance3D = n.find_children("*", "MeshInstance3D", true, false)[0]
	var arr: Array = mi.mesh.surface_get_arrays(0)
	var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var bild := Image.create(GROESSE, GROESSE, false, Image.FORMAT_RGB8)
	bild.fill(Color.BLACK)
	var anzahl := 0
	for t in range(0, idx.size(), 3):
		var a := pos[idx[t]]
		var b := pos[idx[t + 1]]
		var c := pos[idx[t + 2]]
		var m := (a + b + c) / 3.0
		if m.y < KOPF_UNTEN:
			continue
		# Grün = ganzer Kopf (dort kein Kleid umfärben — Augen, Mund)
		var farbe := Color(0, 1, 0)
		# Gesicht = vorn, unter der Haarlinie und nicht an den Seiten (dort hängen Strähnen)
		var gesicht := m.z > GESICHT_Z and m.y < HAARLINIE and absf(m.x) < GESICHT_BREITE
		if not gesicht:
			farbe = Color(1, 1, 0)   # Rot = Haare
			anzahl += 1
		_dreieck(bild, uv[idx[t]], uv[idx[t + 1]], uv[idx[t + 2]], farbe)
	bild.save_png(ProjectSettings.globalize_path(ZIEL))
	print("Haarmaske: %d Dreiecke -> %s" % [anzahl, ZIEL])
	n.free()
	quit()

func _dreieck(bild: Image, a: Vector2, b: Vector2, c: Vector2, farbe: Color) -> void:
	var p := [a * GROESSE, b * GROESSE, c * GROESSE]
	var minx := int(floor(minf(p[0].x, minf(p[1].x, p[2].x)))) - 1
	var maxx := int(ceil(maxf(p[0].x, maxf(p[1].x, p[2].x)))) + 1
	var miny := int(floor(minf(p[0].y, minf(p[1].y, p[2].y)))) - 1
	var maxy := int(ceil(maxf(p[0].y, maxf(p[1].y, p[2].y)))) + 1
	var flaeche := _kante(p[0], p[1], p[2])
	if absf(flaeche) < 0.0001:
		return
	for y in range(maxi(0, miny), mini(GROESSE, maxy + 1)):
		for x in range(maxi(0, minx), mini(GROESSE, maxx + 1)):
			var q := Vector2(x + 0.5, y + 0.5)
			var w0 := _kante(p[1], p[2], q) / flaeche
			var w1 := _kante(p[2], p[0], q) / flaeche
			var w2 := _kante(p[0], p[1], q) / flaeche
			# etwas großzügig, damit an den UV-Rändern keine Haut-Säume bleiben
			if w0 >= -0.08 and w1 >= -0.08 and w2 >= -0.08:
				var alt := bild.get_pixel(x, y)
				bild.set_pixel(x, y, Color(maxf(alt.r, farbe.r), maxf(alt.g, farbe.g), 0))

func _kante(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
