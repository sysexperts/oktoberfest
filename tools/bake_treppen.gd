extends SceneTree
## Baut die beiden Emporentreppen (Galerie/EmporeWest|Ost/Treppe in
## scenes/tent.tscn) neu — und nur die Stufen. Wangen, Handlauf und Pfosten
## bleiben, ebenso alles andere im Zelt (auch was von Hand oder von anderen
## Werkzeugen ergänzt wurde; tools/bake_zelt.gd würde das überschreiben).
##
## Vorher: lose, dünne Bretter ohne Setzstufen. Licht schien dazwischen durch,
## und die Bretter überlappten sich.
## Jetzt, wie in tools/bake_braukeller.gd (Kellertreppe):
##   Trittbrett  5 cm dick, 3 cm Nase vorn, reicht hinten unter die nächste
##               Setzstufe
##   Setzstufe   steht auf dem Tritt davor und trägt den nächsten; ihre Vorderseite
##               liegt 3 cm hinter der Nase — nie in einer Ebene mit dem Tritt
##   oberste Stufe endet genau an der Emporenkante (kein Überlappen mit dem Boden)
## Maße (Stufenzahl, Breite, Steigung, Lage) werden aus den alten Stufen gelesen.
##
## Wandabstand: Die äußere Wange (x = ±11,97, 6 cm dick) füllte exakt denselben Raum
## wie die Wandvertäfelung (ebenfalls x = ±11,97, 6 cm dick) — alle Flächen lagen in
## denselben Ebenen. Die ganze Treppe sitzt deshalb 1 cm weiter zur Halle (Knoten
## „Treppe“ um ±1 cm versetzt): die Wange steht 1 cm vor der Vertäfelung, nichts
## liegt mehr bündig.
##
##   godot --headless --path . --script tools/bake_treppen.gd

const ZELT := "res://scenes/tent.tscn"
const WANDABSTAND := 0.01
const DICK := 0.05
const NASE := 0.03
const SETZ := 0.03

var _meshes := {}

func _init() -> void:
	var alte_uid := ""
	var kopf := FileAccess.get_file_as_string(ZELT).get_slice("\n", 0)
	var t := RegEx.create_from_string("uid=\"(uid://[a-z0-9]+)\"").search(kopf)
	if t:
		alte_uid = t.get_string(1)
	var root := (load(ZELT) as PackedScene).instantiate()
	var gesamt := 0
	for seite in ["EmporeWest", "EmporeOst"]:
		var tr := root.get_node_or_null("Galerie/%s/Treppe" % seite)
		if tr == null:
			push_error("Treppe fehlt: " + seite)
			continue
		gesamt += _bauen(root, tr)
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, ZELT)
	root.free()
	if alte_uid != "":
		var text := FileAccess.get_file_as_string(ZELT)
		var erste := text.get_slice("\n", 0)
		var neu := RegEx.create_from_string(" uid=\"uid://[a-z0-9]+\"").sub(erste, "").replace("]", " uid=\"%s\"]" % alte_uid)
		var f := FileAccess.open(ZELT, FileAccess.WRITE)
		f.store_string(text.replace(erste, neu))
		f.close()
	print("TREPPEN FERTIG (", gesamt, " Stufen)")
	quit()

func _box(g: Vector3) -> BoxMesh:
	var key := "%.4f_%.4f_%.4f" % [g.x, g.y, g.z]
	if not _meshes.has(key):
		var b := BoxMesh.new()
		b.size = g
		_meshes[key] = b
	return _meshes[key]

func _neu(root: Node, eltern: Node, name: String, g: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = _box(g)
	mi.position = pos
	mi.material_override = mat
	eltern.add_child(mi)
	mi.owner = root

func _bauen(root: Node, tr: Node) -> int:
	var stufen: Array[MeshInstance3D] = []   # alte Bretter (Stufe1 …) oder schon gebaute Tritte
	var setz: Array[MeshInstance3D] = []
	var wange: MeshInstance3D = null
	var alt_form := true
	for c in tr.get_children():
		if not c is MeshInstance3D:
			continue
		if c.name.begins_with("Stufe"):
			stufen.append(c)
		elif c.name.begins_with("Tritt"):
			stufen.append(c)
			alt_form = false
		elif c.name.begins_with("Setzstufe"):
			setz.append(c)
		elif c.name.begins_with("Wange") and wange == null:
			wange = c
	if stufen.is_empty():
		return 0
	var s1 := stufen[0]
	var n := stufen.size()
	var alt := s1.mesh as BoxMesh
	var mat_tritt := s1.material_override
	var mat_holz: Material = wange.material_override if wange else mat_tritt
	if not setz.is_empty():
		mat_holz = setz[0].material_override
	var breite := alt.size.x
	var tritt: float
	var steigung: float
	var qx := s1.position.x
	var zu: float
	if alt_form:
		# lose Bretter: Mitte bei zu + tritt * (i + 0,5), Dicke 7 cm, Länge tritt + 4 cm
		tritt = alt.size.z - 0.04
		steigung = s1.position.y + 0.035
		zu = s1.position.z - tritt * 0.5
	else:
		# schon gebaute Tritte: erste Kante = Mitte - halbe Länge + Nase, Abstand der Mitten = tritt
		tritt = stufen[1].position.z - s1.position.z
		steigung = s1.position.y + DICK / 2.0
		zu = s1.position.z - alt.size.z / 2.0 + NASE
	# zur Halle hin: West (x < 0) nach +x, Ost nach -x. Gesetzt, nicht addiert —
	# das Werkzeug lässt sich beliebig oft laufen.
	tr.position.x = -signf(qx) * WANDABSTAND
	for st in stufen:
		tr.remove_child(st)
		st.free()
	for st in setz:
		tr.remove_child(st)
		st.free()
	for i in n:
		var zi := zu + tritt * i
		var yi := steigung * (i + 1)
		var y_davor := steigung * i
		var z0 := zi - NASE
		var z1 := zi + tritt + SETZ - 0.006   # hinten 6 mm kürzer als die Setzstufe: nie bündig
		if i == n - 1:
			z1 = zi + tritt   # endet genau an der Emporenkante
		_neu(root, tr, "Tritt%d" % (i + 1), Vector3(breite, DICK, z1 - z0), Vector3(qx, yi - DICK / 2.0, (z0 + z1) / 2.0), mat_tritt)
		# von der Oberkante des Tritts davor bis 2 mm in den Tritt darüber
		var h := steigung - DICK + 0.004
		_neu(root, tr, "Setzstufe%d" % (i + 1), Vector3(breite, h, SETZ), Vector3(qx, (y_davor + yi - DICK) / 2.0, zi + SETZ / 2.0), mat_holz)
	return n
