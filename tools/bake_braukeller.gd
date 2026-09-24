extends SceneTree
## Backt den Braukeller unter dem Festzelt zu ArrayMeshes — eine Oberfläche je
## Material, damit aus hunderten Einzelteilen wenige Zeichenaufrufe werden (wie
## tools/bake_moebel.gd und tools/bake_zelt.gd).
##
##   keller        Gewölbe: Steinboden, Ziegelwände, Deckenbalken, Treppe,
##                 Türrahmen, Lampen — alles ein Mesh
##   maischbottich Holzbottich mit Eisenreifen und Rührpaddel (🌾 Malz + 💧 Wasser)
##   sudkessel     Kupferkessel mit Haube, Rohr und Feuerstelle (🔥 Kochen + 🌿 Hopfen)
##   gaerfass      Liegendes Lagerfass auf Holzböcken, Spundloch und Zapfhahn (🦠 Hefe)
##   transportfass Kleines tragbares Fass für den Weg nach oben
##
## Aufruf: godot --headless --script res://tools/bake_braukeller.gd
##
## Maße in Metern. Der Keller liegt unter dem Zelt: Boden bei y = -3.4,
## Deckenunterkante bei y = -1.0, Treppenschacht wie in tools/bake_zelt.gd
## (SCHACHT_*). Die Gefäße haben ihren Ursprung am Boden.

const ZIEL := "res://assets/braukeller/"

# Muss zu tools/bake_zelt.gd passen (Loch im Dielenboden)
const SCHACHT_X0 := -11.8
const SCHACHT_X1 := -8.8
const SCHACHT_Z0 := -14.0
const SCHACHT_Z1 := -8.4
# Keller: Boden und Decke
const BODEN_Y := -3.4
const DECKE_Y := -1.0
# Brauraum östlich der Treppe
const RAUM_X0 := -8.8
const RAUM_X1 := -3.6
const RAUM_Z0 := -14.2
const RAUM_Z1 := -5.6
# Treppe: oben an der Zeltkante, unten auf dem Kellerboden
const TREPPE_Z_OBEN := -8.6
const TREPPE_Z_UNTEN := -13.4
const TUER_Z := -11.5
const TUER_B := 1.2
const TUER_H := 2.05

var _teile := {}
var _mats := {}

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZIEL))
	_keller()
	_maischbottich()
	_sudkessel()
	_gaerfass()
	_transportfass()
	print("Braukeller gebacken.")
	quit()

# ------------------------------------------------------------ Werkzeug
func _mat(name: String, farbe: Color, rauh := 0.85, metall := 0.0, leuchten := 0.0) -> void:
	if _mats.has(name):
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	m.roughness = rauh
	m.metallic = metall
	if leuchten > 0.0:
		m.emission_enabled = true
		m.emission = farbe
		m.emission_energy_multiplier = leuchten
	_mats[name] = m

func _neu() -> void:
	_teile.clear()
	_mats.clear()

func _add(mat: String, mesh: PrimitiveMesh, t: Transform3D) -> void:
	if not _teile.has(mat):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_teile[mat] = st
	(_teile[mat] as SurfaceTool).append_from(mesh, 0, t)

func _speichern(name: String) -> void:
	var am := ArrayMesh.new()
	for mat: String in _teile.keys():
		var st: SurfaceTool = _teile[mat]
		st.generate_normals()
		st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, _mats[mat])
		am.surface_set_name(am.get_surface_count() - 1, mat)
	ResourceSaver.save(am, ZIEL + name + ".tres")
	print("  ", name, ": ", am.get_surface_count(), " Oberflächen")

func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b

func _zyl(r_oben: float, r_unten: float, h: float, seg := 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_oben
	c.bottom_radius = r_unten
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

func _torus(innen: float, aussen: float, seg := 20, ring := 8) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = innen
	t.outer_radius = aussen
	t.rings = seg
	t.ring_segments = ring
	return t

func _kugel(r: float, seg := 14, ringe := 8) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = ringe
	return s

func _at(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))

