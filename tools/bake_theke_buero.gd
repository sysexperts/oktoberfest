extends SceneTree
## Baut die Schanktheke (scenes/schanktheke.tscn) und das Festbüro
## (scenes/festbuero.tscn) als echte Knoten. Materialien und Bauteile kommen aus
## tools/bake_zelt.gd (assets/zelt/, scenes/zelt/).
##
## Theke: Maße wie früher (18,4 m, Platte 1,09 m, Ausgabe bei x −2), Vorderseite
## (Gäste) = +Z. Das Schankdach bleibt unter 3,3 m und innerhalb |x| ≤ 7,7 —
## sonst stößt es an die Emporen.
## Büro: Blockhütte 10 × 8 m, Tür vorn (−Z), Schild aus dem Übersetzungsschlüssel.
##
## ACHTUNG: überschreibt Handänderungen an beiden Szenen.
##   godot --headless --path . --script tools/bake_theke_buero.gd

const MAT := "res://assets/zelt/materialien/"
const SZ := "res://scenes/zelt/"

var _own: Node
var _meshes := {}
var _formen := {}
var m := {}

func _init() -> void:
	for n in ["dielen", "holz_hell", "holz_dunkel", "vertaefelung", "stoff", "streifen", "streifen_fein",
			"rauten", "rauten_fein", "hopfen", "blau", "weiss", "rot", "gold", "metall", "glas"]:
		m[n] = load(MAT + n + ".tres")
	m.schindel = _mat_speichern("schindel", Color(0.55, 0.17, 0.12), 0.85)
	m.stein = _mat_speichern("stein", Color(0.52, 0.5, 0.47), 0.95)
	m.messing = _mat_speichern("messing", Color(0.85, 0.62, 0.26), 0.3)
	m.papier = _mat_speichern("papier", Color(0.96, 0.93, 0.82), 0.9)
	_speichern(_theke(), "res://scenes/schanktheke.tscn")
	_speichern(_buero(), "res://scenes/festbuero.tscn")
	print("THEKE BUERO FERTIG")
	quit()

func _mat_speichern(name: String, c: Color, r: float) -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.albedo_color = c
	mt.roughness = r
	ResourceSaver.save(mt, MAT + name + ".tres")
	return ResourceLoader.load(MAT + name + ".tres", "", ResourceLoader.CACHE_MODE_REPLACE)

# ------------------------------------------------------------------ Helfer
func _neu(name: String) -> Node3D:
	var r := Node3D.new()
	r.name = name
	_own = r
	_meshes = {}
	_formen = {}
	return r

func _haengen(parent: Node, n: Node, name: String) -> Node:
	n.name = name
	parent.add_child(n)
	n.owner = _own
	return n

func _gruppe(parent: Node, name: String, pos := Vector3.ZERO) -> Node3D:
	var g := Node3D.new()
	g.position = pos
	return _haengen(parent, g, name)

func _rot(g: Vector3) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(g.x), deg_to_rad(g.y), deg_to_rad(g.z)))

