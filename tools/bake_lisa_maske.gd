extends SceneTree
## Haar- und Kopfmaske für Lisa (character3). Rot = Haare, Grün = Kopf.
## Haare und Haut haben in der Textur dieselbe Farbe — darum wird jeder
## Texturpunkt über seine Lage am Modell (Ruhelage) eingeordnet: Für jeden
## Bildpunkt im UV-Dreieck wird die 3D-Position interpoliert und geprüft.
## Das Gesicht ist eine Ellipse vorn am Kopf, Hals und Dekolleté vorn bleiben
## Haut. So entstehen weiche, runde Ränder statt Dreieckskanten.
## Der Farbshader (assets/shader/figur_farbe.gdshader) liest die Maske.
## Aufruf: godot --headless --path . --script res://tools/bake_lisa_maske.gd

const ZIEL := "res://assets/character/character3/haar_maske.png"
const GROESSE := 2048
## Ab hier aufwärts gehört alles zum Kopf (Meter, Ruhelage)
const KOPF_UNTEN := 1.15
## Gesicht: Ellipse vorn (z > GESICHT_Z), Mitte und Halbachsen
const GESICHT_Z := 0.02
const GESICHT_MITTE := Vector2(0.008, 1.26)   # x, y
const GESICHT_HALB := Vector2(0.155, 0.135)   # Breite, Höhe
## Weicher Übergang am Gesichtsrand (Anteil der Halbachse)
const RAND := 0.12
## Vorn unterhalb dieser Höhe: Hals, keine Haare
const HALS_OBEN := 1.2
## halbe Halsbreite vorn
const HALS_HALB := 0.09

func _init() -> void:
	var n: Node = load("res://assets/character/character3/character3.glb").instantiate()
	var mi: MeshInstance3D = n.find_children("*", "MeshInstance3D", true, false)[0]
	var arr: Array = mi.mesh.surface_get_arrays(0)
	var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var bild := Image.create(GROESSE, GROESSE, false, Image.FORMAT_RGB8)
	bild.fill(Color.BLACK)
	for t in range(0, idx.size(), 3):
		var a := pos[idx[t]]
		var b := pos[idx[t + 1]]
		var c := pos[idx[t + 2]]
		if maxf(a.y, maxf(b.y, c.y)) < KOPF_UNTEN - 0.02:
			continue
		_dreieck(bild, [uv[idx[t]], uv[idx[t + 1]], uv[idx[t + 2]]], [a, b, c])
	bild.save_png(ProjectSettings.globalize_path(ZIEL))
	print("Maske gespeichert: ", ZIEL)
	n.free()
	quit()

## Anteil Haar (0..1) an einer Stelle des Kopfes
func _haar(p: Vector3) -> float:
	if p.y < KOPF_UNTEN:
		return 0.0
	# Haarspitzen laufen weich aus, statt an den Schultern einen Saum zu malen
	var unten := smoothstep(KOPF_UNTEN, KOPF_UNTEN + 0.04, p.y)
	if p.z > GESICHT_Z:
		if p.y < HALS_OBEN and absf(p.x) < HALS_HALB:
			return 0.0   # vorn am Hals (seitlich hängen dort die Haarspitzen)
		var d := Vector2((p.x - GESICHT_MITTE.x) / GESICHT_HALB.x, (p.y - GESICHT_MITTE.y) / GESICHT_HALB.y).length()
		return smoothstep(1.0 - RAND, 1.0 + RAND, d) * unten
	return unten

func _dreieck(bild: Image, t_uv: Array, t_pos: Array) -> void:
	var p: Array = [t_uv[0] * GROESSE, t_uv[1] * GROESSE, t_uv[2] * GROESSE]
	var flaeche := _kante(p[0], p[1], p[2])
	if absf(flaeche) < 0.0001:
		return
	var minx := int(floor(minf(p[0].x, minf(p[1].x, p[2].x)))) - 1
	var maxx := int(ceil(maxf(p[0].x, maxf(p[1].x, p[2].x)))) + 1
	var miny := int(floor(minf(p[0].y, minf(p[1].y, p[2].y)))) - 1
	var maxy := int(ceil(maxf(p[0].y, maxf(p[1].y, p[2].y)))) + 1
	for y in range(maxi(0, miny), mini(GROESSE, maxy + 1)):
		for x in range(maxi(0, minx), mini(GROESSE, maxx + 1)):
			var q := Vector2(x + 0.5, y + 0.5)
			var w0 := _kante(p[1], p[2], q) / flaeche
			var w1 := _kante(p[2], p[0], q) / flaeche
			var w2 := _kante(p[0], p[1], q) / flaeche
			# ein Pixel Rand dazu, damit an UV-Nähten keine Säume bleiben
			if w0 < -0.02 or w1 < -0.02 or w2 < -0.02:
				continue
			var p3: Vector3 = t_pos[0] * w0 + t_pos[1] * w1 + t_pos[2] * w2
			var h := _haar(p3)
			var kopf := 1.0 if p3.y >= KOPF_UNTEN + 0.03 else 0.0
			var alt := bild.get_pixel(x, y)
			bild.set_pixel(x, y, Color(maxf(alt.r, h), maxf(alt.g, kopf), 0))

func _kante(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