## Achse liegend: dreht ein Zylinder-Mesh von y auf x bzw. z
func _liegend(achse: String, x: float, y: float, z: float) -> Transform3D:
	var b := Basis(Vector3.FORWARD, PI / 2.0) if achse == "x" else Basis(Vector3.RIGHT, PI / 2.0)
	return Transform3D(b, Vector3(x, y, z))

func _kellermats() -> void:
	_mat("stein", Color(0.44, 0.42, 0.39), 0.95)
	_mat("ziegel", Color(0.42, 0.26, 0.21), 0.9)
	_mat("moertel", Color(0.55, 0.52, 0.47), 0.95)
	_mat("holz", Color(0.46, 0.3, 0.17), 0.8)
	_mat("holz_dunkel", Color(0.27, 0.17, 0.1), 0.8)
	# Metallwert niedrig halten: bei 0.7 spiegelten die Fassreifen den Himmel und
	# waren im Keller blau statt dunkelgrau.
	_mat("eisen", Color(0.22, 0.21, 0.22), 0.65, 0.25)
	_mat("kupfer", Color(0.72, 0.4, 0.18), 0.35, 0.7)
	_mat("messing", Color(0.78, 0.6, 0.26), 0.38, 0.6)
	_mat("glut", Color(1.0, 0.45, 0.12), 0.6, 0.0, 2.2)
	_mat("licht", Color(1.0, 0.86, 0.6), 0.4, 0.0, 3.0)

