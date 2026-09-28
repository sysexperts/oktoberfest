extends SceneTree
## Backt Erbrochenes und Urin zu je einem ArrayMesh: unregelmäßige, gewölbte
## Lachen mit Rauschrand, Spritzern und (bei Erbrochenem) Brocken.
## Aufruf: godot --headless --script res://tools/bake_pfuetzen.gd
## Ergebnis: assets/dreck/kotze.tres, assets/dreck/urin.tres (von scenes/mess.tscn benutzt)

const ZIEL := "res://assets/dreck/"

var _rng := RandomNumberGenerator.new()
var _rausch := FastNoiseLite.new()

func _init() -> void:
	_rausch.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_rausch.frequency = 1.0
	_kotze()
	_urin()
	print("Pfützen gebacken.")
	quit()

# ------------------------------------------------------------ Werkzeug
func _mat(glanz: float, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0 - glanz
	m.metallic_specular = 0.7
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, alpha)
	return m

## Flache Lache: Umriss aus Rauschen, Wölbung zur Mitte, Rand rundet ab.
## farbe(t, winkel) liefert die Farbe von Mitte (t=0) bis Rand (t=1).
func _lache(st: SurfaceTool, mitte: Vector3, radius: float, hoehe: float, zacken: float,
		dehnung: Vector2, beulen: float, samen: int, farbe: Callable) -> void:
	const SEG := 72
	const RINGE := 12
	_rausch.seed = samen
	_hub += 0.0008   # jede Lache minimal höher: kein Flimmern, wo sie sich überlappen
	mitte.y += _hub
	var punkte: Array[Vector3] = []
	var farben: Array[Color] = []
	# Mittelpunkt
	punkte.append(mitte + Vector3(0, hoehe, 0))
	farben.append(farbe.call(0.0, 0.0))
	for r in range(1, RINGE + 1):
		var t := float(r) / RINGE
		for s in SEG:
			var w := TAU * s / SEG
			var c := Vector2(cos(w), sin(w))
			var rand := 1.0 + zacken * (_rausch.get_noise_2d(c.x * 0.9, c.y * 0.9)
				+ _rausch.get_noise_2d(c.x * 2.2 + 7.0, c.y * 2.2) * 0.25)
			var rr := radius * rand * t
			var p := Vector3(c.x * rr * dehnung.x, 0.0, c.y * rr * dehnung.y)
			# Oberflächenprofil: flach gewölbt, am Rand rund abfallend (Meniskus)
			var prof := sqrt(maxf(0.0, 1.0 - pow(t, 6.0)))
			var beule := 1.0 + beulen * _rausch.get_noise_2d(p.x * 14.0 + 30.0, p.z * 14.0)
			p.y = hoehe * prof * beule
			punkte.append(mitte + p)
			farben.append(farbe.call(t, w))
	var start := _zaehler
	for i in punkte.size():
		st.set_color(farben[i])
		st.add_vertex(punkte[i])
	_zaehler += punkte.size()
	# Mittelfächer
	for s in SEG:
		st.add_index(start)
		st.add_index(start + 1 + s)
		st.add_index(start + 1 + (s + 1) % SEG)
	for r in range(1, RINGE):
		var a := start + 1 + (r - 1) * SEG
		var b := start + 1 + r * SEG
		for s in SEG:
			var s2 := (s + 1) % SEG
			st.add_index(a + s); st.add_index(b + s); st.add_index(a + s2)
			st.add_index(a + s2); st.add_index(b + s); st.add_index(b + s2)

var _zaehler := 0
var _hub := 0.0

## Unregelmäßiger Brocken: verbeulte, flachgedrückte Kugel
func _brocken(st: SurfaceTool, mitte: Vector3, r: float, farbe: Color, samen: int) -> void:
	const SEG := 10
	const RINGE := 6
	_rausch.seed = samen
	var start := _zaehler
	for i in RINGE + 1:
		var v := PI * i / RINGE
		for s in SEG:
			var w := TAU * s / SEG
			var n := Vector3(sin(v) * cos(w), cos(v), sin(v) * sin(w))
			var d := r * (1.0 + 0.45 * _rausch.get_noise_3d(n.x * 2.0, n.y * 2.0, n.z * 2.0))
			var p := n * d
			p.y *= 0.55
			st.set_color(farbe.lerp(Color(0, 0, 0), 0.25 * (1.0 - n.y) * 0.5))
			st.add_vertex(mitte + p)
	_zaehler += (RINGE + 1) * SEG
	for i in RINGE:
		for s in SEG:
			var s2 := (s + 1) % SEG
			var a := start + i * SEG
			var b := start + (i + 1) * SEG
			st.add_index(a + s); st.add_index(b + s); st.add_index(a + s2)
			st.add_index(a + s2); st.add_index(b + s); st.add_index(b + s2)

