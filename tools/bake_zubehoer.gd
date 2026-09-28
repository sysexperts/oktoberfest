extends SceneTree
## Modelliert Zubehör für die Figuren (Maße vom Kopf von character2, gemessen:
## Walze mit Radius 0,19 m, runde Kuppe ab 1,53 m bis 1,72 m, Mund bei 1,25 m,
## Kragen ab 1,20 m). Alles in Modellkoordinaten (+z = vorn).
##   tirolerhut.tres — Filzkrone mit Kniff, geschwungene Krempe, Hutband mit
##                      Kordel, Feder und Gamsbart
##   vollbart.tres    — Vollbart, der der Kopfform folgt, mit Strähnen und
##                      gewelltem Rand, dazu ein gezwirbelter Schnurrbart
## Oberflächen je Material (Filz, Band, Kordel, Feder, Gamsbart / Bart,
## Schnurrbart) — in den Zubehör-Szenen per Material umfärbbar.
## Aufruf: godot --headless --path . --script res://tools/bake_zubehoer.gd

const ZIEL := "res://assets/zubehoer/"
const KOPF_R := 0.19
const KUPPE_Y := 1.53

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZIEL))
	_rng.seed = 1234
	_hut()
	_bart()
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
	m.cull_mode = BaseMaterial3D.CULL_DISABLED if name in ["Filz", "Feder"] else BaseMaterial3D.CULL_BACK
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

func _hut() -> void:
	var am := ArrayMesh.new()
	var filz := Color(0.22, 0.33, 0.19)
	var filz_d := Color(0.17, 0.27, 0.15)
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
	var band := Color(0.33, 0.19, 0.09)
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
	_roehre(st, kordel, kr, Color(0.85, 0.72, 0.4), 8)
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
	ResourceSaver.save(am, ZIEL + "tirolerhut.tres")
	print("  tirolerhut: ", am.get_surface_count(), " Oberflächen")

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

func _bart_punkt(u: float, v: float, aussen: bool) -> Array:
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
	return [p, Color(0.34, 0.2, 0.1).darkened(dunkel)]

func _bart() -> void:
	var am := ArrayMesh.new()
	var st := _neu()
	var nu := 90
	var nv := 24
	_flaeche(st, nu, nv, func(u: float, v: float) -> Array: return _bart_punkt(u, v, true))
	_flaeche(st, nu, nv, func(u: float, v: float) -> Array: return _bart_punkt(u, v, false), true)
	# Unterkante schließen (gewellter Rand)
	_flaeche(st, nu, 1, func(u: float, v: float) -> Array:
		var a: Array = _bart_punkt(u, 1.0, true)
		var b: Array = _bart_punkt(u, 1.0, false)
		return [(a[0] as Vector3).lerp(b[0], v), Color(0.24, 0.13, 0.06)], true)
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
		_roehre(st, pts, rad, Color(0.3, 0.17, 0.08), 14)
	_fertig(am, st, "Schnurrbart", 0.9)
	ResourceSaver.save(am, ZIEL + "vollbart.tres")
	print("  vollbart: ", am.get_surface_count(), " Oberflächen")