# ------------------------------------------------------------ Gewölbe
func _keller() -> void:
	_neu()
	_kellermats()
	var hoehe := DECKE_Y - BODEN_Y

	# Boden: Steinplatten über Treppenschacht und Brauraum
	_add("stein", _box(Vector3(SCHACHT_X1 - SCHACHT_X0 + 0.4, 0.2, SCHACHT_Z1 - SCHACHT_Z0 + 0.4)),
		_at((SCHACHT_X0 + SCHACHT_X1) / 2.0, BODEN_Y - 0.1, (SCHACHT_Z0 + SCHACHT_Z1) / 2.0))
	_add("stein", _box(Vector3(RAUM_X1 - RAUM_X0 + 0.4, 0.2, RAUM_Z1 - RAUM_Z0 + 0.4)),
		_at((RAUM_X0 + RAUM_X1) / 2.0, BODEN_Y - 0.1, (RAUM_Z0 + RAUM_Z1) / 2.0))
	# Plattenfugen: ein Raster heller Mörtelstreifen, damit der Boden nicht leer wirkt
	var fx := RAUM_X0
	while fx <= RAUM_X1:
		_add("moertel", _box(Vector3(0.04, 0.01, RAUM_Z1 - RAUM_Z0)),
			_at(fx, BODEN_Y + 0.005, (RAUM_Z0 + RAUM_Z1) / 2.0))
		fx += 1.3
	var fz := RAUM_Z0
	while fz <= RAUM_Z1:
		_add("moertel", _box(Vector3(RAUM_X1 - RAUM_X0, 0.01, 0.04)),
			_at((RAUM_X0 + RAUM_X1) / 2.0, BODEN_Y + 0.005, fz))
		fz += 1.3

	# Ziegelwände rings um beide Räume, mit Aussparung für die Tür
	_wand_x(SCHACHT_X0 - 0.15, SCHACHT_Z0, SCHACHT_Z1, hoehe)          # Treppe West
	_wand_z(SCHACHT_Z0 - 0.15, SCHACHT_X0, SCHACHT_X1, hoehe)          # Treppe Süd
	_wand_z(SCHACHT_Z1 + 0.15, SCHACHT_X0, SCHACHT_X1, hoehe, 0.3)     # Treppe Nord (nur Sockel, oben offen)
	_wand_z(RAUM_Z0 - 0.15, RAUM_X0, RAUM_X1, hoehe)                   # Brauraum Süd
	_wand_z(RAUM_Z1 + 0.15, RAUM_X0, RAUM_X1, hoehe)                   # Brauraum Nord
	_wand_x(RAUM_X1 + 0.15, RAUM_Z0, RAUM_Z1, hoehe)                   # Brauraum Ost
	# Trennwand mit Türöffnung zwischen Treppe und Brauraum
	_wand_x(RAUM_X0, RAUM_Z0, TUER_Z - TUER_B / 2.0, hoehe)
	_wand_x(RAUM_X0, TUER_Z + TUER_B / 2.0, RAUM_Z1, hoehe)
	# Sturz über der Tür
	_add("ziegel", _box(Vector3(0.3, hoehe - TUER_H, TUER_B)),
		_at(RAUM_X0, BODEN_Y + TUER_H + (hoehe - TUER_H) / 2.0, TUER_Z))
	# Türrahmen aus Balken
	for dz: float in [TUER_Z - TUER_B / 2.0, TUER_Z + TUER_B / 2.0]:
		_add("holz_dunkel", _box(Vector3(0.36, TUER_H, 0.12)), _at(RAUM_X0, BODEN_Y + TUER_H / 2.0, dz))
	_add("holz_dunkel", _box(Vector3(0.36, 0.14, TUER_B + 0.24)), _at(RAUM_X0, BODEN_Y + TUER_H, TUER_Z))

	# Decke: Balkenlage über beiden Räumen, dazwischen Bretter
	_add("holz_dunkel", _box(Vector3(RAUM_X1 - RAUM_X0 + 0.4, 0.12, RAUM_Z1 - RAUM_Z0 + 0.4)),
		_at((RAUM_X0 + RAUM_X1) / 2.0, DECKE_Y + 0.06, (RAUM_Z0 + RAUM_Z1) / 2.0))
	var bz := RAUM_Z0 + 0.6
	while bz <= RAUM_Z1 - 0.3:
		_add("holz", _box(Vector3(RAUM_X1 - RAUM_X0, 0.22, 0.2)),
			_at((RAUM_X0 + RAUM_X1) / 2.0, DECKE_Y - 0.11, bz))
		bz += 1.2
	# Über der Treppe nur der Streifen neben dem Schacht
	_add("holz_dunkel", _box(Vector3(SCHACHT_X1 - SCHACHT_X0 + 0.4, 0.12, 0.6)),
		_at((SCHACHT_X0 + SCHACHT_X1) / 2.0, DECKE_Y + 0.06, SCHACHT_Z0 + 0.3))

	_schachtkragen()
	_treppe()
	_lampen()
	_kellerdeko()
	_speichern("keller")

## Ziegelwand entlang z bei festem x
func _wand_x(x: float, z0: float, z1: float, hoehe: float, anteil := 1.0) -> void:
	if z1 - z0 < 0.05:
		return
	var h := hoehe * anteil
	_add("ziegel", _box(Vector3(0.3, h, z1 - z0)), _at(x, BODEN_Y + h / 2.0, (z0 + z1) / 2.0))
	# Zwei Mörtelbänder als Lagerfugen — billige Struktur, große Wirkung
	for f: float in [0.33, 0.66]:
		_add("moertel", _box(Vector3(0.32, 0.03, z1 - z0)), _at(x, BODEN_Y + h * f, (z0 + z1) / 2.0))

## Ziegelwand entlang x bei festem z
func _wand_z(z: float, x0: float, x1: float, hoehe: float, anteil := 1.0) -> void:
	if x1 - x0 < 0.05:
		return
	var h := hoehe * anteil
	_add("ziegel", _box(Vector3(x1 - x0, h, 0.3)), _at((x0 + x1) / 2.0, BODEN_Y + h / 2.0, z))
	for f: float in [0.33, 0.66]:
		_add("moertel", _box(Vector3(x1 - x0, 0.03, 0.32)), _at((x0 + x1) / 2.0, BODEN_Y + h * f, z))

