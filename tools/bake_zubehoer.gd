extends SceneTree
## Modelliert Zubehör für die Figuren (Maße vom Kopf von character2, gemessen:
## Walze mit Radius 0,19 m, runde Kuppe ab 1,53 m bis 1,72 m, Mund bei 1,25 m,
## Kragen ab 1,20 m). Alles in Modellkoordinaten (+z = vorn).
##   tirolerhut.tres — Filzkrone mit Kniff, geschwungene Krempe, Hutband mit
##                      Kordel, Feder und Gamsbart
##   vollbart.tres    — Vollbart, der der Kopfform folgt, mit Strähnen und
##                      gewelltem Rand, dazu ein gezwirbelter Schnurrbart
##   *_schwarz.tres   — dieselben Teile in Schwarz (schwarzer Filz, Silberkordel)
##   brille.tres      — runde Nickelbrille mit klaren Gläsern
##   konrad_hut.tres / konrad_bart.tres — nur für Konrad, den Rivalen (siehe unten)
##   sonnenbrille.tres — breite Sonnenbrille mit dunklen, spiegelnden Gläsern
## Oberflächen je Material (Filz, Band, Kordel, Feder, Gamsbart / Bart,
## Schnurrbart) — in den Zubehör-Szenen per Material umfärbbar.
## Aufruf: godot --headless --path . --script res://tools/bake_zubehoer.gd

const ZIEL := "res://assets/zubehoer/"
const KOPF_R := 0.19
const KUPPE_Y := 1.53

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZIEL))
	# Filz, Filz dunkel, Band, Kordel
	_hut("tirolerhut", [Color(0.22, 0.33, 0.19), Color(0.17, 0.27, 0.15), Color(0.33, 0.19, 0.09), Color(0.85, 0.72, 0.4)])
	_hut("tirolerhut_schwarz", [Color(0.035, 0.035, 0.04), Color(0.022, 0.022, 0.026), Color(0.012, 0.012, 0.014), Color(0.72, 0.72, 0.74)])
	# Bart, Rand, Schnurrbart
	_bart("vollbart", [Color(0.34, 0.2, 0.1), Color(0.24, 0.13, 0.06), Color(0.3, 0.17, 0.08)])
	_bart("vollbart_schwarz", [Color(0.05, 0.045, 0.045), Color(0.025, 0.022, 0.022), Color(0.04, 0.036, 0.036)])
	_brille("brille", Color(0.7, 0.68, 0.62), Color(0.85, 0.92, 1.0, 0.18), false)
	_brille("sonnenbrille", Color(0.03, 0.03, 0.03), Color(0.02, 0.025, 0.03, 0.9), true)
	_konrad_hut("konrad_hut")
	_konrad_bart("konrad_bart")
	# Rosen, Rosen-Rand, Knospen
	_kranz("rosenkranz", [Color(0.82, 0.1, 0.16), Color(0.55, 0.05, 0.1), Color(0.96, 0.82, 0.86)])
	_kranz("rosenkranz_rosa", [Color(0.95, 0.5, 0.68), Color(0.78, 0.3, 0.5), Color(1.0, 0.95, 0.85)])
	print("Zubehör gebacken.")
	quit()

# ------------------------------------------------------------ Werkzeug
func _kopf_r(y: float) -> float:
	if y <= KUPPE_Y:
		return KOPF_R
	return sqrt(maxf(0.0, KOPF_R * KOPF_R - (y - KUPPE_Y) * (y - KUPPE_Y)))

## Gitterfläche: f(u, v) -> [Position, Farbe], u und v jeweils 0..1
func _flaeche(st: SurfaceTool, nu: int, nv: int, f: Callable, umdrehen := false) -> void:
	var p := []
	for j in nv + 1:
		for i in nu + 1:
			p.append(f.call(float(i) / nu, float(j) / nv))
	for j in nv:
		for i in nu:
			var a := j * (nu + 1) + i
			var q := [a, a + 1, a + nu + 2, a + nu + 1]
			var reihen := [[0, 1, 2], [0, 2, 3]] if not umdrehen else [[0, 2, 1], [0, 3, 2]]
			for tri in reihen:
				for k in tri:
					var e: Array = p[q[k]]
					st.set_color(e[1])
					st.add_vertex(e[0])