func _mi(parent: Node, name: String, mesh: Mesh, xf: Transform3D, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = xf
	mi.material_override = mat
	return _haengen(parent, mi, name)

func _box(parent: Node, name: String, g: Vector3, pos: Vector3, mat: Material, grad := Vector3.ZERO) -> MeshInstance3D:
	var key := "b%.3f_%.3f_%.3f" % [g.x, g.y, g.z]
	if not _meshes.has(key):
		var b := BoxMesh.new()
		b.size = g
		_meshes[key] = b
	return _mi(parent, name, _meshes[key], Transform3D(_rot(grad), pos), mat)

func _zyl(parent: Node, name: String, unten: float, oben: float, h: float, seg: int, xf: Transform3D, mat: Material) -> MeshInstance3D:
	var key := "z%.3f_%.3f_%.3f_%d" % [unten, oben, h, seg]
	if not _meshes.has(key):
		var c := CylinderMesh.new()
		c.bottom_radius = unten
		c.top_radius = oben
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		_meshes[key] = c
	return _mi(parent, name, _meshes[key], xf, mat)

func _torus(parent: Node, name: String, i: float, a: float, xf: Transform3D, mat: Material) -> MeshInstance3D:
	var key := "t%.3f_%.3f" % [i, a]
	if not _meshes.has(key):
		var t := TorusMesh.new()
		t.inner_radius = i
		t.outer_radius = a
		t.rings = 24
		t.ring_segments = 8
		_meshes[key] = t
	return _mi(parent, name, _meshes[key], xf, mat)

func _prisma(parent: Node, name: String, g: Vector3, xf: Transform3D, mat: Material) -> MeshInstance3D:
	var key := "p%.3f_%.3f_%.3f" % [g.x, g.y, g.z]
	if not _meshes.has(key):
		var p := PrismMesh.new()
		p.size = g
		_meshes[key] = p
	return _mi(parent, name, _meshes[key], xf, mat)

func _kollision(koerper: Node, name: String, g: Vector3, pos: Vector3) -> void:
	var key := "%.3f_%.3f_%.3f" % [g.x, g.y, g.z]
	if not _formen.has(key):
		var f := BoxShape3D.new()
		f.size = g
		_formen[key] = f
	var cs := CollisionShape3D.new()
	cs.shape = _formen[key]
	cs.position = pos
	_haengen(koerper, cs, name)

func _instanz(parent: Node, pfad: String, name: String, xf: Transform3D) -> Node3D:
	var n := (load(pfad) as PackedScene).instantiate() as Node3D
	n.transform = xf
	n.name = name
	parent.add_child(n)
	n.owner = _own
	return n

func _speichern(root: Node, pfad: String) -> void:
	var alte_uid := ""
	if FileAccess.file_exists(pfad):
		var treffer := RegEx.create_from_string("uid=\"(uid://[a-z0-9]+)\"").search(FileAccess.get_file_as_string(pfad).get_slice("\n", 0))
		if treffer:
			alte_uid = treffer.get_string(1)
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, pfad)
	root.free()
	if alte_uid != "":
		var text := FileAccess.get_file_as_string(pfad)
		var erste := text.get_slice("\n", 0)
		var neu := RegEx.create_from_string(" uid=\"uid://[a-z0-9]+\"").sub(erste, "").replace("]", " uid=\"%s\"]" % alte_uid)
		var f := FileAccess.open(pfad, FileAccess.WRITE)
		f.store_string(neu + text.substr(erste.length()))
		f.close()
	print("  ", pfad)

