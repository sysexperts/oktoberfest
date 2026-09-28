extends SceneTree
## Eigene Haarmodelle für Lisa (character3). Im Originalmodell sind Haare und
## Kopf ein einziges Geometriestück mit gleicher Texturfarbe — sauber umfärben
## geht nicht. Darum: eine Haarschale, die die Originalfrisur knapp überdeckt
## (Haardreiecke ein Stück nach außen geschoben), mit denselben Knochengewichten
## wie das Original, damit sie jede Animation exakt mitmacht. Dazu Zusatzteile
## (Zöpfe, Dutt), die am Kopfknochen hängen.
## Ergebnis: assets/character/character3/haare_*.tres
## Aufruf: godot --headless --path . --script res://tools/bake_lisa_haare.gd

const ZIEL := "res://assets/character/character3/"
const KOPF_UNTEN := 1.15
const GESICHT_Z := 0.02
const GESICHT_MITTE := Vector2(0.008, 1.255)
const GESICHT_HALB := Vector2(0.14, 0.125)
const HALS_OBEN := 1.2
const HALS_HALB := 0.1
## so weit liegt die neue Schale über der alten Frisur (Meter)
const ABSTAND := 0.009

func _init() -> void:
	var n: Node = load("res://assets/character/character3/character3.glb").instantiate()
	var mi: MeshInstance3D = n.find_children("*", "MeshInstance3D", true, false)[0]
	var arr: Array = mi.mesh.surface_get_arrays(0)
	_schale(arr, "haare_bob", 0.0)
	n.free()
	print("Haare gebacken.")
	quit()

## Hinten reicht die Originalfrisur tiefer — dort bis HINTEN_UNTEN, nur der
## Nacken in der Mitte bleibt frei
const HINTEN_UNTEN := 1.06
const NACKEN_HALB := 0.075

func _ist_haar(m: Vector3) -> bool:
	if m.z < GESICHT_Z and m.y >= HINTEN_UNTEN and m.y < KOPF_UNTEN:
		# nur am Kopf, nicht an Schultern und Trägern
		return absf(m.x) < 0.2 and not (absf(m.x) < NACKEN_HALB and m.z > -0.12)
	if m.y < KOPF_UNTEN:
		return false
	if m.z > GESICHT_Z:
		if m.y < HALS_OBEN and absf(m.x) < HALS_HALB:
			return false
		var d := Vector2((m.x - GESICHT_MITTE.x) / GESICHT_HALB.x, (m.y - GESICHT_MITTE.y) / GESICHT_HALB.y).length()
		if d < 1.0:
			return false
	return true

## Haarschale aus den Haardreiecken. laenger > 0 zieht die unteren Spitzen
## nach unten (längere Haare).
func _schale(arr: Array, name: String, laenger: float) -> void:
	var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nor: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var knochen: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var gewichte: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var neu_idx := {}
	var o_pos := PackedVector3Array()
	var o_nor := PackedVector3Array()
	var o_kn := PackedInt32Array()
	var o_gw := PackedFloat32Array()
	var o_idx := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		var m := (pos[idx[t]] + pos[idx[t + 1]] + pos[idx[t + 2]]) / 3.0
		if not _ist_haar(m):
			continue
		for j in 3:
			var v := idx[t + j]
			if not neu_idx.has(v):
				neu_idx[v] = o_pos.size()
				var p := pos[v] + nor[v] * ABSTAND
				if laenger > 0.0 and p.y < 1.3 and p.z < 0.1:
					# unten hinten und seitlich: Spitzen verlängern
					p.y -= laenger * smoothstep(1.3, 1.17, p.y)
				o_pos.append(p)
				o_nor.append(nor[v])
				for k in 4:
					o_kn.append(knochen[v * 4 + k])
					o_gw.append(gewichte[v * 4 + k])
			o_idx.append(neu_idx[v])
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = o_pos
	a[Mesh.ARRAY_NORMAL] = o_nor
	a[Mesh.ARRAY_BONES] = o_kn
	a[Mesh.ARRAY_WEIGHTS] = o_gw
	a[Mesh.ARRAY_INDEX] = o_idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	ResourceSaver.save(am, ZIEL + name + ".tres")
	print("  ", name, ": ", o_idx.size() / 3, " Dreiecke")
