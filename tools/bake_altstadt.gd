extends SceneTree
## Altstadt-Kulisse rund um das Fest (ersetzt das Low-Poly-Bergterrain des Kirmes-Pakets):
##   Wiese, Stadtmauer mit Toren und Wehrtürmen, Reihen bayerischer Bürgerhäuser am Hang
##   (Giebel-, Trauf- und Treppengiebelhäuser, Fachwerk, Läden, Blumenkästen, Balkone,
##   Gauben, Markisen), Kirchtürme mit Zwiebelhauben, Frauenkirche, Rathaus, Maibäume, Wald.
##   Die Alpen dahinter malt der Himmel (assets/sky/wolken_himmel.gdshader).
## Ein Material (assets/altstadt/altstadt.tres): Oberflächenart in UV.x, Maße in UV2.
##
## ACHTUNG: überschreibt scenes/kulisse/altstadt.tscn und assets/altstadt/meshes/.
## Feinschliff (Wahrzeichen verschieben usw.) danach im Editor.
##   godot --headless --path . --script tools/bake_altstadt.gd

const MESH_DIR := "res://assets/altstadt/meshes/"
const SZENE := "res://scenes/kulisse/altstadt.tscn"
const MITTE := Vector3(0, 0, -8)
const MAUER_R := 100.0
const HANG_START := 104.0
const HANG := 0.22
const HANG_MAX := 38.0
const SEKTOREN := 16
const TORE := [0.0, PI]

const PUTZ := [Color(0.94, 0.89, 0.76), Color(0.9, 0.76, 0.5), Color(0.92, 0.74, 0.68),
	Color(0.78, 0.84, 0.86), Color(0.76, 0.86, 0.74), Color(0.97, 0.95, 0.9),
	Color(0.96, 0.86, 0.55), Color(0.93, 0.66, 0.52), Color(0.86, 0.82, 0.9), Color(0.97, 0.93, 0.82)]
const DACH := [Color(0.62, 0.27, 0.18), Color(0.54, 0.22, 0.15), Color(0.68, 0.34, 0.21),
	Color(0.46, 0.27, 0.19), Color(0.36, 0.37, 0.4), Color(0.6, 0.3, 0.2)]
const LADEN := [Color(0.2, 0.4, 0.26), Color(0.52, 0.17, 0.15), Color(0.38, 0.25, 0.15),
	Color(0.26, 0.37, 0.52), Color(0.9, 0.9, 0.86)]
const BLUETEN := [Color(0.85, 0.1, 0.12), Color(0.95, 0.35, 0.55), Color(0.9, 0.2, 0.2)]
const MARKISE := [Color(0.72, 0.12, 0.12), Color(0.15, 0.35, 0.65), Color(0.2, 0.45, 0.25)]
const ZUNFT := [Color(0.9, 0.9, 0.85), Color(0.1, 0.34, 0.72), Color(0.85, 0.7, 0.3), Color(0.7, 0.15, 0.12)]
const HOLZ := Color(0.36, 0.23, 0.14)
const BALKEN := Color(0.27, 0.16, 0.09)
const STEIN := Color(0.6, 0.56, 0.5)
const STEIN_HELL := Color(0.8, 0.76, 0.68)
const RAHMEN := Color(0.93, 0.92, 0.88)
const GLAS := Color(0.12, 0.15, 0.2)
const KUPFER := Color(0.36, 0.6, 0.5)
const GOLD := Color(0.95, 0.74, 0.32)
const ZIEGELROT := Color(0.66, 0.37, 0.27)
const WIESE := Color(0.33, 0.42, 0.21)
const PFLASTER := Color(0.56, 0.53, 0.48)
const LAUB := Color(0.22, 0.38, 0.17)
const NADEL := Color(0.14, 0.27, 0.16)
const FELDER := [Color(0.33, 0.42, 0.21), Color(0.42, 0.48, 0.22), Color(0.62, 0.56, 0.3),
	Color(0.28, 0.38, 0.2), Color(0.5, 0.5, 0.26)]

var rng := RandomNumberGenerator.new()
var laerm := FastNoiseLite.new()
var mat: Material
var _st: SurfaceTool
var _t := Transform3D.IDENTITY
var _sektoren := {}
var _belegt: Array = []   # [Vector2 Mitte, Radius]

func _init() -> void:
	rng.seed = 1810
	laerm.seed = 4
	laerm.frequency = 0.006
	mat = load("res://assets/altstadt/altstadt.tres")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/kulisse/"))
	var wurzel := Node3D.new()
	wurzel.name = "Altstadt"

	# Boden
	_st = _neu()
	_t = Transform3D.IDENTITY
	_boden()
	_knoten(wurzel, wurzel, "Boden", _speichern(_st, "boden"), Transform3D.IDENTITY)

	# Stadtmauer
	_st = _neu()
	_stadtmauer()
	_t = Transform3D.IDENTITY
	_knoten(wurzel, wurzel, "Stadtmauer", _speichern(_st, "stadtmauer"), Transform3D.IDENTITY)

	# Wahrzeichen (eigene Knoten, im Editor verschiebbar)
	var wz := Node3D.new()
	wz.name = "Wahrzeichen"
	wurzel.add_child(wz)
	wz.owner = wurzel
	_wahrzeichen(wurzel, wz, "Frauenkirche", PI + 0.32, 158.0, 30.0, 24.0, func() -> void: _frauenkirche())
	_wahrzeichen(wurzel, wz, "Rathaus", -0.55, 150.0, 16.0, 6.0, func() -> void: _rathaus())
	_wahrzeichen(wurzel, wz, "Kirchturm1", PI - 0.45, 132.0, 8.0, 0.0, func() -> void: _turm(6.5, 38.0, "zwiebel", Color(0.95, 0.9, 0.78), 0))
	_wahrzeichen(wurzel, wz, "Kirchturm2", 0.85, 146.0, 8.0, 0.0, func() -> void: _turm(6.0, 34.0, "zwiebel", Color(0.96, 0.86, 0.6), 0))
	_wahrzeichen(wurzel, wz, "Kirchturm3", -1.75, 128.0, 8.0, 0.0, func() -> void: _turm(6.0, 32.0, "zwiebel", Color(0.93, 0.93, 0.9), 0))
	_wahrzeichen(wurzel, wz, "Kirchturm4", PI - 0.1, 196.0, 9.0, 0.0, func() -> void: _turm(7.0, 46.0, "spitz", Color(0.9, 0.84, 0.72), 0))
	_wahrzeichen(wurzel, wz, "Kirchturm5", 2.3, 184.0, 9.0, 0.0, func() -> void: _turm(7.0, 40.0, "zwiebel", Color(0.95, 0.9, 0.8), 0))
	_wahrzeichen(wurzel, wz, "Kirchturm6", -2.45, 204.0, 8.0, 0.0, func() -> void: _turm(6.5, 36.0, "zwiebel", Color(0.92, 0.8, 0.7), 0))
	_wahrzeichen(wurzel, wz, "Kirchturm7", 1.6, 122.0, 7.0, 0.0, func() -> void: _turm(5.5, 30.0, "spitz", Color(0.95, 0.93, 0.86), 0))
	_wahrzeichen(wurzel, wz, "StadttorNord", 0.0, MAUER_R, 16.0, 0.0, func() -> void: _stadttor())
	_wahrzeichen(wurzel, wz, "StadttorSued", PI, MAUER_R, 16.0, 0.0, func() -> void: _stadttor())
	_wahrzeichen(wurzel, wz, "Maibaum1", 0.24, 90.0, 3.0, 0.0, func() -> void: _maibaum())
	_wahrzeichen(wurzel, wz, "Maibaum2", PI - 0.9, 150.0, 5.0, 0.0, func() -> void: _maibaum())

	# Häuserreihen und Bäume, nach Himmelsrichtung in Viertel zusammengefasst
	_haeuser()
	_baeume()
	var viertel := Node3D.new()
	viertel.name = "Viertel"
	wurzel.add_child(viertel)
	viertel.owner = wurzel
	for i in SEKTOREN:
		if _sektoren.has(i):
			_knoten(wurzel, viertel, "Viertel%02d" % i, _speichern(_sektoren[i], "viertel_%02d" % i), Transform3D.IDENTITY)

	var ps := PackedScene.new()
	ps.pack(wurzel)
	ResourceSaver.save(ps, SZENE)
	print("BAKE FERTIG")
	quit()