## Röhre entlang einer Kurve: punkte, radien (gleiche Länge), Farbe
func _roehre(st: SurfaceTool, punkte: Array, radien: Array, farbe: Color, seg := 12) -> void:
	var ringe := []
	for i in punkte.size():
		var p: Vector3 = punkte[i]
		var t: Vector3 = (punkte[mini(i + 1, punkte.size() - 1)] - punkte[maxi(i - 1, 0)]).normalized()
		var hilf := Vector3.UP if absf(t.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var n1 := t.cross(hilf).normalized()
		var n2 := t.cross(n1).normalized()
		var ring := []
		for s in seg:
			var w := TAU * s / seg
			ring.append(p + (n1 * cos(w) + n2 * sin(w)) * float(radien[i]))
		ringe.append(ring)
	for i in ringe.size() - 1:
		for s in seg:
			var s2 := (s + 1) % seg
			for v in [ringe[i][s], ringe[i + 1][s], ringe[i + 1][s2], ringe[i][s], ringe[i + 1][s2], ringe[i][s2]]:
				st.set_color(farbe)
				st.add_vertex(v)
	# Enden zu
	for ende in [0, ringe.size() - 1]:
		var mitte: Vector3 = punkte[ende]
		for s in seg:
			var a: Vector3 = ringe[ende][s]
			var b: Vector3 = ringe[ende][(s + 1) % seg]
			for v in ([mitte, b, a] if ende == 0 else [mitte, a, b]):
				st.set_color(farbe)
				st.add_vertex(v)

func _neu() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

func _fertig(am: ArrayMesh, st: SurfaceTool, name: String, rauh: float) -> void:
	st.generate_normals()
	st.commit(am)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = rauh
	m.resource_name = name
	m.cull_mode = BaseMaterial3D.CULL_DISABLED if name in ["Filz", "Feder", "Glas"] else BaseMaterial3D.CULL_BACK
	if name == "Glas":
		# durchsichtig über das Alpha der Vertexfarbe, glänzend
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.metallic_specular = 1.0
	elif name == "Rahmen":
		m.metallic = 0.6
	elif name == "Schnalle":
		m.metallic = 0.85
		m.metallic_specular = 0.8
	am.surface_set_material(am.get_surface_count() - 1, m)
	am.surface_set_name(am.get_surface_count() - 1, name)

# ------------------------------------------------------------ Tirolerhut
const HUT_Y := 1.612          # Unterkante der Krone, hier ist der Kopf r ≈ 0,17
const KRONE_H := 0.135
const SEG := 64

func _krone_r(w: float, h: float) -> float:
	# oben schmaler, vorn eingedrückt (die typische Kniffform)
	var r := lerpf(0.182, 0.128, pow(h, 1.2))
	var vorn := exp(-pow(wrapf(w, -PI, PI), 2.0) / 0.25)
	r *= 1.0 - 0.13 * vorn * smoothstep(0.35, 1.0, h)
	# leicht oval: vorn-hinten länger
	return r * (1.0 + 0.05 * absf(cos(w)))

func _hut(datei: String, farben: Array) -> void:
	var am := ArrayMesh.new()
	# gleiche Zufallsfolge je Hut, damit der Gamsbart in jeder Farbe gleich aussieht
	_rng.seed = 1234
	var filz: Color = farben[0]
	var filz_d: Color = farben[1]
	# Krone: Mantel
	var st := _neu()
	_flaeche(st, SEG, 14, func(u: float, v: float) -> Array:
		var w := u * TAU
		var r := _krone_r(w, v)
		var fleck := 0.04 * sin(w * 7.0 + v * 5.0)
		return [Vector3(sin(w) * r, HUT_Y + v * KRONE_H, cos(w) * r), filz.lerp(filz_d, 0.3 * v + fleck)], true)
	# Krone: Deckel mit Kniff (Längsdelle von vorn nach hinten)
	_flaeche(st, SEG, 10, func(u: float, v: float) -> Array:
		var w := u * TAU
		var rho := 1.0 - v
		var r := _krone_r(w, 1.0) * rho
		var x := sin(w) * r
		var z := cos(w) * r
		var y := HUT_Y + KRONE_H + 0.03 * (1.0 - rho * rho) - 0.034 * exp(-pow(x / 0.045, 2.0)) * (1.0 - rho * rho * 0.7)
		return [Vector3(x, y, z), filz_d], true)
	# Krempe: oben, unten, Rand — seitlich hochgeschlagen, vorn und hinten gesenkt
	var krempe := func(u: float, aussen: float, unten: bool) -> Array:
		var w := u * TAU
		var innen := _krone_r(w, 0.0) - 0.004
		var breite := 0.07 + 0.012 * absf(cos(w))
		var r := innen + breite * aussen
		var hoch := 0.03 * pow(absf(sin(w)), 2.0) - 0.012 * pow(absf(cos(w)), 2.0) - 0.008 * cos(w)
		var y := HUT_Y + 0.004 + hoch * pow(aussen, 1.6) - (0.009 if unten else 0.0)
		return [Vector3(sin(w) * r, y, cos(w) * r), filz_d if unten else filz]
	_flaeche(st, SEG, 6, func(u: float, v: float) -> Array: return krempe.call(u, v, false), true)
	_flaeche(st, SEG, 6, func(u: float, v: float) -> Array: return krempe.call(u, v, true))
	_flaeche(st, SEG, 1, func(u: float, v: float) -> Array:
		var a: Array = krempe.call(u, 1.0, false)
		var b: Array = krempe.call(u, 1.0, true)
		return [(a[0] as Vector3).lerp(b[0], v), filz_d], true)
	_fertig(am, st, "Filz", 0.95)

	# Hutband + Kordel
	st = _neu()
	var band: Color = farben[2]
	_flaeche(st, SEG, 3, func(u: float, v: float) -> Array:
		var w := u * TAU
		var h := v * 0.26
		var r := _krone_r(w, h) + 0.004
		return [Vector3(sin(w) * r, HUT_Y + h * KRONE_H, cos(w) * r), band.darkened(0.15 * v)], true)
	_fertig(am, st, "Band", 0.7)
	st = _neu()
	var kordel := []
	var kr := []
	for i in SEG + 1:
		var w := TAU * i / SEG
		var r := _krone_r(w, 0.27) + 0.007
		kordel.append(Vector3(sin(w) * r, HUT_Y + 0.27 * KRONE_H + 0.002 * sin(w * 24.0), cos(w) * r))
		kr.append(0.0045)
	_roehre(st, kordel, kr, farben[3], 8)
	_fertig(am, st, "Kordel", 0.6)

	# Feder: gebogene, spitz zulaufende Fahne mit Kiel, links hinten im Band
	st = _neu()
	var ansatz := Vector3(-0.155, HUT_Y + 0.03, -0.09)
	var kiel := []
	for i in 13:
		var t := i / 12.0
		kiel.append(ansatz + Vector3(-0.02 * t, 0.2 * t, -0.07 * t - 0.03 * t * t) + Vector3(0, 0, 0.02 * sin(t * PI)))
	_flaeche(st, 12, 4, func(u: float, v: float) -> Array:
		var i := int(round(u * 12.0))
		var p: Vector3 = kiel[i]
		var breite := 0.022 * sin(pow(u, 0.7) * PI) * (1.0 - 0.3 * u)
		var seite := (v - 0.5) * 2.0
		var q := p + Vector3(0, 0, 1).rotated(Vector3.UP, -0.4) * breite * seite + Vector3(-0.004, 0, 0) * absf(seite)
		var farbe := Color(0.95, 0.93, 0.86).lerp(Color(0.25, 0.22, 0.2), smoothstep(0.7, 1.0, u))
		return [q, farbe])
	_flaeche(st, 12, 4, func(u: float, v: float) -> Array:
		var i := int(round(u * 12.0))
		var p: Vector3 = kiel[i]
		var breite := 0.022 * sin(pow(u, 0.7) * PI) * (1.0 - 0.3 * u)
		var seite := (v - 0.5) * 2.0
		var q := p + Vector3(0, 0, 1).rotated(Vector3.UP, -0.4) * breite * seite + Vector3(-0.004, 0, 0) * absf(seite)
		return [q, Color(0.85, 0.83, 0.78)], true)
	var kr2 := []
	for i in kiel.size():
		kr2.append(lerpf(0.003, 0.0012, i / 12.0))
	_roehre(st, kiel, kr2, Color(0.9, 0.88, 0.8), 6)
	_fertig(am, st, "Feder", 0.9)

	# Gamsbart: Büschel dünner Haare hinten links, unten dunkel, Spitzen hell
	st = _neu()
	var fuss := Vector3(-0.12, HUT_Y + 0.035, -0.14)
	for i in 70:
		var w := _rng.randf_range(-0.9, 0.9)
		var neig := _rng.randf_range(0.1, 0.55)
		var laenge := _rng.randf_range(0.1, 0.15)
		var richtung := Vector3(sin(w) * neig - 0.25, 1.0, cos(w) * neig * 0.6 - 0.35).normalized()
		var pts := []
		var rad := []
		for k in 5:
			var t := k / 4.0
			pts.append(fuss + Vector3(_rng.randf_range(-0.012, 0.012), 0, _rng.randf_range(-0.012, 0.012)) * (1.0 - t)
				+ richtung * laenge * t + Vector3(0, -0.03 * t * t, 0))
			rad.append(lerpf(0.0028, 0.0008, t))
		_roehre(st, pts, rad, Color(0.14, 0.11, 0.08).lerp(Color(0.8, 0.74, 0.62), _rng.randf_range(0.2, 0.6)), 4)
	var knoten := []
	var kn_r := []
	for k in 3:
		knoten.append(fuss + Vector3(0, -0.01 + k * 0.01, 0))
		kn_r.append([0.011, 0.014, 0.009][k])
	_roehre(st, knoten, kn_r, Color(0.7, 0.62, 0.35), 10)
	_fertig(am, st, "Gamsbart", 0.9)
	ResourceSaver.save(am, ZIEL + datei + ".tres")
	print("  ", datei, ": ", am.get_surface_count(), " Oberflächen")

# ------------------------------------------------------------ Vollbart
const BART_W := 1.62          # halber Winkel (rad) bis zu den Koteletten

func _bart_oben(w: float) -> float:
	# vorn unter dem Mund, unter den Augen etwas höher, Koteletten bis 1,40
	var a := absf(w)
	return lerpf(1.232, 1.29, smoothstep(0.15, 0.75, a)) + 0.1 * smoothstep(0.95, BART_W, a)

func _bart_unten(w: float) -> float:
	# vorn als runder Spitzbart über den Kragen, seitlich kurz am Kiefer
	var a := absf(w)
	var y := lerpf(1.05, 1.225, pow(smoothstep(0.0, 1.35, a), 0.9)) + 0.03 * smoothstep(1.2, BART_W, a)
	return y + 0.01 * sin(w * 11.0) * (1.0 - smoothstep(1.1, BART_W, a))

func _innen_r(y: float) -> float:
	# am Gesicht anliegend, unten über den Kragen hinweg
	return lerpf(0.232, 0.194, smoothstep(1.17, 1.23, y))

func _dicke(w: float, v: float) -> float:
	var a := absf(w)
	return (0.012 + 0.04 * pow(v, 0.8)) * lerpf(1.0, 0.45, smoothstep(0.5, BART_W, a))

func _bart_punkt(u: float, v: float, aussen: bool, farbe: Color) -> Array:
	var w := lerpf(-BART_W, BART_W, u)
	var y := lerpf(_bart_oben(w), _bart_unten(w), v)
	var r := _innen_r(y) + 0.002
	if aussen:
		# Strähnen: senkrechte Rillen, zur Spitze hin stärker
		var rille := 0.005 * sin(w * 46.0 + sin(v * 7.0) * 1.3) * smoothstep(0.1, 0.6, v)
		r += _dicke(w, v) + rille
		# Kanten weich auf die Haut laufen lassen
		r -= _dicke(w, v) * (1.0 - smoothstep(0.0, 0.12, v)) * 0.8
	var p := Vector3(sin(w) * r, y, cos(w) * r)
	# Spitze leicht nach vorn-unten
	p.z += 0.03 * pow(v, 2.0) * pow(cos(w), 4.0) if aussen else 0.0
	var dunkel := 0.25 * (0.5 + 0.5 * sin(w * 46.0 + v * 3.0)) + 0.15 * v
	return [p, farbe.darkened(dunkel)]

func _bart(datei: String, farben: Array) -> void:
	var am := ArrayMesh.new()
	var st := _neu()
	var nu := 90
	var nv := 24
	var farbe: Color = farben[0]
	_flaeche(st, nu, nv, func(u: float, v: float) -> Array: return _bart_punkt(u, v, true, farbe))
	_flaeche(st, nu, nv, func(u: float, v: float) -> Array: return _bart_punkt(u, v, false, farbe), true)
	# Unterkante schließen (gewellter Rand)
	_flaeche(st, nu, 1, func(u: float, v: float) -> Array:
		var a: Array = _bart_punkt(u, 1.0, true, farbe)
		var b: Array = _bart_punkt(u, 1.0, false, farbe)
		return [(a[0] as Vector3).lerp(b[0], v), farben[1]], true)
	_fertig(am, st, "Bart", 0.95)

	# Schnurrbart: zwei gezwirbelte Hälften, in der Mitte dick, Spitzen nach oben gedreht
	st = _neu()
	for seite in [-1.0, 1.0]:
		var pts := []
		var rad := []
		for i in 21:
			var t := i / 20.0
			var w: float = seite * lerpf(0.02, 0.62, t)
			var r := 0.2 + 0.012 * sin(t * PI) - 0.015 * t
			var y := 1.258 - 0.012 * sin(t * PI * 0.9) + 0.05 * pow(smoothstep(0.6, 1.0, t), 1.5)
			var p := Vector3(sin(w) * r, y, cos(w) * r)
			# Spitze kringelt sich nach oben und leicht nach innen
			p += Vector3(float(seite) * -0.012, 0.0, 0.0) * smoothstep(0.85, 1.0, t)
			pts.append(p)
			rad.append(lerpf(0.019, 0.0035, pow(t, 0.8)) * (1.0 + 0.25 * sin(t * PI * 0.8)))
		_roehre(st, pts, rad, farben[2], 14)
	_fertig(am, st, "Schnurrbart", 0.9)
	ResourceSaver.save(am, ZIEL + datei + ".tres")
	print("  ", datei, ": ", am.get_surface_count(), " Oberflächen")

# ------------------------------------------------------------ Brillen
## Augen von character2 (tools/kopf_messen.gd): Mitte x ±0,075, y 1,395,
## vorderster Punkt z 0,20 (Pupillen stehen weiter vor, daher Gläser bei 0,25). Kopf an den Schläfen halb 0,18 breit.
const AUGE_X := 0.077
const AUGE_Y := 1.397
const GLAS_Z := 0.252

## Glas etwas nach hinten biegen, wie der Kopf: außen weiter hinten
func _glas_z(x: float) -> float:
	return GLAS_Z - 0.03 * pow(absf(x) / 0.14, 2.0)

## Umriss eines Glases: rund (Nickelbrille) oder breit mit fast geradem
## Oberrand (Sonnenbrille). t 0..1 einmal herum.
func _glas_rand(t: float, seite: float, sonne: bool) -> Vector3:
	var w := t * TAU
	var x := cos(w)
	var y := sin(w)
	var p: Vector2
	if sonne:
		# oben flach, unten tropfenförmig zur Wange hin
		var ry := 0.044 if y < 0.0 else 0.03
		p = Vector2(x * 0.058 * (1.0 + 0.12 * maxf(0.0, -y) * x * seite), y * ry + 0.008)
	else:
		p = Vector2(x, y) * 0.048
	var gx := seite * (AUGE_X + (0.006 if sonne else 0.0)) + p.x
	return Vector3(gx, AUGE_Y + p.y, _glas_z(gx))

func _brille(datei: String, rahmen: Color, glas: Color, sonne: bool) -> void:
	var am := ArrayMesh.new()
	var st := _neu()
	var n := 48
	var dicke := 0.0055 if sonne else 0.0028
	for seite: float in [-1.0, 1.0]:
		# Fassung: geschlossener Ring ums Glas
		var ring := []
		var rr := []
		for i in n + 1:
			ring.append(_glas_rand(float(i) / n, seite, sonne))
			rr.append(dicke)
		_roehre(st, ring, rr, rahmen, 8)
		# Bügel: vom äußeren Rand an der Schläfe entlang nach hinten, hinterm Ohr abwärts
		var start := _glas_rand(0.0 if seite > 0.0 else 0.5, seite, sonne) + Vector3(0, 0.012 if sonne else 0.0, 0)
		var buegel := []
		var br := []
		for i in 13:
			var t := i / 12.0
			var x := seite * lerpf(absf(start.x) + 0.004, 0.196, smoothstep(0.0, 0.35, t))
			var z := lerpf(start.z, -0.07, t)
			var y := lerpf(start.y, AUGE_Y + 0.004, t) - 0.03 * smoothstep(0.8, 1.0, t)
			buegel.append(Vector3(x, y, z))
			br.append(dicke * lerpf(1.0, 0.8, t))
		_roehre(st, buegel, br, rahmen, 8)
	# Steg über der Nase: kleiner Bogen zwischen den Gläsern
	var innen := _glas_rand(0.5, 1.0, sonne)
	var steg := []
	var sr := []
	for i in 9:
		var t := i / 8.0
		var x := lerpf(-innen.x, innen.x, t)
		steg.append(Vector3(x, AUGE_Y + (0.02 if sonne else 0.006) + 0.01 * sin(t * PI), _glas_z(x) + 0.003))
		sr.append(dicke * 0.9)
	_roehre(st, steg, sr, rahmen, 8)
	if sonne:
		# Oberkante als durchgehende, kräftige Leiste
		var leiste := []
		var lr := []
		var aussen := absf(_glas_rand(0.0, 1.0, true).x) + 0.004
		for i in 25:
			var x := lerpf(-aussen, aussen, i / 24.0)
			leiste.append(Vector3(x, AUGE_Y + 0.038, _glas_z(x) + 0.002))
			lr.append(0.0065)
		_roehre(st, leiste, lr, rahmen, 8)
	_fertig(am, st, "Rahmen", 0.35)
	# Gläser: Fächer aus der Mitte zum Rand
	st = _neu()
	for seite: float in [-1.0, 1.0]:
		var mx := seite * (AUGE_X + (0.006 if sonne else 0.0))
		var mitte := Vector3(mx, AUGE_Y + (0.004 if sonne else 0.0), _glas_z(mx) + 0.003)
		for i in n:
			for v in [mitte, _glas_rand(float(i) / n, seite, sonne), _glas_rand(float(i + 1) / n, seite, sonne)]:
				st.set_color(glas)
				st.add_vertex(v)
	_fertig(am, st, "Glas", 0.05)
	ResourceSaver.save(am, ZIEL + datei + ".tres")
	print("  ", datei, ": ", am.get_surface_count(), " Oberflächen")

# ------------------------------------------------------------ Konrad (der Rivale)
## Konrad soll man ansehen, dass er nichts Gutes im Schild führt: hoher
## schwarzer Hut, tief in die Stirn gezogen, weinrotes Band mit Goldschnalle
## und Fasanenfedern; dazu schwere, zornig gestellte Brauen (sie decken die
## gutmütigen Brauen des Modells zu), ein dünner, hochgezwirbelter Schnurrbart
## und ein spitzer Kinnbart.
const K_HOEHE := 0.235
const K_SCHWARZ := Color(0.04, 0.037, 0.04)
const K_ROT := Color(0.33, 0.028, 0.045)
const K_GOLD := Color(0.86, 0.66, 0.24)

## Röhre mit ovalem Querschnitt: `quer` gibt die Richtung der Breite vor (wird
## senkrecht zur Kurve gestellt), radien_a in dieser Richtung, radien_b quer dazu.
## farbe(i, s) -> Color, i = Punkt entlang der Kurve, s = 0..1 um den Ring.
func _oval(st: SurfaceTool, punkte: Array, radien_a: Array, radien_b: Array, quer: Vector3, farbe: Callable, seg := 14) -> void:
	var ringe := []
	for i in punkte.size():
		var p: Vector3 = punkte[i]
		var t: Vector3 = (punkte[mini(i + 1, punkte.size() - 1)] - punkte[maxi(i - 1, 0)]).normalized()
		var n1 := (quer - t * quer.dot(t)).normalized()
		var n2 := t.cross(n1).normalized()
		var ring := []
		for s in seg:
			var w := TAU * s / seg
			ring.append(p + n1 * cos(w) * float(radien_a[i]) + n2 * sin(w) * float(radien_b[i]))
		ringe.append(ring)
	for i in ringe.size() - 1:
		for s in seg:
			var s2 := (s + 1) % seg
			var ecken := [[i, s], [i + 1, s], [i + 1, s2], [i, s], [i + 1, s2], [i, s2]]
			for e: Array in ecken:
				st.set_color(farbe.call(e[0], float(e[1]) / seg))
				st.add_vertex(ringe[e[0]][e[1]])
	for ende in [0, ringe.size() - 1]:
		var mitte: Vector3 = punkte[ende]
		for s in seg:
			var a: Vector3 = ringe[ende][s]
			var b: Vector3 = ringe[ende][(s + 1) % seg]
			for v in ([mitte, b, a] if ende == 0 else [mitte, a, b]):
				st.set_color(farbe.call(ende, 0.0))
				st.add_vertex(v)

func _k_krone_r(w: float, h: float) -> float:
	# unten weit wie der Kopf, in der Mitte tailliert, oben wieder etwas ausgestellt
	var r := lerpf(0.184, 0.158, smoothstep(0.0, 0.5, h)) + 0.016 * smoothstep(0.55, 1.0, h)
	return r * (1.0 + 0.05 * absf(cos(w)))

func _k_krempe(u: float, aussen: float, unten: bool, filz: Color, filz_d: Color) -> Array:
	var w := u * TAU
	var innen := _k_krone_r(w, 0.0) - 0.004
	var breite := 0.082 + 0.03 * pow(maxf(0.0, cos(w)), 2.0) + 0.012 * pow(maxf(0.0, -cos(w)), 2.0)
	var r := innen + breite * aussen
	# Seiten scharf hochgeschlagen, vorn als Schirm tief über die Augen gezogen
	var hoch := 0.045 * pow(absf(sin(w)), 2.5) - 0.038 * pow(maxf(0.0, cos(w)), 3.0) + 0.012 * pow(maxf(0.0, -cos(w)), 2.0)
	var y := HUT_Y + 0.004 + hoch * pow(aussen, 1.4) - (0.008 if unten else 0.0)
	return [Vector3(sin(w) * r, y, cos(w) * r), filz_d if unten else filz.lerp(filz_d, 0.35 * aussen)]

func _konrad_hut(datei: String) -> void:
	var am := ArrayMesh.new()
	var filz := K_SCHWARZ
	var filz_d := Color(0.02, 0.018, 0.02)
	var st := _neu()
	# Krone: Mantel
	_flaeche(st, SEG, 18, func(u: float, v: float) -> Array:
		var w := u * TAU
		var r := _k_krone_r(w, v)
		var fleck := 0.05 * sin(w * 9.0 + v * 4.0)
		return [Vector3(sin(w) * r, HUT_Y + v * K_HOEHE, cos(w) * r), filz.lerp(filz_d, 0.25 * (1.0 - v) + fleck)], true)
	# Deckel: flach, mit umlaufender Kante und leichter Mulde
	_flaeche(st, SEG, 10, func(u: float, v: float) -> Array:
		var w := u * TAU
		var rho := 1.0 - v
		var r := _k_krone_r(w, 1.0) * rho
		var y := HUT_Y + K_HOEHE + 0.006 * smoothstep(0.75, 0.95, rho) * (1.0 - smoothstep(0.95, 1.0, rho)) - 0.012 * (1.0 - rho * rho)
		return [Vector3(sin(w) * r, y, cos(w) * r), filz_d.lerp(filz, 0.5 * rho)], true)
	# Krempe
	_flaeche(st, SEG, 8, func(u: float, v: float) -> Array: return _k_krempe(u, v, false, filz, filz_d), true)
	_flaeche(st, SEG, 8, func(u: float, v: float) -> Array: return _k_krempe(u, v, true, filz, filz_d))
	_flaeche(st, SEG, 1, func(u: float, v: float) -> Array:
		var a: Array = _k_krempe(u, 1.0, false, filz, filz_d)
		var b: Array = _k_krempe(u, 1.0, true, filz, filz_d)
		return [(a[0] as Vector3).lerp(b[0], v), filz_d], true)
	_fertig(am, st, "Filz", 0.92)

	# Band: breit, weinrot, mit Falten
	st = _neu()
	var band_h := 0.3
	_flaeche(st, SEG, 4, func(u: float, v: float) -> Array:
		var w := u * TAU
		var h := 0.015 + v * band_h
		var r := _k_krone_r(w, h) + 0.0045
		var falte := 0.12 * sin(v * PI * 3.0) + 0.06 * sin(w * 5.0)
		return [Vector3(sin(w) * r, HUT_Y + h * K_HOEHE, cos(w) * r), K_ROT.darkened(0.18 + falte)], true)
	_fertig(am, st, "Band", 0.9)

	# Schnalle und Goldborte: Metall
	st = _neu()
	for rand: float in [0.015, 0.015 + band_h]:
		var borte := []
		var br := []
		for i in SEG + 1:
			var w := TAU * i / SEG
			var r := _k_krone_r(w, rand) + 0.006
			borte.append(Vector3(sin(w) * r, HUT_Y + rand * K_HOEHE, cos(w) * r))
			br.append(0.0032)
		_roehre(st, borte, br, K_GOLD, 6)
	# Schnalle vorn, leicht zur Seite gerückt: Rahmen aus vier Stäben und ein Dorn
	var sw := 0.3            # Mitte der Schnalle (Winkel)
	var sb := 0.2            # halbe Breite (Winkel)
	var ecke := func(dw: float, h: float) -> Vector3:
		var w: float = sw + dw
		var r := _k_krone_r(w, h) + 0.013
		return Vector3(sin(w) * r, HUT_Y + h * K_HOEHE, cos(w) * r)
	var unten_h := -0.01
	var oben_h := band_h + 0.04
	for stab: Array in [[-sb, unten_h, sb, unten_h], [-sb, oben_h, sb, oben_h], [-sb, unten_h, -sb, oben_h], [sb, unten_h, sb, oben_h]]:
		var pts := []
		var rr := []
		for i in 7:
			var t := i / 6.0
			pts.append(ecke.call(lerpf(stab[0], stab[2], t), lerpf(stab[1], stab[3], t)))
			rr.append(0.0062)
		_roehre(st, pts, rr, K_GOLD, 8)
	var dorn := []
	var dr := []
	for i in 5:
		var t := i / 4.0
		dorn.append(ecke.call(lerpf(-sb, sb * 0.75, t), lerpf(unten_h, oben_h, 0.5)) + Vector3(0, 0, 0.004))
		dr.append(lerpf(0.0045, 0.002, t))
	_roehre(st, dorn, dr, K_GOLD.lightened(0.15), 6)
	_fertig(am, st, "Schnalle", 0.3)

	# Federn: eine lange, dunkelrot gebänderte Fasanenfeder und eine kurze schwarze,
	# links im Band, weit nach hinten gestrichen
	st = _neu()
	for feder: Array in [[Vector3(-0.168, HUT_Y + 0.05, 0.035), 0.36, 0.075, true], [Vector3(-0.172, HUT_Y + 0.045, -0.02), 0.22, 0.05, false]]:
		var ansatz: Vector3 = feder[0]
		var lang: float = feder[1]
		var breit_max: float = feder[2]
		var rot: bool = feder[3]
		var kiel := []
		for i in 17:
			var t := i / 16.0
			kiel.append(ansatz + Vector3(-0.03 * t, lang * (0.62 * t - 0.36 * t * t), -lang * (0.3 * t + 0.62 * t * t)))
		for rueck in [false, true]:
			_flaeche(st, 16, 6, func(u: float, v: float) -> Array:
				var i := int(round(u * 16.0))
				var p: Vector3 = kiel[i]
				var t: Vector3 = ((kiel[mini(i + 1, 16)] as Vector3) - (kiel[maxi(i - 1, 0)] as Vector3)).normalized()
				# Fahne um den Kiel gedreht: von vorn und von der Seite gleich gut zu sehen
				var quer := t.cross(Vector3.RIGHT).normalized().rotated(t, 0.95)
				var breite := breit_max * sin(pow(u, 0.65) * PI * 0.94) * (1.0 - 0.15 * u)
				var seite := (v - 0.5) * 2.0
				# Fahne leicht gewölbt und an den Rändern ausgefranst
				var q := p + quer * breite * seite * (1.0 + 0.06 * sin(u * 60.0 + seite * 3.0)) + Vector3(-0.006, 0, 0) * (1.0 - seite * seite)
				var farbe := Color(0.05, 0.045, 0.05)
				if rot:
					var binde := smoothstep(0.35, 0.65, 0.5 + 0.5 * sin(u * 34.0 - absf(seite) * 2.5))
					farbe = Color(0.5, 0.07, 0.06).lerp(Color(0.06, 0.03, 0.03), binde)
					farbe = farbe.lerp(Color(0.04, 0.035, 0.04), smoothstep(0.6, 1.0, u))
				return [q, farbe.darkened(0.25 if rueck else 0.0)], rueck)
		var kr := []
		for i in kiel.size():
			kr.append(lerpf(0.0034, 0.001, i / 16.0))
		_roehre(st, kiel, kr, Color(0.75, 0.7, 0.6), 6)
	_fertig(am, st, "Feder", 0.85)
	ResourceSaver.save(am, ZIEL + datei + ".tres")
	print("  ", datei, ": ", am.get_surface_count(), " Oberflächen")

## Punkt auf der Gesichtswalze: Winkel w (0 = vorn), Höhe y, Abstand vor der Haut
func _gesicht(w: float, y: float, vor := 0.0) -> Vector3:
	var r := _innen_r(y) + vor
	return Vector3(sin(w) * r, y, cos(w) * r)

func _konrad_bart(datei: String) -> void:
	var am := ArrayMesh.new()
	var haar := Color(0.022, 0.02, 0.022)
	var glanz := Color(0.075, 0.07, 0.08)
	# Strähnen: helle und dunkle Bahnen um den Querschnitt
	var straehne := func(i: int, s: float) -> Color:
		return haar.lerp(glanz, 0.5 + 0.5 * sin(s * TAU * 5.0 + i * 0.35))

	# --- Brauen: schwer und schräg, innen tief zur Nasenwurzel gezogen, außen
	# als Büschel hochgestellt. Breit genug, um die Brauen des Modells zu decken.
	var st := _neu()
	for seite: float in [-1.0, 1.0]:
		var pts := []
		var ra := []
		var rb := []
		for i in 15:
			var t := i / 14.0
			var x: float = seite * lerpf(0.012, 0.158, t)
			var y := lerpf(1.452, 1.497, t) - 0.02 * (1.0 - smoothstep(0.0, 0.22, t)) + 0.03 * smoothstep(0.78, 1.0, t)
			var z := sqrt(maxf(0.0, 0.194 * 0.194 - x * x)) + 0.014 - 0.01 * smoothstep(0.8, 1.0, t)
			pts.append(Vector3(x, y, z))
			var form := sin(pow(t, 0.55) * PI * 0.5) * (1.0 - 0.8 * smoothstep(0.82, 1.0, t))
			ra.append(lerpf(0.02, 0.047, form) * (1.0 if t > 0.04 else 0.6))
			rb.append(lerpf(0.016, 0.036, form))
		_oval(st, pts, ra, rb, Vector3.UP, straehne, 16)
	_fertig(am, st, "Brauen", 0.9)

	# --- Schnurrbart: dünn, lang, die Enden stehen frei ab und kringeln sich hoch
	st = _neu()
	for seite: float in [-1.0, 1.0]:
		var pts := []
		var rad := []
		var n := 30
		var haut_ende := _gesicht(seite * 0.62, 1.262, 0.012)
		for i in n + 1:
			var t := float(i) / n
			var p: Vector3
			if t <= 0.5:
				var s := t / 0.5
				var w: float = seite * lerpf(0.015, 0.62, s)
				p = _gesicht(w, 1.286 - 0.024 * sin(s * PI * 0.5), 0.012 + 0.012 * sin(s * PI))
			else:
				# frei in der Luft: erst nach außen, dann in einem Bogen nach oben und zurück
				var s := (t - 0.5) / 0.5
				var bogen := s * PI * 1.35
				var rk := lerpf(0.04, 0.02, s)
				p = haut_ende + Vector3(seite * (0.025 * s + rk * sin(bogen)), rk * (1.0 - cos(bogen)) , -0.02 * s)
			pts.append(p)
			rad.append(lerpf(0.0165, 0.003, pow(t, 0.75)) * (1.0 + 0.3 * sin(minf(t * 2.0, 1.0) * PI)))
		_roehre(st, pts, rad, haar.lerp(glanz, 0.25), 12)
	_fertig(am, st, "Schnurrbart", 0.8)

	# --- Kinnbart: von den Mundwinkeln herab zur langen, nach vorn gebogenen Spitze,
	# dazu zwei schmale Stege, die den Mund einrahmen, und scharfe Koteletten
	st = _neu()
	var pts := []
	var ra := []
	var rb := []
	for i in 19:
		var t := i / 18.0
		var y := lerpf(1.238, 1.0, t)
		var z := _innen_r(y) + 0.012 + 0.02 * sin(t * PI) + 0.075 * pow(t, 2.2)
		pts.append(Vector3(0.0, y, z))
		var form := sin(pow(t, 0.5) * PI) * 0.35 + (1.0 - t) * 0.65
		ra.append(maxf(0.003, 0.074 * form * (1.0 - 0.25 * sin(t * PI))))
		rb.append(maxf(0.003, 0.034 * form + 0.006 * sin(t * PI)))
	_oval(st, pts, ra, rb, Vector3.RIGHT, func(i: int, s: float) -> Color:
		return haar.lerp(glanz, 0.5 + 0.5 * sin(s * TAU * 9.0 + i * 0.2)), 22)
	for seite: float in [-1.0, 1.0]:
		var steg := []
		var sa := []
		var sb := []
		for i in 9:
			var t := i / 8.0
			steg.append(_gesicht(seite * lerpf(0.4, 0.2, pow(t, 1.3)), lerpf(1.272, 1.225, t), 0.009))
			sa.append(lerpf(0.011, 0.018, t))
			sb.append(0.008)
		_oval(st, steg, sa, sb, Vector3.RIGHT, straehne, 10)
		# Koteletten: unter dem Hut hervor, nach vorn unten zur Spitze
		var kot := []
		var ka := []
		var kb := []
		for i in 11:
			var t := i / 10.0
			# Koteletten wie Backenbart: unter dem Hut dünn, in der Mitte am
			# breitesten, dann in einer Spitze nach vorn zum Mundwinkel gezogen
			var form := sin(pow(clampf(t * 0.92 + 0.08, 0.0, 1.0), 0.75) * PI)
			kot.append(_gesicht(seite * lerpf(1.46, 1.12, pow(t, 1.5)), lerpf(1.6, 1.29, t), 0.004 + 0.008 * form))
			ka.append(0.005 + 0.036 * form)
			kb.append(0.005 + 0.013 * form)
		_oval(st, kot, ka, kb, Vector3(0, 0, 1), straehne, 10)
	_fertig(am, st, "Bart", 0.85)
	ResourceSaver.save(am, ZIEL + datei + ".tres")
	print("  ", datei, ": ", am.get_surface_count(), " Oberflächen")

# ------------------------------------------------------------ Rosenkranz
## Kranz aus Efeu und Rosen, liegt wie ein Reif um den Kopf (etwas über der Stirn).
func _kranz(datei: String, farben: Array) -> void:
	var am := ArrayMesh.new()
	_rng.seed = 77
	var mitte_y := 1.635
	var radius := 0.2
	# Ranke: Röhre im Kreis, leicht wellig
	var st := _neu()
	var punkte := []
	var radien := []
	var n := 48
	for i in n + 1:
		var w := TAU * float(i) / n
		var r := radius + 0.006 * sin(w * 9.0)
		punkte.append(Vector3(sin(w) * r, mitte_y + 0.008 * sin(w * 5.0) - 0.012 * (1.0 - cos(w)) * 0.0, cos(w) * r))
		radien.append(0.013)
	_roehre(st, punkte, radien, Color(0.2, 0.32, 0.12), 8)
	_fertig(am, st, "Ranke", 0.9)
	# Blätter: kleine Rauten, nach außen und leicht nach oben geneigt
	st = _neu()
	for i in 44:
		var w := TAU * (float(i) + _rng.randf() * 0.4) / 44.0
		var aussen := Vector3(sin(w), 0.0, cos(w))
		var quer := Vector3(cos(w), 0.0, -sin(w))
		var fuss := aussen * (radius + 0.005) + Vector3(0, mitte_y + _rng.randf_range(-0.012, 0.012), 0)
		var spitze := fuss + aussen * 0.045 + Vector3(0, _rng.randf_range(-0.03, 0.03), 0)
		var gr := _rng.randf_range(0.0, 1.0)
		var f := Color(0.16, 0.34, 0.12).lerp(Color(0.3, 0.46, 0.16), gr)
		var a := fuss + quer * 0.014
		var b := fuss - quer * 0.014
		for v in [fuss, a, spitze, fuss, spitze, b]:
			st.set_color(f)
			st.add_vertex(v)
	_fertig(am, st, "Blatt", 0.85)
	# Rosen: je drei Blütenkugeln (Kern, Außenring) und Knospen dazwischen
	var rosen := _neu()
	var knospen := _neu()
	var anzahl := 9
	for i in anzahl:
		var w := TAU * (float(i) + 0.5) / anzahl
		var aussen := Vector3(sin(w), 0.0, cos(w))
		var pos := aussen * (radius + 0.012) + Vector3(0, mitte_y + 0.012, 0)
		_kugel(rosen, pos, 0.036, farben[1], 0.9)
		_kugel(rosen, pos + aussen * 0.012 + Vector3(0, 0.008, 0), 0.027, farben[0], 0.8)
		_kugel(rosen, pos + aussen * 0.022 + Vector3(0, 0.012, 0), 0.015, farben[1], 0.7)
		# Knospe zwischen zwei Rosen
		var w2 := w + TAU / anzahl / 2.0
		var a2 := Vector3(sin(w2), 0.0, cos(w2))
		_kugel(knospen, a2 * (radius + 0.008) + Vector3(0, mitte_y + 0.004, 0), 0.016, farben[2], 0.8)
	_fertig(am, rosen, "Rose", 0.8)
	_fertig(am, knospen, "Knospe", 0.8)
	ResourceSaver.save(am, ZIEL + datei + ".tres")

func _kugel(st: SurfaceTool, mitte: Vector3, r: float, farbe: Color, _rauh: float) -> void:
	var nu := 12
	var nv := 8
	var p := []
	for j in nv + 1:
		for i in nu + 1:
			var a := TAU * float(i) / nu
			var b := PI * float(j) / nv
			p.append(mitte + Vector3(sin(b) * cos(a), cos(b), sin(b) * sin(a)) * r)
	for j in nv:
		for i in nu:
			var k := j * (nu + 1) + i
			for t in [k, k + 1, k + nu + 2, k, k + nu + 2, k + nu + 1]:
				st.set_color(farbe)
				st.add_vertex(p[t])