## Kragen zwischen Kellerdecke (y = DECKE_Y) und Zeltboden (y = 0): ohne ihn
## schaut man durch das Loch im Dielenboden seitlich ins Freie, weil dort
## zwischen Decke und Boden nichts steht. Nach Norden bleibt es offen — dort
## steigt man ein.
func _schachtkragen() -> void:
	var h := -DECKE_Y
	var y := DECKE_Y + h / 2.0
	_add("ziegel", _box(Vector3(0.3, h, SCHACHT_Z1 - SCHACHT_Z0)),
		_at(SCHACHT_X0 - 0.15, y, (SCHACHT_Z0 + SCHACHT_Z1) / 2.0))
	_add("ziegel", _box(Vector3(0.3, h, SCHACHT_Z1 - SCHACHT_Z0)),
		_at(SCHACHT_X1 + 0.15, y, (SCHACHT_Z0 + SCHACHT_Z1) / 2.0))
	_add("ziegel", _box(Vector3(SCHACHT_X1 - SCHACHT_X0 + 0.6, h, 0.3)),
		_at((SCHACHT_X0 + SCHACHT_X1) / 2.0, y, SCHACHT_Z0 - 0.15))
	# Unter dem Dielenboden rings um den Schacht ein Balkenkranz, damit die
	# Schnittkante des Bodens nicht in der Luft hängt
	for sx: float in [SCHACHT_X0 - 0.06, SCHACHT_X1 + 0.06]:
		_add("holz_dunkel", _box(Vector3(0.12, 0.2, SCHACHT_Z1 - SCHACHT_Z0)),
			_at(sx, -0.14, (SCHACHT_Z0 + SCHACHT_Z1) / 2.0))
	_add("holz_dunkel", _box(Vector3(SCHACHT_X1 - SCHACHT_X0 + 0.24, 0.2, 0.12)),
		_at((SCHACHT_X0 + SCHACHT_X1) / 2.0, -0.14, SCHACHT_Z0 - 0.06))
	_add("holz_dunkel", _box(Vector3(SCHACHT_X1 - SCHACHT_X0 + 0.24, 0.2, 0.12)),
		_at((SCHACHT_X0 + SCHACHT_X1) / 2.0, -0.14, SCHACHT_Z1 + 0.06))

## Treppe vom Zeltboden herunter: Stufen, Wangen, Handlauf.
## Die Kollision ist eine Rampe (scenes/braukeller.tscn) — genau wie bei den
## Emporentreppen im Zelt, weil Stufen als Kollision den Spieler hängen lassen.
func _treppe() -> void:
	var lauf := TREPPE_Z_OBEN - TREPPE_Z_UNTEN
	var n := 17
	var breite := SCHACHT_X1 - SCHACHT_X0 - 0.5
	var mx := (SCHACHT_X0 + SCHACHT_X1) / 2.0
	var steigung := -BODEN_Y / float(n)
	var tritt := lauf / float(n)
	for i in n:
		var y := BODEN_Y + steigung * float(i + 1)
		var z := TREPPE_Z_UNTEN + tritt * (float(i) + 0.5)
		_add("holz", _box(Vector3(breite, 0.07, tritt + 0.05)), _at(mx, y - 0.035, z))
		_add("holz_dunkel", _box(Vector3(breite, steigung - 0.07, 0.05)), _at(mx, y - steigung / 2.0 - 0.02, z - tritt / 2.0))
	var winkel := atan2(-BODEN_Y, lauf)
	var schraeg := sqrt(BODEN_Y * BODEN_Y + lauf * lauf)
	var neigung := Basis(Vector3.RIGHT, -winkel)
	var mitte := Vector3(mx, BODEN_Y / 2.0, (TREPPE_Z_OBEN + TREPPE_Z_UNTEN) / 2.0)
	for sx: float in [-1.0, 1.0]:
		_add("holz_dunkel", _box(Vector3(0.08, 0.36, schraeg)),
			Transform3D(neigung, Vector3(mx + sx * (breite / 2.0 + 0.04), mitte.y - 0.1, mitte.z)))
		_add("holz_dunkel", _box(Vector3(0.06, 0.06, schraeg)),
			Transform3D(neigung, Vector3(mx + sx * (breite / 2.0 + 0.04), mitte.y + 0.95, mitte.z)))
		for i in range(1, n, 4):
			var y := BODEN_Y + steigung * float(i + 1)
			var z := TREPPE_Z_UNTEN + tritt * (float(i) + 0.5)
			_add("holz_dunkel", _box(Vector3(0.05, 0.9, 0.05)),
				_at(mx + sx * (breite / 2.0 + 0.04), y + 0.45, z))
	# Podest unten
	_add("stein", _box(Vector3(breite + 0.3, 0.06, 1.0)), _at(mx, BODEN_Y + 0.03, TREPPE_Z_UNTEN - 0.5))

