extends SceneTree
## Baut die Regalwand hinter der Schankseite (scenes/rueckwand_regal.tscn) als
## echte Knoten: 8 m breit, Unterschrank, drei Bretter mit Krügen — wie bisher,
## nur detaillierter (Sockel, Türen mit Rautenfüllung und Messinggriffen,
## Kranzgesims mit Rautenfries, Konsolen unter den Brettern, gedrechselte
## Aufsätze, Rautenband hinter den Fässern).
##
## Maße: Ursprung am Boden, Mitte der Wand (x = 0), Gäste vorn (+z). Die Platte
## liegt oben bei y = 0,92 — Fässer und Krugstapel (scenes/main.tscn, Stations)
## stehen genau darauf. Das unterste Brett liegt bei 1,75 m: die Fässer sind
## 0,64 m hoch (Oberkante 1,56 m), sonst ragen sie in Brett und Krüge.
##
## Die Krugpositionen (Lücken in den Reihen) werden aus der bestehenden Szene
## übernommen, damit die Reihen so bleiben, wie sie sind.
##
## ACHTUNG: überschreibt Handänderungen an der Szene.
##   godot --headless --path . --script tools/bake_rueckwand_regal.gd

const ZIEL := "res://scenes/rueckwand_regal.tscn"
const MAT := "res://assets/zelt/materialien/"
const KRUG := "res://scenes/krug.tscn"

const PLATTE_OBEN := 0.92
const BRETTER := [1.75, 2.15, 2.55]     # Oberkante der drei Bretter
const WAND_OBEN := 3.05
const HALB := 4.0                        # halbe Breite

var _own: Node
var _meshes := {}
var _formen := {}
var m := {}

func _init() -> void:
	for n in ["holz_dunkel", "holz_hell", "messing", "blau", "weiss", "rauten_fein", "rauten", "gold", "schwarz_lack"]:
		m[n] = load(MAT + n + ".tres")
	var reihen := _reihen_lesen()
	var root := _bauen(reihen)
	var ps := PackedScene.new()
	ps.pack(root)
	var alte_uid := _alte_uid()
	ResourceSaver.save(ps, ZIEL)
	root.free()
	if alte_uid != "":
		var text := FileAccess.get_file_as_string(ZIEL)
		var erste := text.get_slice("\n", 0)
		var neu := RegEx.create_from_string(" uid=\"uid://[a-z0-9]+\"").sub(erste, "").replace("]", " uid=\"%s\"]" % alte_uid)
		var f := FileAccess.open(ZIEL, FileAccess.WRITE)
		f.store_string(text.replace(erste, neu))
		f.close()
	print("REGALWAND FERTIG (", reihen.size(), " Reihen)")
	quit()

func _alte_uid() -> String:
	if not FileAccess.file_exists(ZIEL):
		return ""
	var t := RegEx.create_from_string("uid=\"(uid://[a-z0-9]+)\"").search(FileAccess.get_file_as_string(ZIEL).get_slice("\n", 0))
	return t.get_string(1) if t else ""

## Reihe -> Liste der x-Werte der Krüge aus der bestehenden Szene
func _reihen_lesen() -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(ZIEL):
		return out
	var re_k := RegEx.create_from_string("\\[node name=\"K\\d+\" parent=\"Glaeser/(Reihe\\d)\"[^\\]]*instance[^\\]]*\\]\\ntransform = Transform3D\\([^,]*,[^,]*,[^,]*,[^,]*,[^,]*,[^,]*,[^,]*,[^,]*,[^,]*, ([-0-9.]+),")
	for t in re_k.search_all(FileAccess.get_file_as_string(ZIEL)):
		var r := t.get_string(1)
		if not out.has(r):
			out[r] = []
		out[r].append(float(t.get_string(2)))
	return out

# ------------------------------------------------------------------ Helfer
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
	return _haengen(parent, mi, name) as MeshInstance3D