# ------------------------------------------------------------ Schanktheke
func _theke() -> Node3D:
	var r := _neu("Schanktheke")
	var korpus := _gruppe(r, "Korpus")
	_box(korpus, "Kern", Vector3(18.0, 0.98, 1.0), Vector3(0, 0.49, -0.05), m.holz_dunkel)
	_box(korpus, "Sockel", Vector3(18.3, 0.14, 1.2), Vector3(0, 0.07, 0.05), m.stein)
	# Halbe Bierfässer als Front, dazwischen Lisenen
	var faesser := _gruppe(r, "Fassfront")
	for i in 9:
		var x := -8.0 + i * 2.0
		var f := _gruppe(faesser, "Fass%d" % (i + 1), Vector3(x, 0, 0.42))
		_zyl(f, "Bauch", 0.44, 0.44, 0.78, 20, Transform3D(Basis(), Vector3(0, 0.55, 0)), m.holz_hell)
		_zyl(f, "Dauben", 0.4, 0.4, 0.86, 20, Transform3D(Basis(), Vector3(0, 0.55, 0)), m.holz_hell)
		for y in [0.26, 0.84]:
			_torus(f, "Reif_%s" % String.num(y), 0.4, 0.445, Transform3D(Basis(), Vector3(0, y, 0)), m.metall)
		_zyl(f, "Spund", 0.06, 0.06, 0.05, 12, Transform3D(_rot(Vector3(90, 0, 0)), Vector3(0, 0.55, 0.45)), m.messing)
		if i < 8:
			_box(faesser, "Lisene%d" % (i + 1), Vector3(0.16, 0.9, 0.14), Vector3(x + 1.0, 0.55, 0.62), m.holz_dunkel)
	# Messing-Fußleiste mit Haltern
	_zyl(r, "Fussleiste", 0.035, 0.035, 18.0, 12, Transform3D(_rot(Vector3(0, 0, 90)), Vector3(0, 0.2, 0.98)), m.messing)
	for i in 7:
		_box(r, "Halter%d" % (i + 1), Vector3(0.05, 0.05, 0.4), Vector3(-7.5 + i * 2.5, 0.2, 0.8), m.messing)
	# Dicke Eichenplatte mit Rautenfries
	_box(r, "Platte", Vector3(18.6, 0.11, 1.7), Vector3(0, 1.035, 0.12), m.holz_hell)
	_box(r, "Fries", Vector3(18.4, 0.14, 0.03), Vector3(0, 0.9, 0.96), m.rauten_fein)
	_box(r, "Tropfleiste", Vector3(18.6, 0.04, 0.05), Vector3(0, 0.98, 0.98), m.messing)
	# Schankdach: niedrig und schmal genug für die Emporen
	var dach := _gruppe(r, "Schankdach")
	for x in [-7.4, -4.6, 4.6, 7.4]:
		_box(dach, "Pfosten_%s" % String.num(x), Vector3(0.16, 1.95, 0.16), Vector3(x, 1.09 + 0.975, -0.55), m.holz_dunkel)
	_box(dach, "Raehm", Vector3(15.2, 0.2, 0.2), Vector3(0, 3.1, -0.55), m.holz_dunkel)
	_box(dach, "Vordach", Vector3(15.4, 0.05, 1.3), Vector3(0, 3.25, 0.0), m.streifen, Vector3(-9, 0, 0))
	for i in 5:
		_instanz(dach, SZ + "lambrequin_2.tscn", "Volant%d" % (i + 1), Transform3D(Basis().scaled(Vector3(1.5, 0.8, 1)), Vector3(-6.0 + i * 3.0, 3.1, 0.65)))
	var regal := _gruppe(dach, "Glaeserregal")
	_box(regal, "Stange", Vector3(14.6, 0.05, 0.05), Vector3(0, 2.85, -0.3), m.messing)
	for i in 28:
		var x := -7.0 + i * 0.52
		if absf(x + 2.0) < 2.3:
			continue   # über der Ausgabe hängt das Schild
		_instanz(regal, "res://scenes/krug.tscn", "Krug%d" % (i + 1), Transform3D(_rot(Vector3(180, 0, 0)), Vector3(x, 2.82, -0.3)))
	# Schild mit dem Zeltnamen an Ketten über der Ausgabe
	var schild := _gruppe(r, "Schild", Vector3(-2.0, 2.3, -0.42))
	_box(schild, "Tafel", Vector3(4.2, 0.9, 0.08), Vector3.ZERO, m.holz_dunkel)
	_box(schild, "RahmenOben", Vector3(4.36, 0.07, 0.12), Vector3(0, 0.47, 0.02), m.gold)
	_box(schild, "RahmenUnten", Vector3(4.36, 0.07, 0.12), Vector3(0, -0.47, 0.02), m.gold)
	_zyl(schild, "KetteL", 0.012, 0.012, 0.36, 6, Transform3D(Basis(), Vector3(-1.9, 0.63, 0)), m.metall)
	_zyl(schild, "KetteR", 0.012, 0.012, 0.36, 6, Transform3D(Basis(), Vector3(1.9, 0.63, 0)), m.metall)
	var name_l := Label3D.new()
	name_l.position = Vector3(-2.0, 2.3, -0.34)
	name_l.visible = false
	name_l.pixel_size = 0.006
	name_l.double_sided = false
	name_l.modulate = Color(1, 0.86, 0.45)
	name_l.outline_modulate = Color(0.2, 0.1, 0.04)
	name_l.text = "Festzelt"
	name_l.font = load("res://assets/fonts/UnifrakturCook-Bold.ttf")
	name_l.font_size = 80
	name_l.outline_size = 16
	name_l.set_meta("breite", 3.8)
	name_l.set_meta("pixel_basis", 0.006)
	_haengen(r, name_l, "Zeltname")
	name_l.add_to_group("zeltname", true)
	# Laternen und Zapfsäulen (Deko)
	for x in [-7.4, 7.4]:
		_instanz(r, SZ + "wandlaterne.tscn", "Laterne_%s" % String.num(x), Transform3D(Basis(), Vector3(x, 2.3, -0.47)))
	for x in [-6.4, 3.4]:
		var z := _gruppe(r, "Zapfsaeule_%s" % String.num(x), Vector3(x, 1.09, -0.1))
		_zyl(z, "Saeule", 0.05, 0.05, 0.45, 12, Transform3D(Basis(), Vector3(0, 0.22, 0)), m.messing)
		_box(z, "Kopf", Vector3(0.5, 0.1, 0.1), Vector3(0, 0.45, 0), m.messing)
		for k in 3:
			_zyl(z, "Hahn%d" % (k + 1), 0.02, 0.02, 0.16, 8, Transform3D(Basis(), Vector3(-0.18 + k * 0.18, 0.34, 0.05)), m.holz_dunkel)
	# Kollision (Fässer ragen vor) und Ausgabe
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Body")
	_kollision(koerper, "CollisionShape3D", Vector3(18.4, 1.1, 1.8), Vector3(0, 0.55, 0.1))
	_instanz(r, "res://scenes/ausgabe.tscn", "Ausgabe", Transform3D(Basis(), Vector3(-2, 1.09, 0.3)))
	return r