## Drei Lampen unter der Decke — gebacken ist nur der Körper, das Licht selbst
## steckt als OmniLight3D in scenes/braukeller.tscn.
func _lampen() -> void:
	for lz: float in [RAUM_Z0 + 1.6, (RAUM_Z0 + RAUM_Z1) / 2.0, RAUM_Z1 - 1.6]:
		var lx := (RAUM_X0 + RAUM_X1) / 2.0
		_add("eisen", _box(Vector3(0.04, 0.35, 0.04)), _at(lx, DECKE_Y - 0.35, lz))
		_add("eisen", _zyl(0.22, 0.1, 0.16, 14), _at(lx, DECKE_Y - 0.6, lz))
		_add("licht", _kugel(0.09, 12, 6), _at(lx, DECKE_Y - 0.74, lz))
	_add("eisen", _box(Vector3(0.04, 0.3, 0.04)),
		_at((SCHACHT_X0 + SCHACHT_X1) / 2.0, DECKE_Y - 0.3, TREPPE_Z_UNTEN - 0.4))
	_add("licht", _kugel(0.08, 12, 6),
		_at((SCHACHT_X0 + SCHACHT_X1) / 2.0, DECKE_Y - 0.6, TREPPE_Z_UNTEN - 0.4))
	# Wandlampe neben der Tür — ohne sie steht man im Dunkeln vor dem Schloss
	_add("eisen", _box(Vector3(0.22, 0.05, 0.05)), _at(RAUM_X0 - 0.28, BODEN_Y + 1.95, TUER_Z - 0.95))
	_add("eisen", _zyl(0.13, 0.07, 0.12, 12), _at(RAUM_X0 - 0.42, BODEN_Y + 1.88, TUER_Z - 0.95))
	_add("licht", _kugel(0.07, 12, 6), _at(RAUM_X0 - 0.42, BODEN_Y + 1.76, TUER_Z - 0.95))