# ------------------------------------------------------------------ Hilfen

func hoehe(r: float) -> float:
	return clampf((r - HANG_START) * HANG, 0.0, HANG_MAX)

func polar(a: float, r: float) -> Vector3:
	return MITTE + Vector3(sin(a) * r, hoehe(r), cos(a) * r)

func _neu() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

func _speichern(st: SurfaceTool, name: String) -> ArrayMesh:
	st.index()
	var m := st.commit()
	m.surface_set_material(0, mat)
	var pfad := MESH_DIR + name + ".res"
	ResourceSaver.save(m, pfad, ResourceSaver.FLAG_COMPRESS)
	m.take_over_path(pfad)
	print("  Mesh ", name, "  Dreiecke: ", m.surface_get_array_index_len(0) / 3)
	return m

func _knoten(wurzel: Node, eltern: Node, name: String, mesh: Mesh, xf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	eltern.add_child(mi)
	mi.owner = wurzel
	return mi

func _wahrzeichen(wurzel: Node, eltern: Node, name: String, a: float, r: float, radius: float, tiefe: float, bau: Callable) -> void:
	var p := polar(a, r)
	var hinten := polar(a, r + tiefe)
	_belegt.append([Vector2(hinten.x, hinten.z), radius])
	_st = _neu()
	_t = Transform3D.IDENTITY
	bau.call()
	_t = Transform3D.IDENTITY
	_knoten(wurzel, eltern, name, _speichern(_st, name.to_lower()), Transform3D(Basis(Vector3.UP, a + PI), p))

func _frei(p: Vector3, radius: float) -> bool:
	for b: Array in _belegt:
		if Vector2(p.x, p.z).distance_to(b[0]) < float(b[1]) + radius:
			return false
	return true

func _nahe_tor(a: float, breite: float) -> bool:
	for t: float in TORE:
		if absf(angle_difference(a, t)) < breite:
			return true
	return false

func _sektor(a: float) -> SurfaceTool:
	var i := posmod(floori(fposmod(a, TAU) / TAU * SEKTOREN), SEKTOREN)
	if not _sektoren.has(i):
		_sektoren[i] = _neu()
	return _sektoren[i]

func _farbe(liste: Array) -> Color:
	return liste[rng.randi() % liste.size()]

func _jitter(c: Color, s := 0.05) -> Color:
	return Color(c.r * rng.randf_range(1.0 - s, 1.0 + s), c.g * rng.randf_range(1.0 - s, 1.0 + s), c.b * rng.randf_range(1.0 - s, 1.0 + s))

# ------------------------------------------------------------------ Geometrie

func _v(p: Vector3, n: Vector3, farbe: Color, art: int, uv2: Vector2) -> void:
	_st.set_color(farbe.srgb_to_linear())
	_st.set_uv(Vector2(art, 0))
	_st.set_uv2(uv2)
	_st.set_normal(n)
	_st.add_vertex(p)

## Dreieck mit Normalen; Reihenfolge wird so gedreht, dass die Vorderseite nach außen zeigt.
func _dreieck(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
		farbe: Color, art: int, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var pa := _t * a
	var pb := _t * b
	var pc := _t * c
	var ma := (_t.basis * na).normalized()
	var mb := (_t.basis * nb).normalized()
	var mc := (_t.basis * nc).normalized()
	if (pb - pa).cross(pc - pa).dot(ma + mb + mc) > 0.0:
		_v(pa, ma, farbe, art, ua)
		_v(pc, mc, farbe, art, uc)
		_v(pb, mb, farbe, art, ub)
	else:
		_v(pa, ma, farbe, art, ua)
		_v(pb, mb, farbe, art, ub)
		_v(pc, mc, farbe, art, uc)

func _dreieck_flach(a: Vector3, b: Vector3, c: Vector3, farbe: Color, art: int, hinweis: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.dot(hinweis) < 0.0:
		n = -n
	_dreieck(a, b, c, n, n, n, farbe, art, ua, ub, uc)

## Viereck a-b-c-d (umlaufend). UV2: Kante a→b = x, a→d = y (in Metern ab uv0) oder 0…1.
func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, farbe: Color, art: int, hinweis: Vector3,
		uv0 := Vector2.ZERO, normiert := false) -> void:
	var n := (b - a).cross(d - a)
	if n.length_squared() < 1e-10:
		n = (c - b).cross(d - b)
	if n.length_squared() < 1e-10:
		n = hinweis
	n = n.normalized()
	if n.dot(hinweis) < 0.0:
		n = -n
	var ua := Vector2(0, 0)
	var ub := Vector2(1, 0)
	var uc := Vector2(1, 1)
	var ud := Vector2(0, 1)
	if not normiert:
		var la := (b - a).length()
		var ld := (d - a).length()
		ua = uv0
		ub = uv0 + Vector2(la, 0)
		uc = uv0 + Vector2(la, ld)
		ud = uv0 + Vector2(0, ld)
	_dreieck(a, b, c, n, n, n, farbe, art, ua, ub, uc)
	_dreieck(a, c, d, n, n, n, farbe, art, ua, uc, ud)

## Rechteck auf einer senkrechten Fläche: unten-Mitte, Normale, Breite, Höhe, Abstand vor der Fläche.
func _flaeche(unten: Vector3, n: Vector3, bw: float, bh: float, farbe: Color, art: int, abstand: float, normiert := false) -> void:
	var r := Vector3.UP.cross(n).normalized()
	var p := unten + n * abstand
	var a := p - r * bw * 0.5
	var b := p + r * bw * 0.5
	_quad(a, b, b + Vector3.UP * bh, a + Vector3.UP * bh, farbe, art, n, Vector2(0, unten.y), normiert)

## Quader (Seiten-Bits: 1 oben, 2 unten, 4 +z, 8 -z, 16 +x, 32 -x)
func _kiste(m: Vector3, g: Vector3, farbe: Color, art: int, seiten := 61) -> void:
	var h := g * 0.5
	var y0 := Vector2(0, m.y - h.y)
	if seiten & 1:
		_quad(m + Vector3(-h.x, h.y, h.z), m + Vector3(h.x, h.y, h.z), m + Vector3(h.x, h.y, -h.z), m + Vector3(-h.x, h.y, -h.z), farbe, art, Vector3.UP)
	if seiten & 2:
		_quad(m + Vector3(-h.x, -h.y, -h.z), m + Vector3(h.x, -h.y, -h.z), m + Vector3(h.x, -h.y, h.z), m + Vector3(-h.x, -h.y, h.z), farbe, art, Vector3.DOWN)
	if seiten & 4:
		_quad(m + Vector3(-h.x, -h.y, h.z), m + Vector3(h.x, -h.y, h.z), m + Vector3(h.x, h.y, h.z), m + Vector3(-h.x, h.y, h.z), farbe, art, Vector3.BACK, y0)
	if seiten & 8:
		_quad(m + Vector3(h.x, -h.y, -h.z), m + Vector3(-h.x, -h.y, -h.z), m + Vector3(-h.x, h.y, -h.z), m + Vector3(h.x, h.y, -h.z), farbe, art, Vector3.FORWARD, y0)
	if seiten & 16:
		_quad(m + Vector3(h.x, -h.y, h.z), m + Vector3(h.x, -h.y, -h.z), m + Vector3(h.x, h.y, -h.z), m + Vector3(h.x, h.y, h.z), farbe, art, Vector3.RIGHT, y0)
	if seiten & 32:
		_quad(m + Vector3(-h.x, -h.y, -h.z), m + Vector3(-h.x, -h.y, h.z), m + Vector3(-h.x, h.y, h.z), m + Vector3(-h.x, h.y, -h.z), farbe, art, Vector3.LEFT, y0)

## Drehkörper um die senkrechte Achse; Profil = Punkte (Radius, Höhe) von unten nach oben.
func _drehkoerper(m: Vector3, profil: Array, seg: int, farbe: Color, art: int) -> void:
	for i in profil.size() - 1:
		var p0: Vector2 = profil[i]
		var p1: Vector2 = profil[i + 1]
		var e := p1 - p0
		var n2 := Vector2(e.y, -e.x).normalized()
		for j in seg:
			var a0 := TAU * j / seg
			var a1 := TAU * (j + 1) / seg
			var q00 := m + Vector3(cos(a0) * p0.x, p0.y, sin(a0) * p0.x)
			var q10 := m + Vector3(cos(a1) * p0.x, p0.y, sin(a1) * p0.x)
			var q01 := m + Vector3(cos(a0) * p1.x, p1.y, sin(a0) * p1.x)
			var q11 := m + Vector3(cos(a1) * p1.x, p1.y, sin(a1) * p1.x)
			var n0 := Vector3(cos(a0) * n2.x, n2.y, sin(a0) * n2.x)
			var n1 := Vector3(cos(a1) * n2.x, n2.y, sin(a1) * n2.x)
			var u0 := a0 * maxf(p0.x, p1.x)
			var u1 := a1 * maxf(p0.x, p1.x)
			var l := e.length()
			var y := m.y + p0.y
			_dreieck(q00, q10, q11, n0, n1, n1, farbe, art, Vector2(u0, y), Vector2(u1, y), Vector2(u1, y + l))
			_dreieck(q00, q11, q01, n0, n1, n0, farbe, art, Vector2(u0, y), Vector2(u1, y + l), Vector2(u0, y + l))

func _balken(p0: Vector3, p1: Vector3, t: float, n := Vector3.BACK) -> void:
	var dir := (p1 - p0).normalized()
	var quer := n.cross(dir) * t * 0.5
	var o := n * 0.03
	_quad(p0 - quer + o, p1 - quer + o, p1 + quer + o, p0 + quer + o, BALKEN, 2, n)

func _pyramide(m: Vector3, halb: float, h: float, farbe: Color, art: int) -> void:
	var top := m + Vector3(0, h, 0)
	var ecken := [m + Vector3(-halb, 0, halb), m + Vector3(halb, 0, halb), m + Vector3(halb, 0, -halb), m + Vector3(-halb, 0, -halb)]
	for i in 4:
		var a: Vector3 = ecken[i]
		var b: Vector3 = ecken[(i + 1) % 4]
		var mitte := (a + b) * 0.5
		var raus := Vector3(mitte.x - m.x, 0, mitte.z - m.z).normalized() + Vector3.UP * 0.4
		var l := a.distance_to(b)
		var sl := mitte.distance_to(top)
		_dreieck_flach(a, b, top, farbe, art, raus, Vector2(0, 0), Vector2(l, 0), Vector2(l * 0.5, sl))

func _spitze_gold(p: Vector3, l: float) -> void:
	_drehkoerper(p, [Vector2(0.12, 0.0), Vector2(0.05, l)], 6, GOLD, 6)
	var kugel := []
	for i in 7:
		var w := -PI * 0.5 + PI * i / 6.0
		kugel.append(Vector2(cos(w) * 0.32, sin(w) * 0.32 + 0.32))
	_drehkoerper(p + Vector3(0, l, 0), kugel, 8, GOLD, 6)
	_kiste(p + Vector3(0, l + 1.2, 0), Vector3(0.09, 1.1, 0.09), GOLD, 6)
	_kiste(p + Vector3(0, l + 1.35, 0), Vector3(0.6, 0.09, 0.09), GOLD, 6)

# ------------------------------------------------------------------ Boden

func _bodenpunkt(a: float, r: float) -> Vector3:
	var p := MITTE + Vector3(sin(a) * r, 0, cos(a) * r)
	p.y = hoehe(r) - 0.08
	if r > 250.0:
		p.y += laerm.get_noise_2d(p.x, p.z) * 16.0 * smoothstep(250.0, 420.0, r)
	return p

func _boden() -> void:
	var ringe: Array[float] = [0.0, 60.0, 88.0, 93.5, 98.0, 104.0]
	var r := 104.0
	while r < 290.0:
		r += 12.0
		ringe.append(r)
	ringe.append_array([330.0, 380.0, 440.0, 520.0, 620.0, 760.0, 950.0, 1200.0, 1600.0])
	var seg := 160
	for i in ringe.size() - 1:
		var r0 := ringe[i]
		var r1 := ringe[i + 1]
		var weg := r0 >= 93.5 and r1 <= 98.0
		var stadt := r0 >= 104.0 and r1 <= 242.0
		for j in seg:
			var a0 := TAU * j / seg
			var a1 := TAU * (j + 1) / seg
			var farbe := WIESE
			var art := 7
			if weg or stadt:
				farbe = PFLASTER if weg else PFLASTER * 0.92
				art = 9
			elif r0 >= 290.0:
				farbe = FELDER[int(absf(sin(float(i * 91 + j * 13)) * 1000.0)) % FELDER.size()]
			_quad(_bodenpunkt(a0, r0), _bodenpunkt(a1, r0), _bodenpunkt(a1, r1), _bodenpunkt(a0, r1), farbe, art, Vector3.UP)

# ------------------------------------------------------------------ Häuser

func _haeuser() -> void:
	var reihen := [110.0, 124.5, 140.0, 156.5, 174.0, 192.5, 212.0]
	for ri in reihen.size():
		var r: float = reihen[ri]
		var a := rng.randf() * 0.05
		while a < TAU - 0.03:
			var w := rng.randf_range(7.0, 12.0)
			var d := rng.randf_range(9.0, 13.0)
			var luecke := rng.randf_range(0.3, 1.4)
			if rng.randf() < 0.1:
				luecke += 6.0   # Gasse
			var ac := a + (w * 0.5) / r
			a += (w + luecke) / r
			if absf(angle_difference(ac, 0.0)) * r < 10.0 or absf(angle_difference(ac, PI)) * r < 10.0:
				continue
			var rr := r + rng.randf_range(-1.0, 1.0)
			var p := polar(ac, rr)
			if not _frei(p, maxf(w, d) * 0.55):
				continue
			var stock := rng.randi_range(2, 3) if ri == 0 else rng.randi_range(3, 4)
			_st = _sektor(ac)
			_t = Transform3D(Basis(Vector3.UP, ac + PI), p)
			_haus(w, d, stock)
	_t = Transform3D.IDENTITY

func _haus(w: float, d: float, stock: int) -> void:
	const FH := 2.9
	var sockel := 0.7
	var wand := sockel + stock * FH
	var fachwerk := rng.randf() < 0.25
	var putz := Color(0.95, 0.93, 0.86) if fachwerk else _jitter(_farbe(PUTZ))
	var dach := _jitter(_farbe(DACH), 0.06)
	var laden := rng.randf() < 0.6
	var ladenfarbe := _farbe(LADEN)
	var blumen := rng.randf() < 0.55
	var tief := d * 0.5 * HANG + 1.2
	var form := rng.randf()
	var giebelart := 0 if form < 0.5 else (1 if form < 0.85 else 2)   # 0 Giebel, 1 Traufe, 2 Treppengiebel
	_kiste(Vector3(0, (sockel - tief) * 0.5, 0), Vector3(w + 0.12, sockel + tief, d + 0.12), STEIN, 4)
	_kiste(Vector3(0, sockel + (wand - sockel) * 0.5, 0), Vector3(w, wand - sockel, d), putz, 0, 60)

	var spalten := maxi(1, int((w - 0.8) / 1.75))
	var abstand := w / spalten
	var tuer_spalte := spalten / 2
	var schaufenster := rng.randf() < 0.25 and spalten >= 3
	if fachwerk and stock > 1:
		_fachwerk(w, d, stock, sockel, FH, spalten, abstand)
	for f in stock:
		for i in spalten:
			var x := -w * 0.5 + abstand * (i + 0.5)
			if f == 0 and i == tuer_spalte:
				_tuer(Vector3(x, 0.2, d * 0.5))
				continue
			if f == 0 and schaufenster:
				_flaeche(Vector3(x, sockel + 0.15, d * 0.5), Vector3.BACK, abstand - 0.35, 1.95, HOLZ * 0.7, 2, 0.03)
				_flaeche(Vector3(x, sockel + 0.3, d * 0.5), Vector3.BACK, abstand - 0.65, 1.65, GLAS, 3, 0.05, true)
				continue
			_fenster(Vector3(x, sockel + f * FH + 0.8, d * 0.5), Vector3.BACK, 0.85, 1.35, laden, ladenfarbe, blumen and f > 0)
	if schaufenster:
		var mf := _farbe(MARKISE)
		var y1 := sockel + 2.6
		var a := Vector3(-w * 0.5 + 0.3, y1, d * 0.5 + 0.02)
		var b := Vector3(w * 0.5 - 0.3, y1, d * 0.5 + 0.02)
		var c := Vector3(w * 0.5 - 0.3, y1 - 0.6, d * 0.5 + 1.4)
		var e := Vector3(-w * 0.5 + 0.3, y1 - 0.6, d * 0.5 + 1.4)
		_quad(a, b, c, e, mf, 14, Vector3(0, 1, 1))
		_quad(a, b, c, e, mf, 14, Vector3(0, -1, -1))
		_quad(e, c, c - Vector3(0, 0.3, 0), e - Vector3(0, 0.3, 0), mf, 14, Vector3.BACK)
	# Seitenfenster
	var sspalten := int((d - 1.5) / 2.4)
	if sspalten > 0 and rng.randf() < 0.6:
		for s: float in [-1.0, 1.0]:
			for f in stock:
				for i in sspalten:
					var z := -d * 0.5 + (d / sspalten) * (i + 0.5)
					_fenster(Vector3(s * w * 0.5, sockel + f * FH + 0.8, z), Vector3(s, 0, 0), 0.8, 1.3, laden, ladenfarbe, false)

	match giebelart:
		0:
			var rh := w * 0.5 * rng.randf_range(0.95, 1.3)
			_satteldach_z(w, d, wand, rh, dach, putz, 0.45, true)
			if fachwerk:
				_balken(Vector3(0, wand, d * 0.5), Vector3(0, wand + rh, d * 0.5), 0.2)
				var yk := wand + rh * 0.45
				var xk := w * 0.5 * 0.55
				_balken(Vector3(-xk, yk, d * 0.5), Vector3(xk, yk, d * 0.5), 0.18)
			if rng.randf() < 0.35:
				_balkon(w, d, wand)
			elif rh > 2.6:
				_fenster(Vector3(0, wand + 0.45, d * 0.5), Vector3.BACK, 0.75, 1.1, laden, ladenfarbe, blumen)
			if rh > 4.2:
				_fenster(Vector3(0, wand + rh * 0.62, d * 0.5), Vector3.BACK, 0.5, 0.7, false, ladenfarbe, false)
		1:
			var rh := d * 0.5 * rng.randf_range(0.8, 1.05)
			_satteldach_x(w, d, wand, rh, dach, putz)
			var k := rh / (d * 0.5)
			var gauben := 1 if w < 9.0 else 2
			for g in gauben:
				var gx := 0.0 if gauben == 1 else (-w * 0.25 if g == 0 else w * 0.25)
				_gaube(gx, d * 0.5 - 0.9, wand + k * 0.9, putz, dach)
		2:
			var rh := w * 0.5 * rng.randf_range(1.0, 1.3)
			_satteldach_z(w, d, wand, rh, dach, putz, -0.5, false)
			var n := 4
			var sh := (rh + 1.2) / n
			for s in n:
				var bw := w * float(n - s) / n
				_kiste(Vector3(0, wand + sh * (s + 0.5), d * 0.5 - 0.23), Vector3(bw, sh, 0.5), putz, 0, 61 - 1)
				_kiste(Vector3(0, wand + sh * (s + 1) + 0.06, d * 0.5 - 0.23), Vector3(bw + 0.14, 0.12, 0.62), STEIN_HELL, 4)
			_fenster(Vector3(0, wand + 0.5, d * 0.5 + 0.02), Vector3.BACK, 0.8, 1.2, laden, ladenfarbe, false)
	# Kamin
	if rng.randf() < 0.6:
		var kx := rng.randf_range(-w * 0.2, w * 0.2)
		var kz := rng.randf_range(-d * 0.3, d * 0.2)
		_kiste(Vector3(kx, wand + w * 0.3 + 0.6, kz), Vector3(0.6, w * 0.6 + 1.6, 0.6), ZIEGELROT, 11)
		_kiste(Vector3(kx, wand + w * 0.6 + 1.45, kz), Vector3(0.8, 0.12, 0.8), STEIN, 4)

func _satteldach_z(w: float, d: float, wand: float, rh: float, dach: Color, giebelfarbe: Color, ueber_vorn: float, giebel_vorn: bool) -> void:
	var o := 0.45
	var k := rh / (w * 0.5)
	var ye := wand - o * k
	var yr := wand + rh
	var xa := w * 0.5 + o
	var zf := d * 0.5 + ueber_vorn
	var zb := -d * 0.5 - o
	for s: float in [-1.0, 1.0]:
		var a := Vector3(s * xa, ye, zf)
		var b := Vector3(s * xa, ye, zb)
		var c := Vector3(0, yr, zb)
		var e := Vector3(0, yr, zf)
		_quad(a, b, c, e, dach, 1, Vector3(s, 1, 0))
		var u := Vector3(0, -0.14, 0)
		_quad(a + u, b + u, c + u, e + u, HOLZ * 0.75, 2, Vector3(-s, -1, 0))
		for zz: float in [zf, zb]:
			_quad(Vector3(s * xa, ye - 0.3, zz), Vector3(0, yr - 0.3, zz), Vector3(0, yr, zz), Vector3(s * xa, ye, zz), HOLZ, 2, Vector3(0, 0, signf(zz)))
		_quad(Vector3(s * xa, ye - 0.3, zf), Vector3(s * xa, ye - 0.3, zb), Vector3(s * xa, ye, zb), Vector3(s * xa, ye, zf), HOLZ, 2, Vector3(s, 0, 0))
	_kiste(Vector3(0, yr + 0.06, (zf + zb) * 0.5), Vector3(0.34, 0.2, zf - zb), dach * 0.8, 1)
	for zz: float in [d * 0.5, -d * 0.5]:
		if zz > 0.0 and not giebel_vorn:
			continue
		_dreieck_flach(Vector3(-w * 0.5, wand, zz), Vector3(w * 0.5, wand, zz), Vector3(0, yr, zz), giebelfarbe, 0,
			Vector3(0, 0, signf(zz)), Vector2(0, wand), Vector2(w, wand), Vector2(w * 0.5, yr))

func _satteldach_x(w: float, d: float, wand: float, rh: float, dach: Color, giebelfarbe: Color) -> void:
	var o := 0.45
	var k := rh / (d * 0.5)
	var ye := wand - o * k
	var yr := wand + rh
	var za := d * 0.5 + o
	var xa := w * 0.5 + o
	for s: float in [-1.0, 1.0]:
		var a := Vector3(-xa, ye, s * za)
		var b := Vector3(xa, ye, s * za)
		var c := Vector3(xa, yr, 0)
		var e := Vector3(-xa, yr, 0)
		_quad(a, b, c, e, dach, 1, Vector3(0, 1, s))
		var u := Vector3(0, -0.14, 0)
		_quad(a + u, b + u, c + u, e + u, HOLZ * 0.75, 2, Vector3(0, -1, -s))
		for xx: float in [-xa, xa]:
			_quad(Vector3(xx, ye - 0.3, s * za), Vector3(xx, yr - 0.3, 0), Vector3(xx, yr, 0), Vector3(xx, ye, s * za), HOLZ, 2, Vector3(signf(xx), 0, 0))
		_quad(Vector3(-xa, ye - 0.28, s * za), Vector3(xa, ye - 0.28, s * za), Vector3(xa, ye, s * za), Vector3(-xa, ye, s * za), HOLZ, 2, Vector3(0, 0, s))
	_kiste(Vector3(0, yr + 0.06, 0), Vector3(xa * 2.0, 0.2, 0.34), dach * 0.8, 1)
	for xx: float in [w * 0.5, -w * 0.5]:
		_dreieck_flach(Vector3(xx, wand, d * 0.5), Vector3(xx, wand, -d * 0.5), Vector3(xx, yr, 0), giebelfarbe, 0,
			Vector3(signf(xx), 0, 0), Vector2(0, wand), Vector2(d, wand), Vector2(d * 0.5, yr))

func _gaube(x: float, zg: float, yb: float, putz: Color, dach: Color) -> void:
	var gw := 1.5
	_kiste(Vector3(x, yb + 0.7, zg - 1.0), Vector3(gw, 1.8, 2.0), putz, 0, 4 | 16 | 32)
	_fenster(Vector3(x, yb + 0.2, zg), Vector3.BACK, 0.8, 0.95, false, HOLZ, false)
	var gy := yb + 1.6
	var gr := gy + 0.75
	for s: float in [-1.0, 1.0]:
		var ax := x + s * (gw * 0.5 + 0.2)
		_quad(Vector3(ax, gy - 0.1, zg + 0.25), Vector3(ax, gy - 0.1, zg - 2.4), Vector3(x, gr, zg - 2.4), Vector3(x, gr, zg + 0.25), dach, 1, Vector3(s, 1, 0))
	_dreieck_flach(Vector3(x - gw * 0.5, gy, zg), Vector3(x + gw * 0.5, gy, zg), Vector3(x, gr - 0.05, zg), putz, 0, Vector3.BACK,
		Vector2(0, gy), Vector2(gw, gy), Vector2(gw * 0.5, gr))

func _fenster(p: Vector3, n: Vector3, bw: float, bh: float, laden: bool, ladenfarbe: Color, blumen: bool) -> void:
	var r := Vector3.UP.cross(n).normalized()
	_flaeche(p - Vector3(0, 0.1, 0), n, bw + 0.24, bh + 0.2, RAHMEN, 0, 0.035)
	_flaeche(p, n, bw, bh, GLAS, 3, 0.05, true)
	if laden:
		for s: float in [-1.0, 1.0]:
			_flaeche(p + r * s * (bw * 0.5 + 0.36), n, 0.46, bh + 0.05, ladenfarbe, 13, 0.06)
	if blumen:
		var groesse := Vector3(bw + 0.4, 0.26, 0.34) if absf(n.z) > 0.5 else Vector3(0.34, 0.26, bw + 0.4)
		var m := p + n * 0.22 + Vector3(0, -0.2, 0)
		_kiste(m, groesse, HOLZ, 2)
		_kiste(m + Vector3(0, 0.22, 0), groesse * Vector3(0.95, 0.9, 0.95), _farbe(BLUETEN), 12)

func _tuer(p: Vector3) -> void:
	_kiste(Vector3(p.x, -0.7, p.z + 0.55), Vector3(2.0, 1.8, 1.1), STEIN, 4)
	_flaeche(p + Vector3(0, -0.05, 0), Vector3.BACK, 1.65, 2.75, STEIN_HELL, 4, 0.09)
	_flaeche(p, Vector3.BACK, 1.2, 2.5, _jitter(Color(0.42, 0.26, 0.15)), 13, 0.11)

func _balkon(w: float, d: float, wand: float) -> void:
	var bw := w * 0.8
	var z := d * 0.5
	_kiste(Vector3(0, wand - 0.1, z + 0.6), Vector3(bw, 0.22, 1.2), HOLZ, 2, 61 | 2)
	_kiste(Vector3(0, wand + 0.45, z + 1.17), Vector3(bw, 0.9, 0.08), HOLZ, 17)
	for s: float in [-1.0, 1.0]:
		_kiste(Vector3(s * bw * 0.5, wand + 0.45, z + 0.6), Vector3(0.08, 0.9, 1.1), HOLZ, 17)
	_kiste(Vector3(0, wand + 1.02, z + 1.25), Vector3(bw, 0.26, 0.3), HOLZ, 2)
	_kiste(Vector3(0, wand + 1.24, z + 1.25), Vector3(bw * 0.97, 0.24, 0.28), _farbe(BLUETEN), 12)
	_flaeche(Vector3(0, wand, z), Vector3.BACK, 1.0, 2.1, GLAS, 3, 0.05, true)

func _fachwerk(w: float, d: float, stock: int, sockel: float, fh: float, spalten: int, abstand: float) -> void:
	var z := d * 0.5
	var y_unten := sockel + fh
	var y_oben := sockel + stock * fh
	for f in range(1, stock + 1):
		var y := sockel + f * fh
		_balken(Vector3(-w * 0.5, y - 0.1, z), Vector3(w * 0.5, y - 0.1, z), 0.22)
	for x: float in [-w * 0.5 + 0.12, w * 0.5 - 0.12]:
		_balken(Vector3(x, y_unten, z), Vector3(x, y_oben, z), 0.22)
	for i in range(1, spalten):
		var x := -w * 0.5 + abstand * i
		_balken(Vector3(x, y_unten, z), Vector3(x, y_oben, z), 0.18)
	for f in range(1, stock):
		var y0 := sockel + f * fh + 0.05
		for i in spalten:
			var xc := -w * 0.5 + abstand * (i + 0.5)
			_balken(Vector3(xc - 0.55, y0, z), Vector3(xc + 0.55, y0 + 0.65, z), 0.13)
			_balken(Vector3(xc + 0.55, y0, z), Vector3(xc - 0.55, y0 + 0.65, z), 0.13)

# ------------------------------------------------------------------ Wahrzeichen

func _turm(w: float, h: float, spitze: String, farbe: Color, art: int) -> void:
	var tief := w * 0.5 * HANG + 2.0
	_kiste(Vector3(0, (h - tief) * 0.5, 0), Vector3(w, h + tief, w), farbe, art)
	if art == 0:
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_kiste(Vector3(sx * (w * 0.5 - 0.2), h * 0.5, sz * (w * 0.5 - 0.2)), Vector3(0.48, h, 0.48), STEIN_HELL, 4)
	for yy: float in [h * 0.38, h * 0.66, h - 0.2]:
		_kiste(Vector3(0, yy, 0), Vector3(w + 0.5, 0.45, w + 0.5), STEIN_HELL, 4)
	for n: Vector3 in [Vector3.BACK, Vector3.FORWARD, Vector3.RIGHT, Vector3.LEFT]:
		var r := Vector3.UP.cross(n)
		var aussen := n * w * 0.5
		_flaeche(aussen + Vector3(0, h * 0.5 - 0.7, 0), n, 2.2 if w > 6.0 else 1.8, 2.2 if w > 6.0 else 1.8, farbe, 10, 0.26, true)
		for s: float in [-1.0, 1.0]:
			_flaeche(aussen + r * s * w * 0.2 + Vector3(0, h * 0.72, 0), n, 0.9, 3.0, GLAS, 15, 0.05)
		_flaeche(aussen + Vector3(0, h * 0.2, 0), n, 0.5, 1.4, GLAS, 3, 0.05, true)
	match spitze:
		"zwiebel":
			_drehkoerper(Vector3(0, h, 0), [Vector2(w * 0.44, 0.0), Vector2(w * 0.44, w * 0.4)], 8, farbe, 0)
			var y1 := h + w * 0.4
			_drehkoerper(Vector3(0, y1, 0), [Vector2(w * 0.3, 0.0), Vector2(w * 0.5, 0.0), Vector2(w * 0.58, w * 0.25),
				Vector2(w * 0.6, w * 0.5), Vector2(w * 0.5, w * 0.82), Vector2(w * 0.3, w * 1.1), Vector2(w * 0.13, w * 1.3),
				Vector2(w * 0.09, w * 1.42)], 16, KUPFER, 5)
			var y2 := y1 + w * 1.42
			_drehkoerper(Vector3(0, y2, 0), [Vector2(w * 0.11, 0.0), Vector2(w * 0.11, w * 0.42)], 8, farbe, 0)
			var y3 := y2 + w * 0.42
			_drehkoerper(Vector3(0, y3, 0), [Vector2(w * 0.1, 0.0), Vector2(w * 0.16, 0.0), Vector2(w * 0.2, w * 0.12),
				Vector2(w * 0.15, w * 0.3), Vector2(w * 0.05, w * 0.45), Vector2(w * 0.025, w * 0.5)], 12, KUPFER, 5)
			_spitze_gold(Vector3(0, y3 + w * 0.5, 0), w * 0.35)
		"haube":
			_drehkoerper(Vector3(0, h, 0), [Vector2(w * 0.5, 0.0), Vector2(w * 0.46, 0.4), Vector2(w * 0.46, w * 0.9)], 8, farbe, art)
			var y1 := h + w * 0.9
			_drehkoerper(Vector3(0, y1, 0), [Vector2(w * 0.3, 0.0), Vector2(w * 0.52, 0.0), Vector2(w * 0.55, w * 0.25),
				Vector2(w * 0.48, w * 0.6), Vector2(w * 0.3, w * 0.85), Vector2(w * 0.14, w * 1.0), Vector2(w * 0.12, w * 1.1)], 16, KUPFER, 5)
			var y2 := y1 + w * 1.1
			_drehkoerper(Vector3(0, y2, 0), [Vector2(w * 0.12, 0.0), Vector2(w * 0.12, w * 0.4)], 8, STEIN_HELL, 0)
			var y3 := y2 + w * 0.4
			_drehkoerper(Vector3(0, y3, 0), [Vector2(w * 0.1, 0.0), Vector2(w * 0.15, 0.0), Vector2(w * 0.1, w * 0.2), Vector2(w * 0.02, w * 0.35)], 12, KUPFER, 5)
			_spitze_gold(Vector3(0, y3 + w * 0.35, 0), w * 0.3)
		_:
			_pyramide(Vector3(0, h, 0), w * 0.5 + 0.35, w * 2.6, KUPFER if w < 6.0 else Color(0.5, 0.24, 0.17), 5 if w < 6.0 else 1)
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					var ep := Vector3(sx * (w * 0.5 - 0.1), h + 0.2, sz * (w * 0.5 - 0.1))
					_kiste(ep + Vector3(0, 0.6, 0), Vector3(0.7, 1.2, 0.7), STEIN_HELL, 4)
					_pyramide(ep + Vector3(0, 1.2, 0), 0.4, 2.4, KUPFER, 5)
			_spitze_gold(Vector3(0, h + w * 2.6, 0), 1.2)

func _frauenkirche() -> void:
	var alt := _t
	var tief := 16.0
	var nw := 24.0
	var nd := 46.0
	var nh := 21.0
	var nz := -31.0
	_kiste(Vector3(0, (nh - tief) * 0.5, nz), Vector3(nw, nh + tief, nd), ZIEGELROT, 11)
	for s: float in [-1.0, 1.0]:
		for i in 8:
			var z := nz - nd * 0.5 + nd / 8.0 * (i + 0.5)
			_flaeche(Vector3(s * nw * 0.5, 4.0, z), Vector3(s, 0, 0), 1.8, 12.0, GLAS, 3, 0.05, true)
			_kiste(Vector3(s * (nw * 0.5 + 0.4), (nh - tief) * 0.5, nz - nd * 0.5 + nd / 8.0 * i), Vector3(0.8, nh + tief, 0.9), ZIEGELROT * 0.95, 11)
	_t = alt * Transform3D(Basis.IDENTITY, Vector3(0, 0, nz))
	_satteldach_z(nw, nd, nh, 17.0, Color(0.5, 0.22, 0.15), ZIEGELROT, 0.45, true)
	for s: float in [-1.0, 1.0]:
		_t = alt * Transform3D(Basis.IDENTITY, Vector3(s * 8.5, 0, -4.5))
		_turm(9.0, 62.0, "haube", ZIEGELROT, 11)
	_t = alt
	_kiste(Vector3(0, (28.0 - tief) * 0.5, -4.5), Vector3(8.0, 28.0 + tief, 9.0), ZIEGELROT, 11)
	_flaeche(Vector3(0, 0.0, 0.0), Vector3.BACK, 3.6, 6.5, HOLZ * 0.8, 13, 0.06)
	_flaeche(Vector3(0, -0.2, 0.0), Vector3.BACK, 4.6, 7.4, STEIN_HELL, 4, 0.04)
	_flaeche(Vector3(0, 9.0, 0.0), Vector3.BACK, 2.6, 13.0, GLAS, 3, 0.05, true)

func _rathaus() -> void:
	var alt := _t
	_t = alt * Transform3D(Basis.IDENTITY, Vector3(0, 0, -9.8))
	var putz := Color(0.84, 0.8, 0.7)
	var wand := 0.7 + 4 * 2.9
	_kiste(Vector3(0, -2.0, 0), Vector3(22.1, 5.4, 13.1), STEIN, 4)
	_kiste(Vector3(0, 0.7 + (wand - 0.7) * 0.5, 0), Vector3(22.0, wand - 0.7, 13.0), putz, 0, 60)
	for f in 4:
		for i in 9:
			var x := -11.0 + 22.0 / 9.0 * (i + 0.5)
			_fenster(Vector3(x, 0.7 + f * 2.9 + 0.8, 6.5), Vector3.BACK, 0.9, 1.5, false, HOLZ, f == 1)
	_satteldach_x(22.0, 13.0, wand, 6.5, Color(0.48, 0.24, 0.17), putz)
	for g in 3:
		_gaube(-7.0 + g * 7.0, 6.5 - 0.9, wand + 6.5 / 6.5 * 0.9, putz, Color(0.48, 0.24, 0.17))
	_t = alt
	_turm(6.5, 46.0, "spitz", putz, 0)

func _stadttor() -> void:
	var stein := Color(0.8, 0.74, 0.62)
	var dach := Color(0.55, 0.24, 0.16)
	_kiste(Vector3(0, 8.0, 0), Vector3(14.0, 20.0, 9.0), stein, 4)
	for s: float in [1.0, -1.0]:
		var n := Vector3(0, 0, s)
		_flaeche(Vector3(0, -0.2, s * 4.5), n, 6.2, 8.4, STEIN_HELL, 4, 0.03)
		_flaeche(Vector3(0, -0.2, s * 4.5), n, 5.0, 7.6, Color(0.06, 0.05, 0.04), 15, 0.06)
		for i in 4:
			_fenster(Vector3(-5.1 + i * 3.4, 11.5, s * 4.5), n, 0.9, 1.5, false, HOLZ, false)
		_flaeche(Vector3(0, 14.4, s * 4.5), n, 2.8, 2.8, stein, 10, 0.07, true)
		_kiste(Vector3(0, 9.6, s * 4.6), Vector3(14.4, 0.4, 0.3), STEIN_HELL, 4)
	_satteldach_x(14.0, 9.0, 18.0, 6.5, dach, stein)
	for s: float in [-1.0, 1.0]:
		var m := Vector3(s * 9.8, 0, -0.5)
		_drehkoerper(m, [Vector2(4.0, -3.0), Vector2(4.0, 21.0), Vector2(4.4, 21.0), Vector2(4.4, 21.6)], 12, stein, 4)
		_drehkoerper(m + Vector3(0, 21.6, 0), [Vector2(0.0, 0.0), Vector2(4.8, 0.0), Vector2(0.0, 9.0)], 12, dach, 1)
		_spitze_gold(m + Vector3(0, 30.6, 0), 1.0)
		for yy: float in [7.0, 14.0]:
			_flaeche(m + Vector3(0, yy, 4.0), Vector3.BACK, 0.6, 1.6, GLAS, 3, 0.25, true)

func _maibaum() -> void:
	_drehkoerper(Vector3.ZERO, [Vector2(0.34, -3.0), Vector2(0.28, 14.0), Vector2(0.15, 30.0), Vector2(0.0, 30.2)], 10, RAHMEN, 8)
	for i in 6:
		var y := 9.0 + i * 2.6
		var quer := i % 2 == 0
		_kiste(Vector3(0, y, 0), Vector3(3.4, 0.12, 0.12) if quer else Vector3(0.12, 0.12, 3.4), HOLZ, 2)
		for s: float in [-1.0, 1.0]:
			var off := Vector3(s * 1.5, -0.9, 0) if quer else Vector3(0, -0.9, s * 1.5)
			var gs := Vector3(0.1, 1.4, 1.2) if quer else Vector3(1.2, 1.4, 0.1)
			_kiste(Vector3(0, y, 0) + off, gs, ZUNFT[(i * 2 + (1 if s > 0.0 else 0)) % ZUNFT.size()], 0, 63)
	_drehkoerper(Vector3(0, 26.5, 0), [Vector2(0.3, 0.0), Vector2(1.2, 0.3), Vector2(1.2, 0.8), Vector2(0.3, 1.1)], 12, LAUB, 16)
	_spitze_gold(Vector3(0, 30.2, 0), 1.0)

# ------------------------------------------------------------------ Mauer und Bäume

func _stadtmauer() -> void:
	var n := 120
	var stein := Color(0.74, 0.68, 0.58)
	var dach := Color(0.56, 0.25, 0.17)
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var am := (a0 + a1) * 0.5
		if _nahe_tor(am, 0.14):
			continue
		var p := polar(am, MAUER_R)
		var laenge := 2.0 * MAUER_R * sin((a1 - a0) * 0.5) + 0.25
		_t = Transform3D(Basis(Vector3.UP, am + PI), Vector3(p.x, 0, p.z))
		_kiste(Vector3(0, 3.0, 0), Vector3(laenge, 8.0, 1.6), stein, 4)
		var zinnen := int(laenge / 1.7)
		for z in zinnen:
			var x := -laenge * 0.5 + (z + 0.5) * laenge / zinnen
			_kiste(Vector3(x, 7.5, -0.5), Vector3(0.9, 1.0, 0.6), stein, 4)
		var o := Vector3(-laenge * 0.5, 8.7, -0.1)
		var b := Vector3(laenge * 0.5, 8.7, -0.1)
		_quad(o, b, Vector3(laenge * 0.5, 7.3, 1.7), Vector3(-laenge * 0.5, 7.3, 1.7), dach, 1, Vector3(0, 1, 1))
		_quad(o, b, Vector3(laenge * 0.5, 7.3, 1.7), Vector3(-laenge * 0.5, 7.3, 1.7), HOLZ * 0.7, 2, Vector3(0, -1, -1))
	for j in 14:
		var a := TAU * j / 14 + TAU / 28.0
		if _nahe_tor(a, 0.22):
			continue
		var p := polar(a, MAUER_R)
		_t = Transform3D(Basis.IDENTITY, Vector3(p.x, 0, p.z))
		_drehkoerper(Vector3.ZERO, [Vector2(3.4, -1.0), Vector2(3.4, 12.0), Vector2(3.8, 12.0), Vector2(3.8, 12.5)], 14, stein, 4)
		_drehkoerper(Vector3(0, 12.5, 0), [Vector2(0.0, 0.0), Vector2(4.3, 0.0), Vector2(0.0, 7.5)], 14, dach, 1)
		_spitze_gold(Vector3(0, 20.0, 0), 0.8)
		for k in 4:
			var w := TAU * k / 4.0 + a
			var nn := Vector3(cos(w), 0, sin(w))
			_flaeche(nn * 3.4 + Vector3(0, 6.5, 0), nn, 0.5, 1.6, GLAS, 3, 0.08, true)
	_t = Transform3D.IDENTITY

func _baum(p: Vector3, g: float, nadel: bool) -> void:
	_t = Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p)
	var stamm := Color(0.3, 0.22, 0.15)
	if nadel:
		_drehkoerper(Vector3(0, -1.0, 0), [Vector2(0.28 * g, 0.0), Vector2(0.2 * g, 2.5 * g)], 6, stamm, 2)
		var farbe := _jitter(NADEL, 0.1)
		_drehkoerper(Vector3(0, 1.2 * g, 0), [Vector2(0.0, 0.0), Vector2(2.2 * g, 0.0), Vector2(1.1 * g, 2.8 * g),
			Vector2(1.6 * g, 2.8 * g), Vector2(0.6 * g, 5.4 * g), Vector2(0.9 * g, 5.4 * g), Vector2(0.0, 8.0 * g)], 8, farbe, 16)
	else:
		_drehkoerper(Vector3(0, -1.0, 0), [Vector2(0.35 * g, 0.0), Vector2(0.25 * g, 3.5 * g)], 6, stamm, 2)
		var farbe := _jitter(LAUB, 0.12)
		_drehkoerper(Vector3(0, 2.2 * g, 0), [Vector2(0.0, 0.0), Vector2(1.9 * g, 0.5 * g), Vector2(2.8 * g, 2.0 * g),
			Vector2(2.6 * g, 3.5 * g), Vector2(1.6 * g, 4.8 * g), Vector2(0.0, 5.3 * g)], 9, farbe, 16)

func _baeume() -> void:
	# Allee auf der Wiese vor der Stadtmauer
	var n := 64
	for i in n:
		var a := TAU * i / n
		if _nahe_tor(a, 0.1):
			continue
		var r := 86.0 + rng.randf_range(-1.0, 1.0)
		_st = _sektor(a)
		_baum(polar(a, r) + Vector3(0, -0.1, 0), rng.randf_range(0.9, 1.15), false)
	# Wälder auf den Hügeln hinter der Stadt
	var wald := FastNoiseLite.new()
	wald.seed = 9
	wald.frequency = 0.012
	var gesetzt := 0
	var versuche := 0
	while gesetzt < 1100 and versuche < 20000:
		versuche += 1
		var a := rng.randf() * TAU
		var r := rng.randf_range(236.0, 520.0)
		var p := _bodenpunkt(a, r)
		if wald.get_noise_2d(p.x, p.z) < 0.05:
			continue
		_st = _sektor(a)
		var g := rng.randf_range(1.0, 1.6) * (1.0 + (r - 236.0) / 300.0)
		_baum(p, g, rng.randf() < 0.65)
		gesetzt += 1
	# einzelne Bäume in den Gassen
	for i in 40:
		var a := rng.randf() * TAU
		var r := rng.randf_range(112.0, 220.0)
		var p := polar(a, r)
		if not _frei(p, 3.0):
			continue
		_st = _sektor(a)
		_baum(p, rng.randf_range(0.8, 1.1), false)
	_t = Transform3D.IDENTITY