func _st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_zaehler = 0
	_hub = 0.0
	return st

func _fertig(am: ArrayMesh, st: SurfaceTool, mat: Material) -> void:
	st.generate_normals()
	st.commit(am)
	am.surface_set_material(am.get_surface_count() - 1, mat)

# ------------------------------------------------------------ Erbrochenes
func _kotze() -> void:
	_rng.seed = 4711
	var am := ArrayMesh.new()
	var gruen_dunkel := Color(0.19, 0.31, 0.04)
	var gruen := Color(0.36, 0.49, 0.09)
	var gruen_hell := Color(0.5, 0.58, 0.15)
	var brei := func(t: float, _w: float) -> Color:
		# Mitte dicker und heller, Rand dünn, dunkler und glasig
		return gruen_hell.lerp(gruen, smoothstep(0.0, 0.6, t)).lerp(gruen_dunkel, smoothstep(0.7, 1.0, t))
	var st := _st()
	_lache(st, Vector3.ZERO, 0.42, 0.05, 0.22, Vector2(1.15, 0.9), 0.5, 11, brei)
	_lache(st, Vector3(0.38, 0.0, 0.18), 0.2, 0.035, 0.25, Vector2(1.3, 0.8), 0.5, 12, brei)
	_lache(st, Vector3(-0.3, 0.0, -0.25), 0.16, 0.03, 0.25, Vector2(0.9, 1.2), 0.5, 13, brei)
	# Spritzer rundherum, nach außen hin kleiner
	for i in 14:
		var w := _rng.randf() * TAU
		var d := _rng.randf_range(0.5, 0.85)
		var r := lerpf(0.07, 0.025, (d - 0.5) / 0.35)
		_lache(st, Vector3(cos(w) * d * 1.1, 0.0, sin(w) * d * 0.9), r, 0.012, 0.18,
			Vector2(_rng.randf_range(0.8, 1.4), _rng.randf_range(0.8, 1.2)), 0.0, 100 + i, brei)
	_fertig(am, st, _mat(0.75, 0.97))
	# Brocken: Essensreste (gelblich, beige, ein paar orange Stücke)
	var st2 := _st()
	var toene := [Color(0.78, 0.74, 0.35), Color(0.7, 0.62, 0.4), Color(0.85, 0.5, 0.15), Color(0.55, 0.68, 0.2)]
	for i in 40:
		var w := _rng.randf() * TAU
		var d := sqrt(_rng.randf()) * 0.38
		var p := Vector3(cos(w) * d * 1.1, 0.0, sin(w) * d * 0.9)
		p.y = 0.052 * sqrt(maxf(0.0, 1.0 - pow(d / 0.42, 6.0))) + 0.004
		_brocken(st2, p, _rng.randf_range(0.014, 0.04), toene[_rng.randi() % toene.size()], 200 + i)
	_fertig(am, st2, _mat(0.55, 1.0))
	ResourceSaver.save(am, ZIEL + "kotze.tres")

# ------------------------------------------------------------ Urin
func _urin() -> void:
	_rng.seed = 815
	var am := ArrayMesh.new()
	var kern := Color(0.98, 0.8, 0.04)
	var rand := Color(0.82, 0.52, 0.02)
	var lache := func(t: float, _w: float) -> Color:
		# Dünner Film: Mitte kräftig gelb, Rand bernsteinfarben (Trocknungsrand)
		var c := kern.lerp(Color(1.0, 0.9, 0.2), 0.3 * (1.0 - t))
		return c.lerp(rand, smoothstep(0.82, 1.0, t))
	var st := _st()
	_lache(st, Vector3.ZERO, 0.5, 0.012, 0.18, Vector2(1.2, 0.85), 0.0, 21, lache)
	_lache(st, Vector3(0.48, 0.0, 0.2), 0.24, 0.01, 0.2, Vector2(1.2, 0.9), 0.0, 22, lache)
	# Rinnsal: eine Kette kleiner, ineinanderlaufender Lachen
	var p := Vector3(-0.35, 0.0, -0.3)
	var r := 0.12
	for i in 16:
		_lache(st, p, r, 0.004, 0.12, Vector2(1.0, 1.4), 0.0, 30 + i, lache)
		p += Vector3(_rng.randf_range(-0.035, 0.01), 0.0, -0.05)
		r *= 0.93
	# Ein paar Tropfen daneben
	for i in 7:
		var w := _rng.randf() * TAU
		var d := _rng.randf_range(0.7, 0.95)
		_lache(st, Vector3(cos(w) * d, 0.0, sin(w) * d * 0.8), _rng.randf_range(0.015, 0.035),
			0.006, 0.2, Vector2.ONE, 0.0, 50 + i, lache)
	_fertig(am, st, _mat(0.95, 1.0))
	ResourceSaver.save(am, ZIEL + "urin.tres")