## Kleinzeug, damit der Keller bewohnt wirkt: Malzsäcke, Kiste, Schaufel, Eimer
func _kellerdeko() -> void:
	_mat("sack", Color(0.72, 0.62, 0.42), 0.95)
	_mat("blech", Color(0.55, 0.56, 0.58), 0.5, 0.6)
	var sx := RAUM_X1 - 0.6
	for i in 3:
		var sz := RAUM_Z1 - 1.0 - float(i) * 0.55
		_add("sack", _zyl(0.22, 0.26, 0.6, 10), _at(sx, BODEN_Y + 0.3, sz))
		_add("sack", _box(Vector3(0.3, 0.06, 0.16)), _at(sx, BODEN_Y + 0.62, sz))
	_add("sack", _zyl(0.24, 0.26, 0.5, 10), Transform3D(Basis(Vector3.FORWARD, 1.4), Vector3(sx - 0.5, BODEN_Y + 0.2, RAUM_Z1 - 2.4)))
	_add("holz", _box(Vector3(0.7, 0.5, 0.5)), _at(RAUM_X0 + 0.6, BODEN_Y + 0.25, RAUM_Z1 - 0.7))
	_add("holz_dunkel", _box(Vector3(0.74, 0.05, 0.54)), _at(RAUM_X0 + 0.6, BODEN_Y + 0.52, RAUM_Z1 - 0.7))
	_add("blech", _zyl(0.16, 0.12, 0.3, 12), _at(RAUM_X0 + 0.5, BODEN_Y + 0.15, RAUM_Z0 + 0.8))
	_add("eisen", _box(Vector3(0.05, 1.2, 0.05)), Transform3D(Basis(Vector3.FORWARD, 0.18), Vector3(RAUM_X1 - 0.25, BODEN_Y + 0.6, RAUM_Z0 + 0.7)))
	_add("blech", _box(Vector3(0.22, 0.3, 0.03)), _at(RAUM_X1 - 0.35, BODEN_Y + 0.08, RAUM_Z0 + 0.72))

# ------------------------------------------------------------ Maischbottich
## Holzbottich mit Eisenreifen, Rührpaddel und Wasserhahn darüber.
func _maischbottich() -> void:
	_neu()
	_kellermats()
	_mat("maische", Color(0.62, 0.45, 0.2), 0.7)
	var h := 1.15
	var r := 0.78
	# Dauben als Ring einzelner Bretter — sieht aus wie echtes Fassholz
	var n := 22
	for i in n:
		var w := TAU * float(i) / float(n)
		var t := Transform3D(Basis(Vector3.UP, w), Vector3(sin(w) * (r - 0.03), h / 2.0, cos(w) * (r - 0.03)))
		_add("holz", _box(Vector3(TAU * r / float(n) + 0.02, h, 0.07)), t)
	_add("holz_dunkel", _zyl(r - 0.06, r - 0.06, 0.08, 20), _at(0, 0.06, 0))
	for ry: float in [0.14, h * 0.55, h - 0.12]:
		_add("eisen", _torus(r - 0.02, r + 0.05, 24, 6), _at(0, ry, 0))
	# Maische im Bottich
	_add("maische", _zyl(r - 0.1, r - 0.1, 0.06, 20), _at(0, h - 0.22, 0))
	# Rührwerk: Welle mit zwei Paddeln und Handkurbel
	_add("eisen", _zyl(0.05, 0.05, h + 0.5, 10), _at(0, h * 0.7, 0))
	for w: float in [0.0, PI / 2.0]:
		_add("holz_dunkel", _box(Vector3(r * 1.4, 0.16, 0.05)),
			Transform3D(Basis(Vector3.UP, w), Vector3(0, h - 0.4, 0)))
	_add("eisen", _box(Vector3(0.3, 0.04, 0.04)), _at(0.15, h + 0.72, 0))
	_add("holz", _zyl(0.05, 0.05, 0.16, 10), _liegend("x", 0.32, h + 0.72, 0))
	# Wasserhahn an der Wandseite
	_add("messing", _zyl(0.04, 0.04, 0.5, 10), _at(-r - 0.2, h + 0.35, 0))
	_add("messing", _zyl(0.035, 0.035, 0.35, 10), _liegend("x", -r - 0.05, h + 0.55, 0))
	_add("messing", _torus(0.05, 0.1, 12, 6), _at(-r - 0.2, h + 0.62, 0))
	_speichern("maischbottich")