# ------------------------------------------------------------ Festbüro
func _buero() -> Node3D:
	var r := _neu("Festbuero")
	var hw := 5.0
	var hd := 4.0
	var sockel := 0.14
	var wand_h := 3.2
	_box(r, "Sockel", Vector3(10.4, sockel, 8.4), Vector3(0, sockel / 2.0, 0), m.stein)
	_box(r, "Dielen", Vector3(9.7, 0.02, 7.7), Vector3(0, sockel + 0.01, 0), m.dielen)
	var w := _gruppe(r, "Waende")
	var lagen := 10
	var lage_h := wand_h / lagen
	for i in lagen:
		var y := sockel + (i + 0.5) * lage_h
		var mat: Material = m.holz_hell if i % 2 == 0 else m.vertaefelung
		_box(w, "Hinten%d" % i, Vector3(10.2, lage_h - 0.02, 0.3), Vector3(0, y, hd), mat)
		_box(w, "Links%d" % i, Vector3(0.3, lage_h - 0.02, 8.2), Vector3(-hw, y, 0), mat)
		_box(w, "Rechts%d" % i, Vector3(0.3, lage_h - 0.02, 8.2), Vector3(hw, y, 0), mat)
		if y < sockel + 2.5:
			_box(w, "VorneL%d" % i, Vector3(4.1, lage_h - 0.02, 0.3), Vector3(-2.95, y, -hd), mat)
			_box(w, "VorneR%d" % i, Vector3(4.1, lage_h - 0.02, 0.3), Vector3(2.95, y, -hd), mat)
		else:
			_box(w, "Vorne%d" % i, Vector3(10.2, lage_h - 0.02, 0.3), Vector3(0, y, -hd), mat)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			for i in lagen:
				_box(w, "Kopf_%s_%s_%d" % [sx, sz, i], Vector3(0.36, lage_h - 0.03, 0.36), Vector3(sx * (hw + 0.1), sockel + (i + 0.5) * lage_h, sz * (hd + 0.1)), m.holz_dunkel)
	var tuer := _gruppe(r, "Tuer", Vector3(0, sockel, -hd - 0.02))
	_box(tuer, "RahmenL", Vector3(0.14, 2.6, 0.36), Vector3(-0.97, 1.3, 0), m.holz_dunkel)
	_box(tuer, "RahmenR", Vector3(0.14, 2.6, 0.36), Vector3(0.97, 1.3, 0), m.holz_dunkel)
	_box(tuer, "Sturz", Vector3(2.1, 0.18, 0.36), Vector3(0, 2.6, 0), m.holz_dunkel)
	_box(tuer, "Blatt", Vector3(0.85, 2.4, 0.06), Vector3(-0.45, 1.2, -0.3), m.blau, Vector3(0, -70, 0))
	_box(tuer, "Fuellung", Vector3(0.6, 0.9, 0.02), Vector3(-0.66, 1.5, -0.62), m.rauten_fein, Vector3(0, -70, 0))
	for x in [-3.0, 3.0]:
		_instanz(r, SZ + "fenster.tscn", "FensterVorn_%s" % String.num(x), Transform3D(_rot(Vector3(0, 180, 0)), Vector3(x, 1.7, -hd)))
		_instanz(r, SZ + "blumenkasten.tscn", "Blumen_%s" % String.num(x), Transform3D(_rot(Vector3(0, 180, 0)), Vector3(x, 0.9, -hd - 0.3)))
	for z in [-1.8, 1.8]:
		for sx: float in [-1.0, 1.0]:
			_instanz(r, SZ + "fenster.tscn", "FensterSeite_%s_%s" % [sx, z], Transform3D(_rot(Vector3(0, sx * 90, 0)), Vector3(sx * hw, 1.7, z)))
	# Satteldach mit Schindelreihen
	var dach := _gruppe(r, "Dach")
	var traufe := sockel + wand_h
	var first := traufe + 2.2
	var neigung := rad_to_deg(atan2(2.2, hd + 0.2))
	var tiefe := hd + 0.9
	var laenge := sqrt(pow(tiefe, 2) + pow(2.2 * tiefe / (hd + 0.2), 2))
	for sz: float in [-1.0, 1.0]:
		var mitte := Vector3(0, first - 1.1 * tiefe / (hd + 0.2) + 0.08, sz * tiefe / 2.0)
		_box(dach, "Flaeche" + ("Vorn" if sz < 0 else "Hinten"), Vector3(11.4, 0.16, laenge), mitte, m.schindel, Vector3(sz * neigung, 0, 0))
		for k in 7:
			var t := (k + 0.5) / 7.0
			_box(dach, "Schindelreihe_%s_%d" % [sz, k], Vector3(11.44, 0.05, 0.12), Vector3(0, first - 2.2 * t * tiefe / (hd + 0.2) + 0.18, sz * tiefe * t), m.holz_dunkel, Vector3(sz * neigung, 0, 0))
	_box(dach, "First", Vector3(11.5, 0.2, 0.3), Vector3(0, first + 0.12, 0), m.holz_dunkel)
	for sx: float in [-1.0, 1.0]:
		_prisma(dach, "Giebel" + ("Links" if sx < 0 else "Rechts"), Vector3(8.4, 2.2, 0.3), Transform3D(_rot(Vector3(0, 90, 0)), Vector3(sx * hw, traufe + 1.1, 0)), m.stoff)
	_instanz(dach, SZ + "fahne.tscn", "FirstFahne", Transform3D(Basis(), Vector3(3.8, first + 0.2, 0)))
	for i in 2:
		_instanz(dach, SZ + "lambrequin_2.tscn", "Volant%d" % (i + 1), Transform3D(Basis().scaled(Vector3(2.8, 1, 1)), Vector3(-2.8 + i * 5.6, traufe - 0.2, -hd - 0.95)))
	# Vordach über der Tür
	var vd := _gruppe(r, "Vordach", Vector3(0, 0, -hd))
	for x in [-1.4, 1.4]:
		_box(vd, "Pfosten_%s" % String.num(x), Vector3(0.16, 2.9, 0.16), Vector3(x, 1.45, -1.5), m.holz_dunkel)
	_box(vd, "Dach", Vector3(3.4, 0.08, 1.8), Vector3(0, 2.95, -0.85), m.streifen, Vector3(-12, 0, 0))
	_box(vd, "Stufe", Vector3(3.0, 0.12, 1.6), Vector3(0, 0.06, -0.9), m.holz_hell)
	# Schild über dem Vordach (Text aus dem Übersetzungsschlüssel)
	var sch := _gruppe(r, "Schild", Vector3(0, traufe + 0.55, -hd - 0.2))
	_box(sch, "Tafel", Vector3(4.6, 0.8, 0.08), Vector3.ZERO, m.holz_dunkel)
	_box(sch, "Rahmen", Vector3(4.76, 0.9, 0.05), Vector3(0, 0, 0.03), m.gold)
	var text := Label3D.new()
	text.set_script(load("res://scripts/welt_text.gd"))
	text.set("schluessel", "WORLD_OFFICE_SIGN")
	text.text = "WORLD_OFFICE_SIGN"
	text.position = Vector3(0, 0, -0.06)
	text.rotation_degrees = Vector3(0, 180, 0)
	text.pixel_size = 0.008
	text.font_size = 64
	text.outline_size = 16
	text.modulate = Color(1, 0.9, 0.5)
	text.double_sided = false
	_haengen(sch, text, "Text")
	# Aushangtafel, Bank, Laterne, Fass
	var aus := _gruppe(r, "Aushang", Vector3(3.9, sockel, -hd - 0.8))
	_box(aus, "Brett", Vector3(1.6, 1.1, 0.06), Vector3(0, 1.45, 0), m.holz_dunkel)
	_prisma(aus, "Dach", Vector3(1.8, 0.3, 0.3), Transform3D(Basis(), Vector3(0, 2.15, 0)), m.schindel)
	var winkel := [-4.0, 3.0, -2.0, 5.0, -3.0]
	for k in 5:
		_box(aus, "Zettel%d" % (k + 1), Vector3(0.36, 0.44, 0.01), Vector3(-0.55 + (k % 3) * 0.55, 1.65 - (k / 3) * 0.5, -0.04), m.papier if k != 2 else m.rauten_fein, Vector3(0, 0, winkel[k]))
	for x in [-0.6, 0.6]:
		_box(aus, "Bein_%s" % String.num(x), Vector3(0.08, 2.0, 0.08), Vector3(x, 1.0, 0.05), m.holz_dunkel)
	var bank := _gruppe(r, "Bank", Vector3(-3.6, sockel, -hd - 0.7))
	_box(bank, "Sitz", Vector3(1.8, 0.07, 0.4), Vector3(0, 0.45, 0), m.holz_hell)
	_box(bank, "Lehne", Vector3(1.8, 0.35, 0.05), Vector3(0, 0.75, 0.2), m.holz_hell)
	for x in [-0.75, 0.75]:
		_box(bank, "Fuss_%s" % String.num(x), Vector3(0.08, 0.45, 0.4), Vector3(x, 0.22, 0), m.holz_dunkel)
	_instanz(r, SZ + "wandlaterne.tscn", "Laterne", Transform3D(_rot(Vector3(0, 180, 0)), Vector3(-1.4, 2.5, -hd - 0.15)))
	_instanz(r, SZ + "fass.tscn", "Fass", Transform3D(Basis(), Vector3(-4.9, 0, -hd - 0.6)))
	# Kollision: Wände mit Türöffnung
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	var hm := sockel + wand_h / 2.0
	_kollision(koerper, "Hinten", Vector3(10.2, wand_h, 0.3), Vector3(0, hm, hd))
	_kollision(koerper, "Links", Vector3(0.3, wand_h, 8.2), Vector3(-hw, hm, 0))
	_kollision(koerper, "Rechts", Vector3(0.3, wand_h, 8.2), Vector3(hw, hm, 0))
	_kollision(koerper, "VorneL", Vector3(4.1, wand_h, 0.3), Vector3(-2.95, hm, -hd))
	_kollision(koerper, "VorneR", Vector3(4.1, wand_h, 0.3), Vector3(2.95, hm, -hd))
	_kollision(koerper, "Aushang", Vector3(1.6, 2.0, 0.3), Vector3(3.9, 1.0, -hd - 0.8))
	return r