func _box(parent: Node, name: String, g: Vector3, pos: Vector3, mat: Material, grad := Vector3.ZERO) -> MeshInstance3D:
	var key := "b%.3f_%.3f_%.3f" % [g.x, g.y, g.z]
	if not _meshes.has(key):
		var b := BoxMesh.new()
		b.size = g
		_meshes[key] = b
	return _mi(parent, name, _meshes[key], Transform3D(_rot(grad), pos), mat)

func _zyl(parent: Node, name: String, r_unten: float, r_oben: float, h: float, seg: int, pos: Vector3, mat: Material, grad := Vector3.ZERO) -> MeshInstance3D:
	var key := "z%.3f_%.3f_%.3f_%d" % [r_unten, r_oben, h, seg]
	if not _meshes.has(key):
		var c := CylinderMesh.new()
		c.bottom_radius = r_unten
		c.top_radius = r_oben
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		_meshes[key] = c
	return _mi(parent, name, _meshes[key], Transform3D(_rot(grad), pos), mat)

func _kugel(parent: Node, name: String, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var key := "k%.3f" % r
	if not _meshes.has(key):
		var s := SphereMesh.new()
		s.radius = r
		s.height = r * 2.0
		s.radial_segments = 16
		s.rings = 8
		_meshes[key] = s
	return _mi(parent, name, _meshes[key], Transform3D(Basis(), pos), mat)

# ------------------------------------------------------------------ Aufbau
func _bauen(reihen: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "RueckwandRegal"
	_own = root
	_meshes = {}
	_formen = {}
	var dunkel: Material = m.holz_dunkel
	var hell: Material = m.holz_hell
	var messing: Material = m.messing

	# --- Unterschrank -------------------------------------------------------
	var schrank := _gruppe(root, "Unterschrank")
	_box(schrank, "Sockel", Vector3(7.94, 0.10, 0.60), Vector3(0, 0.05, -0.02), dunkel)
	_box(schrank, "Korpus", Vector3(8.0, 0.76, 0.64), Vector3(0, 0.48, -0.03), dunkel)
	# Pfosten zwischen den Türpaaren und an den Enden
	for i in 5:
		var x := -4.0 + 2.0 * i
		_box(schrank, "Pfosten%d" % i, Vector3(0.07, 0.76, 0.05), Vector3(clampf(x, -3.965, 3.965), 0.48, 0.315), hell)
	# Sockelleiste und Fries oben über den Türen
	_box(schrank, "FriesUnten", Vector3(7.9, 0.03, 0.04), Vector3(0, 0.115, 0.31), hell)
	_box(schrank, "FriesOben", Vector3(7.9, 0.035, 0.04), Vector3(0, 0.845, 0.31), hell)
	# Türen: Rahmen, eingelassene Füllung, Rautenintarsie, Messinggriff
	for i in 8:
		var x := -3.5 + i
		var tuer := _gruppe(schrank, "Tuer%d" % (i + 1), Vector3(x, 0.48, 0))
		_box(tuer, "Rahmen", Vector3(0.90, 0.68, 0.035), Vector3(0, 0, 0.315), hell)
		_box(tuer, "Fuellung", Vector3(0.70, 0.46, 0.03), Vector3(0, 0, 0.33), dunkel)
		var raute := _box(tuer, "Raute", Vector3(0.17, 0.17, 0.012), Vector3(0, 0, 0.349), m.blau if i % 2 == 0 else m.weiss, Vector3(0, 0, 45))
		raute.name = "Raute"
		_box(tuer, "RauteKern", Vector3(0.075, 0.075, 0.014), Vector3(0, 0, 0.351), m.weiss if i % 2 == 0 else m.blau, Vector3(0, 0, 45))
		# Griff am Mittelspalt des Türpaares
		var gx := 0.39 if i % 2 == 0 else -0.39
		_zyl(tuer, "Griff", 0.011, 0.011, 0.20, 10, Vector3(gx, 0.13, 0.372), messing)
		_kugel(tuer, "GriffKnopfOben", 0.017, Vector3(gx, 0.225, 0.372), messing)
		_kugel(tuer, "GriffKnopfUnten", 0.017, Vector3(gx, 0.035, 0.372), messing)
		_zyl(tuer, "GriffFussOben", 0.006, 0.006, 0.04, 8, Vector3(gx, 0.225, 0.352), messing, Vector3(90, 0, 0))
		_zyl(tuer, "GriffFussUnten", 0.006, 0.006, 0.04, 8, Vector3(gx, 0.035, 0.352), messing, Vector3(90, 0, 0))

	# --- Arbeitsplatte ------------------------------------------------------
	var platte := _gruppe(root, "Arbeitsplatte")
	_box(platte, "Platte", Vector3(8.16, 0.055, 0.80), Vector3(0, PLATTE_OBEN - 0.0275, 0.02), hell)
	# abgerundete Vorderkante und Messingleiste
	_zyl(platte, "Vorderkante", 0.0275, 0.0275, 8.16, 10, Vector3(0, PLATTE_OBEN - 0.0275, 0.42), hell, Vector3(0, 0, 90))
	_box(platte, "MessingLeiste", Vector3(8.1, 0.006, 0.014), Vector3(0, PLATTE_OBEN + 0.003, 0.385), messing)
	_box(platte, "Untersims", Vector3(8.0, 0.03, 0.03), Vector3(0, PLATTE_OBEN - 0.07, 0.385), dunkel)

	# --- Rückwand -----------------------------------------------------------
	var wand := _gruppe(root, "Wand")
	var wand_h := WAND_OBEN - PLATTE_OBEN
	_box(wand, "Rueckwand", Vector3(8.0, wand_h, 0.05), Vector3(0, PLATTE_OBEN + wand_h / 2.0, -0.33), dunkel)
	# Rautenband hinter den Fässern (Spritzschutz)
	var band_unten := PLATTE_OBEN
	var band_oben := BRETTER[0] - 0.13
	_box(wand, "Spritzschutz", Vector3(7.86, band_oben - band_unten, 0.02), Vector3(0, (band_oben + band_unten) / 2.0, -0.295), m.rauten_fein)
	_box(wand, "SpritzschutzRahmenOben", Vector3(7.9, 0.05, 0.04), Vector3(0, band_oben + 0.025, -0.29), hell)
	_box(wand, "SpritzschutzRahmenUnten", Vector3(7.9, 0.03, 0.04), Vector3(0, band_unten + 0.015, -0.29), hell)
	# senkrechte Leisten oberhalb des Rautenbands, zwischen den Brettern
	var leiste_unten := band_oben + 0.05
	for i in 9:
		var x := -4.0 + 1.0 * i
		_box(wand, "Leiste%d" % i, Vector3(0.05, WAND_OBEN - 0.10 - leiste_unten, 0.02), Vector3(clampf(x, -3.9, 3.9), (leiste_unten + WAND_OBEN - 0.10) / 2.0, -0.295), hell)
	# Rautenfries unter dem Gesims
	_box(wand, "Fries", Vector3(7.86, 0.11, 0.02), Vector3(0, WAND_OBEN - 0.075, -0.285), m.rauten)
	_box(wand, "FriesRahmenUnten", Vector3(7.9, 0.02, 0.035), Vector3(0, WAND_OBEN - 0.14, -0.285), hell)

	# --- Seiten mit gedrechselten Aufsätzen ---------------------------------
	for seite in [-1.0, 1.0]:
		var n := "Links" if seite < 0.0 else "Rechts"
		var s := _gruppe(root, "Seite" + n, Vector3(seite * 3.96, 0, 0))
		_box(s, "Wange", Vector3(0.08, wand_h, 0.40), Vector3(0, PLATTE_OBEN + wand_h / 2.0, -0.15), dunkel)
		_box(s, "Leiste", Vector3(0.10, wand_h, 0.03), Vector3(0, PLATTE_OBEN + wand_h / 2.0, 0.055), hell)
		_zyl(s, "AufsatzHals", 0.03, 0.045, 0.08, 12, Vector3(0, WAND_OBEN + 0.13, -0.12), dunkel)
		_kugel(s, "AufsatzKugel", 0.065, Vector3(0, WAND_OBEN + 0.23, -0.12), hell)
		_zyl(s, "AufsatzSpitze", 0.0, 0.03, 0.09, 12, Vector3(0, WAND_OBEN + 0.32, -0.12), messing)

	# --- Gesims -------------------------------------------------------------
	var gesims := _gruppe(root, "Gesims")
	_box(gesims, "Platte", Vector3(8.3, 0.05, 0.52), Vector3(0, WAND_OBEN + 0.075, -0.09), hell)
	_box(gesims, "Kehle", Vector3(8.16, 0.07, 0.46), Vector3(0, WAND_OBEN + 0.015, -0.11), dunkel)
	_box(gesims, "Leiste", Vector3(8.3, 0.02, 0.54), Vector3(0, WAND_OBEN + 0.11, -0.09), dunkel)
	# Zahnschnitt: kleine Klötzchen unter der Kehle
	for i in 40:
		var x := -3.9 + 0.2 * i
		_box(gesims, "Zahn%d" % i, Vector3(0.09, 0.03, 0.03), Vector3(x, WAND_OBEN - 0.03, 0.125), hell)

	# --- Bretter mit Konsolen -----------------------------------------------
	var bretter := _gruppe(root, "Bretter")
	for i in BRETTER.size():
		var oben: float = BRETTER[i]
		var b := _gruppe(bretter, "Brett%d" % (i + 1))
		_box(b, "Brett", Vector3(7.9, 0.04, 0.34), Vector3(0, oben - 0.02, -0.16), hell)
		_box(b, "Vorderleiste", Vector3(7.9, 0.035, 0.02), Vector3(0, oben + 0.0175, 0.0), hell)
		_box(b, "Unterleiste", Vector3(7.9, 0.03, 0.02), Vector3(0, oben - 0.055, 0.0), dunkel)
		for k in 5:
			var x := -3.2 + 1.6 * k
			var kn := _gruppe(b, "Konsole%d" % (k + 1), Vector3(x, oben - 0.04, 0))
			_box(kn, "Wandplatte", Vector3(0.05, 0.13, 0.02), Vector3(0, -0.065, -0.295), dunkel)
			_box(kn, "Strebe", Vector3(0.045, 0.17, 0.03), Vector3(0, -0.06, -0.19), dunkel, Vector3(-52, 0, 0))
			_box(kn, "Auflage", Vector3(0.05, 0.025, 0.24), Vector3(0, -0.0125, -0.17), dunkel)

	# --- Körper: Kollision nur für den Unterschrank ----------------------------
	var body := StaticBody3D.new()
	_haengen(root, body, "Body")
	var f := BoxShape3D.new()
	f.size = Vector3(8.16, PLATTE_OBEN, 0.80)
	var cs := CollisionShape3D.new()
	cs.shape = f
	cs.position = Vector3(0, PLATTE_OBEN / 2.0, 0.02)
	_haengen(body, cs, "CollisionShape3D")

	# --- Krüge auf den Brettern -------------------------------------------------
	var glaeser := _gruppe(root, "Glaeser")
	for i in BRETTER.size():
		var reihe_name := "Reihe%d" % (i + 1)
		var r := _gruppe(glaeser, reihe_name, Vector3(0, BRETTER[i], -0.16))
		var xs: Array = reihen.get(reihe_name, [])
		for j in xs.size():
			var k := (load(KRUG) as PackedScene).instantiate() as Node3D
			k.position = Vector3(float(xs[j]), 0, 0)
			k.set("fuellung", 0.0)
			_haengen(r, k, "K%d" % (j + 1))
	return root