# ------------------------------------------------------------ Sudkessel
## Kupferkessel auf Feuerstelle, mit Haube, Dampfrohr und Hopfenkorb.
func _sudkessel() -> void:
	_neu()
	_kellermats()
	_mat("hopfen", Color(0.45, 0.6, 0.22), 0.8)
	var sockel := 0.42
	var h := 1.05
	var r := 0.82
	# Feuerstelle aus Ziegeln mit Glut
	_add("ziegel", _zyl(r + 0.12, r + 0.2, sockel, 18), _at(0, sockel / 2.0, 0))
	_add("eisen", _torus(r + 0.06, r + 0.16, 20, 6), _at(0, sockel, 0))
	_add("eisen", _box(Vector3(0.5, 0.3, 0.06)), _at(0, sockel * 0.55, -r - 0.18))
	_add("glut", _zyl(0.3, 0.34, 0.1, 14), _at(0, sockel * 0.4, -r - 0.05))
	# Kesselkörper: unten bauchig, oben eingezogen
	_add("kupfer", _zyl(r, r - 0.14, h * 0.55, 20), _at(0, sockel + h * 0.275, 0))
	_add("kupfer", _zyl(r - 0.1, r, h * 0.45, 20), _at(0, sockel + h * 0.55 + h * 0.225, 0))
	for ry: float in [0.2, 0.62]:
		_add("messing", _torus(r - 0.02, r + 0.04, 22, 6), _at(0, sockel + ry, 0))
	# Haube mit Dampfrohr
	_add("kupfer", _zyl(0.18, r - 0.08, 0.34, 20), _at(0, sockel + h + 0.17, 0))
	_add("kupfer", _zyl(0.12, 0.12, 0.5, 12), _at(0, sockel + h + 0.55, 0))
	_add("kupfer", _zyl(0.12, 0.12, 0.6, 12), _liegend("z", 0, sockel + h + 0.78, 0.28))
	# Griffe und Schauglas
	for sx: float in [-1.0, 1.0]:
		_add("messing", _torus(0.07, 0.13, 12, 6),
			Transform3D(Basis(Vector3.FORWARD, PI / 2.0), Vector3(sx * (r + 0.02), sokel_hilf(sockel, h), 0)))
	_add("messing", _box(Vector3(0.12, 0.3, 0.06)), _at(0, sockel + 0.45, -r + 0.02))
	# Hopfenkorb hängt am Rand
	_add("holz_dunkel", _zyl(0.2, 0.16, 0.26, 12), _at(r + 0.28, sockel + h - 0.1, 0.3))
	_add("hopfen", _kugel(0.05, 8, 5), _at(r + 0.24, sockel + h + 0.06, 0.3))
	_add("hopfen", _kugel(0.05, 8, 5), _at(r + 0.34, sockel + h + 0.04, 0.26))
	_add("hopfen", _kugel(0.05, 8, 5), _at(r + 0.3, sockel + h + 0.05, 0.38))
	_speichern("sudkessel")

## Höhe der Kesselgriffe — eigene kleine Funktion, damit die Formel oben lesbar bleibt
func sokel_hilf(sockel: float, h: float) -> float:
	return sockel + h * 0.62

# ------------------------------------------------------------ Gärfass
## Riesiges Lagerfass, liegend auf zwei Holzböcken: Dauben, vier Eisenreifen,
## Spundloch oben, Zapfhahn vorne, Schild für die Sorte.
## Achse liegt entlang z, Ursprung am Boden, Vorderseite (Zapfhahn) zeigt nach -x.
func _gaerfass() -> void:
	_neu()
	_kellermats()
	var laenge := 3.0
	var r := 0.82
	var mitte_y := r + 0.34
	# Böcke
	for bz: float in [-laenge / 2.0 + 0.5, laenge / 2.0 - 0.5]:
		_add("holz_dunkel", _box(Vector3(1.5, 0.16, 0.3)), _at(0, 0.08, bz))
		for sx: float in [-1.0, 1.0]:
			_add("holz_dunkel", _box(Vector3(0.16, 0.34, 0.26)), _at(sx * 0.6, 0.25, bz))
		_add("holz", _box(Vector3(1.3, 0.1, 0.24)), _at(0, 0.44, bz))
	# Dauben: Bretter im Kreis, in der Mitte dicker (Fassbauch)
	var n := 26
	for i in n:
		var w := TAU * float(i) / float(n)
		var t := Transform3D(Basis(Vector3.FORWARD, w) * Basis(Vector3.RIGHT, PI / 2.0),
			Vector3(sin(w) * (r - 0.04), mitte_y + cos(w) * (r - 0.04), 0))
		_add("holz", _box(Vector3(TAU * r / float(n) + 0.03, laenge, 0.08)), t)
	# Böden
	for bz: float in [-laenge / 2.0 + 0.04, laenge / 2.0 - 0.04]:
		_add("holz_dunkel", _zyl(r - 0.08, r - 0.08, 0.08, 22), _liegend("z", 0, mitte_y, bz))
	# Eisenreifen
	for rz: float in [-laenge / 2.0 + 0.18, -0.55, 0.55, laenge / 2.0 - 0.18]:
		_add("eisen", _torus(r - 0.01, r + 0.06, 26, 6), _liegend("z", 0, mitte_y, rz))
	# Spundloch oben mit Holzstopfen
	_add("holz_dunkel", _zyl(0.13, 0.13, 0.1, 12), _at(0, mitte_y + r - 0.02, 0.1))
	_add("messing", _torus(0.13, 0.17, 12, 6), _at(0, mitte_y + r - 0.04, 0.1))
	# Zapfhahn vorne unten
	_add("messing", _zyl(0.05, 0.05, 0.3, 10), _liegend("x", -r - 0.12, mitte_y - 0.35, 0))
	_add("messing", _zyl(0.035, 0.035, 0.18, 10), _at(-r - 0.24, mitte_y - 0.45, 0))
	_add("holz_dunkel", _box(Vector3(0.05, 0.05, 0.22)), _at(-r - 0.24, mitte_y - 0.28, 0))
	# Schild für die Sorte
	_add("holz", _box(Vector3(0.04, 0.3, 0.5)), _at(-r - 0.02, mitte_y + 0.1, 0))
	_speichern("gaerfass")

# ------------------------------------------------------------ Transportfass
## Tragbares Fass für den Weg vom Keller zur Theke: kleiner, mit Tragegriffen.
func _transportfass() -> void:
	_neu()
	_kellermats()
	var h := 0.72
	var r := 0.3
	var n := 16
	for i in n:
		var w := TAU * float(i) / float(n)
		var t := Transform3D(Basis(Vector3.UP, w), Vector3(sin(w) * (r - 0.02), h / 2.0, cos(w) * (r - 0.02)))
		_add("holz", _box(Vector3(TAU * r / float(n) + 0.02, h, 0.05)), t)
	for ry: float in [0.1, h / 2.0, h - 0.1]:
		_add("eisen", _torus(r - 0.01, r + 0.04, 18, 6), _at(0, ry, 0))
	_add("holz_dunkel", _zyl(r - 0.04, r - 0.04, 0.06, 18), _at(0, 0.04, 0))
	_add("holz_dunkel", _zyl(r - 0.04, r - 0.04, 0.06, 18), _at(0, h - 0.04, 0))
	# Tragegriffe seitlich und Zapfhahn
	for sx: float in [-1.0, 1.0]:
		_add("eisen", _torus(0.05, 0.1, 12, 6),
			Transform3D(Basis(Vector3.FORWARD, PI / 2.0), Vector3(sx * (r + 0.01), h * 0.62, 0)))
	_add("messing", _zyl(0.03, 0.03, 0.16, 10), _liegend("z", 0, 0.2, -r - 0.06))
	_add("holz_dunkel", _zyl(0.09, 0.09, 0.06, 12), _at(0, h + 0.02, 0))
	_speichern("transportfass")
