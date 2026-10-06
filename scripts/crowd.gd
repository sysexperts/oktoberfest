class_name Crowd
extends Node3D
## Kirmes-Besucher draußen. Läuft rein lokal auf jedem Client (kein Netz-Traffic),
## die Menge hat keinen Einfluss aufs Spiel.
##
## Die Besucher gehen auf einem Wegenetz durch die Gassen zwischen den Ständen:
## geradeaus weiter, an Kreuzungen biegen manche ab, am Ende einer Gasse kehren
## sie um. Jeder hält sich rechts seiner Laufrichtung (eigene Spur je Besucher)
## — so entsteht Gegenverkehr wie auf einer echten Kirmes statt eines
## Zickzacks zu Zufallszielen.
##
## Woher die Wegpunkte kommen: früher stand hier ein festes Raster aus der alten,
## fest gebauten Kirmes. Seit der Baumodus die Karte bestimmt (scripts/karte.gd)
## lag dieses Raster mitten in den Ständen — die Besucher marschierten durch
## Buden und Bänke. Jetzt werden die Punkte aus dem echten Freiraum gesucht:
## ein Probepunkt zählt nur, wenn dort eine Figur wirklich Platz hat (Kollision)
## und in der Nähe etwas Gebautes steht. Damit liegen sie automatisch auf den
## Gassen und Straßen zwischen den Ständen und wandern nicht über die Wiese.

const VISITOR := preload("res://scenes/visitor.tscn")

## Bei Rucklern hier runterdrehen.
@export var max_visitors := 450

## Abstand der Probepunkte
const RASTER := 2.5
## Nur Punkte, bei denen so nah etwas Gebautes steht (sonst Wiese und Wald)
const NAH_AN_STAENDEN := 10.0
## So dick und hoch ist ein Besucher (Probe auf Platz)
const FREI_RADIUS := 0.45
const FREI_HOEHE := 1.5
## Zelte und im Baumodus markierte Flächen: da gehören die Kirmes-Besucher
## nicht hin (scripts/besucher_sperre.gd, steckt auch in scenes/tent.tscn)
const BesucherSperre := preload("res://scripts/besucher_sperre.gd")
## Fällt die Suche aus (Menühintergrund ohne Karte): altes Ringraster
const RING_Z := [19.0, -22.0]
## Wegenetz: so weit auseinander dürfen verbundene Punkte liegen — Raster
## (Nachbarn samt Diagonale) und die von Hand gesetzten Straßenpunkte
const NACHBAR_RASTER := 3.6
const NACHBAR_STRASSE := 13.0
## Pflaster-Maske: Zellgröße (m). Wege gibt es nur auf dem Pflaster der
## Straßen (Gruppe „pflaster“, scenes/kulisse/strassen.tscn) — nicht auf der
## Wiese zwischen Bäumen und Buden.
const PFLASTER_ZELLE := 1.0
## Chance, an einer Kreuzung abzubiegen statt geradeaus zu gehen
const ABBIEGEN := 0.18

var _visitors := []
var _target := 0
var _points: Array = []
## Wegenetz: Nachbarn je Punkt (Index in _points)
var _nachbarn: Array[PackedInt32Array] = []
## Punkte, die von Hand gesetzt sind (Straßen) — dürfen weiter verbinden
var _strasse := {}
## Zellen, die gepflastert sind (leer = keine Straßen, dann wie früher)
var _pflaster := {}
var _neu_bauen := -1.0   # Karte geändert: nach kurzer Ruhe neu suchen
var _version := 0         # zählt hoch, wenn das Netz neu gebaut wurde
var _probe: PhysicsShapeQueryParameters3D = null

func _ready() -> void:
	var karte := _karte()
	if karte:
		karte.geaendert.connect(_karte_geaendert)
	# Die Kollision der Karte steht erst nach dem ersten Physikschritt bereit
	_neu_bauen = 0.2

## Die gebaute Karte liegt in scenes/kirmes.tscn (Main/Kirmes/Karte); im
## Menühintergrund gibt es sie nicht.
func _karte() -> Node:
	return get_node_or_null("../Kirmes/Karte")

func _karte_geaendert() -> void:
	# Im Baumodus kommen viele Änderungen kurz hintereinander — einmal reicht
	_neu_bauen = 1.5

func _build_points() -> void:
	_points.clear()
	_nachbarn.clear()
	_strasse.clear()
	_version += 1
	var gebaut := _gebaute_orte()
	if gebaut.is_empty():
		_ringraster()
		return
	var raster := _ortsraster(gebaut)
	_pflaster_lesen()
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for p: Vector2 in gebaut:
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_z = minf(min_z, p.y)
		max_z = maxf(max_z, p.y)
	var x := min_x - RASTER
	while x <= max_x + RASTER:
		var z := min_z - RASTER
		while z <= max_z + RASTER:
			var p := Vector2(x, z)
			z += RASTER
			if _pflaster.is_empty():
				if not _nah_an_gebautem(raster, p):
					continue
			elif not _gepflastert(p):
				continue
			if not _frei(p):
				continue
			_points.append(Vector3(p.x, 0.1, p.y))
		x += RASTER
	# Von Hand gesetzte Punkte auf den Straßen (scenes/kulisse/strassen.tscn) kommen
	# dazu — aber nur, wo inzwischen nicht gebaut wurde.
	for m in get_tree().get_nodes_in_group("besucher_punkt"):
		var g: Vector3 = (m as Node3D).global_position
		if _frei(Vector2(g.x, g.z)):
			_strasse[_points.size()] = true
			_points.append(g)
	if _points.is_empty():
		_ringraster()
		return
	_netz_bauen()

## Hat dort eine Figur wirklich Platz? Gefragt wird dieselbe Kollision, an der
## auch der Spieler hängen bleibt — damit zählt alles Gebaute mit, auch später
## im Baumodus hingestellte Buden und Bänke.
func _frei(p: Vector2) -> bool:
	var welt := get_world_3d()
	if welt == null:
		return true
	var raum := welt.direct_space_state
	if raum == null:
		return true
	if _probe == null:
		var form := CapsuleShape3D.new()
		form.radius = FREI_RADIUS
		form.height = FREI_HOEHE
		_probe = PhysicsShapeQueryParameters3D.new()
		_probe.shape = form
		_probe.collide_with_areas = false
	_probe.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, 0.15 + FREI_HOEHE * 0.5, p.y))
	return raum.intersect_shape(_probe, 1).is_empty() and not BesucherSperre.gesperrt(raum, _probe)

## Wo steht etwas Gebautes? Kartenteile (Buden, Bänke, Zäune, Bäume) und die
## von Hand gesetzten Besucherpunkte auf den Straßen.
func _gebaute_orte() -> Array:
	var orte := []
	var karte := _karte()
	if karte and karte.eintraege is Dictionary:
		for e in (karte.eintraege as Dictionary).values():
			orte.append(Vector2(float(e.get("x", 0.0)), float(e.get("z", 0.0))))
	for m in get_tree().get_nodes_in_group("besucher_punkt"):
		var g: Vector3 = (m as Node3D).global_position
		orte.append(Vector2(g.x, g.z))
	return orte

## Orte in Zellen einsortieren, damit die Nachbarschaftsfrage nicht über alle
## 600 Kartenteile läuft (das Raster hat mehrere Tausend Probepunkte).
func _ortsraster(orte: Array) -> Dictionary:
	var d := {}
	for p: Vector2 in orte:
		var k := Vector2i(int(floor(p.x / NAH_AN_STAENDEN)), int(floor(p.y / NAH_AN_STAENDEN)))
		if not d.has(k):
			d[k] = []
		d[k].append(p)
	return d

func _nah_an_gebautem(raster: Dictionary, p: Vector2) -> bool:
	var k := Vector2i(int(floor(p.x / NAH_AN_STAENDEN)), int(floor(p.y / NAH_AN_STAENDEN)))
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			for o: Vector2 in raster.get(Vector2i(k.x + dx, k.y + dz), []):
				if p.distance_squared_to(o) < NAH_AN_STAENDEN * NAH_AN_STAENDEN:
					return true
	return false

## Pflaster-Flächen in Zellen einteilen (Dreiecke der Straßen-Meshes von oben)
func _pflaster_lesen() -> void:
	_pflaster.clear()
	for gruppe in get_tree().get_nodes_in_group("pflaster"):
		for mi: MeshInstance3D in gruppe.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh == null:
				continue
			var xf := mi.global_transform
			var ecken := mi.mesh.get_faces()
			for t in range(0, ecken.size(), 3):
				_dreieck_eintragen(xf * ecken[t], xf * ecken[t + 1], xf * ecken[t + 2])

func _dreieck_eintragen(a3: Vector3, b3: Vector3, c3: Vector3) -> void:
	var a := Vector2(a3.x, a3.z) / PFLASTER_ZELLE
	var b := Vector2(b3.x, b3.z) / PFLASTER_ZELLE
	var c := Vector2(c3.x, c3.z) / PFLASTER_ZELLE
	var flaeche := (b - a).cross(c - a)
	if absf(flaeche) < 0.0001:
		return
	for x in range(int(floor(minf(a.x, minf(b.x, c.x)))), int(ceil(maxf(a.x, maxf(b.x, c.x)))) + 1):
		for y in range(int(floor(minf(a.y, minf(b.y, c.y)))), int(ceil(maxf(a.y, maxf(b.y, c.y)))) + 1):
			var q := Vector2(x + 0.5, y + 0.5)
			var w0 := (c - b).cross(q - b) / flaeche
			var w1 := (a - c).cross(q - c) / flaeche
			var w2 := (b - a).cross(q - a) / flaeche
			if w0 >= -0.05 and w1 >= -0.05 and w2 >= -0.05:
				_pflaster[Vector2i(x, y)] = true

func _gepflastert(p: Vector2) -> bool:
	return _pflaster.has(Vector2i(int(floor(p.x / PFLASTER_ZELLE)), int(floor(p.y / PFLASTER_ZELLE))))

## Verbindet benachbarte Punkte, wenn der Weg dazwischen frei ist.
func _netz_bauen(ohne_probe := false) -> void:
	_nachbarn.clear()
	_nachbarn.resize(_points.size())
	var zelle := NACHBAR_STRASSE
	var raster := {}
	for i in _points.size():
		var p: Vector3 = _points[i]
		var k := Vector2i(int(floor(p.x / zelle)), int(floor(p.z / zelle)))
		if not raster.has(k):
			raster[k] = []
		raster[k].append(i)
	for i in _points.size():
		_nachbarn[i] = PackedInt32Array()
	for i in _points.size():
		var p: Vector3 = _points[i]
		var k := Vector2i(int(floor(p.x / zelle)), int(floor(p.z / zelle)))
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				for j: int in raster.get(Vector2i(k.x + dx, k.y + dz), []):
					if j <= i:
						continue
					var q: Vector3 = _points[j]
					var weit := NACHBAR_STRASSE if (_strasse.has(i) or _strasse.has(j)) else NACHBAR_RASTER
					var d := Vector2(p.x - q.x, p.z - q.z).length()
					if d < 0.5 or d > weit:
						continue
					if not ohne_probe and not _weg_frei(p, q):
						continue
					_nachbarn[i].append(j)
					_nachbarn[j].append(i)

## Ist die Strecke zwischen zwei Punkten begehbar? Alle ~1,2 m nachsehen.
func _weg_frei(a: Vector3, b: Vector3) -> bool:
	var schritte := maxi(1, int(Vector2(a.x - b.x, a.z - b.z).length() / 1.2))
	for s in range(1, schritte):
		var t := float(s) / schritte
		if not _frei(Vector2(lerpf(a.x, b.x, t), lerpf(a.z, b.z, t))):
			return false
	return true

## Notfall: das alte feste Ringraster der ursprünglichen Kirmes.
func _ringraster() -> void:
	for x in [-28.0, -21.0, -14.0, -7.0, 0.0, 7.0, 14.0, 21.0, 28.0]:
		for z: float in RING_Z:
			_points.append(Vector3(x, 0.1, z))
	for z in [-16.0, -9.0, -2.0, 5.0, 12.0]:
		_points.append(Vector3(22.0, 0.1, z))
		_points.append(Vector3(-22.0, 0.1, z))
	# Ohne Karte gibt es nichts, woran man stoßen könnte: großzügig verbinden
	for i in _points.size():
		_strasse[i] = true
	_netz_bauen(true)

# ------------------------------------------------------------ Wegenetz
## Startpunkt: ein Punkt mit Nachbarn (sonst irgendeiner)
func weg_start() -> int:
	if _points.is_empty():
		_build_points()
	for versuch in 20:
		var i := randi() % _points.size()
		if _nachbarn.size() > i and not _nachbarn[i].is_empty():
			return i
	return randi() % _points.size()

func punkt(i: int) -> Vector3:
	return _points[i] if i >= 0 and i < _points.size() else Vector3.ZERO

func netz_version() -> int:
	return _version

## Nächster Punkt auf dem Weg: möglichst geradeaus, manchmal abbiegen,
## umkehren nur am Ende einer Gasse.
func weiter(i: int, richtung: Vector3) -> int:
	if i < 0 or i >= _nachbarn.size() or _nachbarn[i].is_empty():
		return weg_start()
	var von: Vector3 = _points[i]
	var bester := -1
	var bester_wert := -INF
	var seiten: Array[int] = []
	var zurueck := -1
	for j in _nachbarn[i]:
		var d: Vector3 = _points[j] - von
		d.y = 0.0
		var gerade := d.normalized().dot(richtung)
		if gerade > 0.6:
			# leichter Zufall, damit parallele Reihen nicht exakt gleich laufen
			var wert := gerade + randf() * 0.15
			if wert > bester_wert:
				bester_wert = wert
				bester = j
		elif gerade > -0.3:
			seiten.append(j)
		else:
			zurueck = j
	if not seiten.is_empty() and (bester < 0 or randf() < ABBIEGEN):
		return seiten.pick_random()
	if bester >= 0:
		return bester
	return zurueck if zurueck >= 0 else _nachbarn[i][0]

## Ziel auf der eigenen Spur: um „spur" Meter rechts der Laufrichtung versetzt,
## wenn dort Platz ist — so gehen Hin- und Rückweg nebeneinander.
func spur_punkt(i: int, richtung: Vector3, spur: float) -> Vector3:
	var p: Vector3 = _points[i]
	var rechts := Vector3(-richtung.z, 0.0, richtung.x)
	for anteil in [1.0, 0.5, 0.0]:
		var q: Vector3 = p + rechts * spur * float(anteil)
		if anteil == 0.0 or _frei(Vector2(q.x, q.z)):
			return q
	return p

## f: 0.0 = leer, 1.0 = volle Kirmes.
func set_density(f: float) -> void:
	_target = int(round(clampf(f, 0.0, 1.0) * float(max_visitors)))

func _process(delta: float) -> void:
	if _neu_bauen >= 0.0:
		_neu_bauen -= delta
		if _neu_bauen < 0.0:
			_build_points()
	if _visitors.size() != _target:
		_sync_step(delta)

## So lange darf das Bauen von Besuchern in einem Bild dauern. Ein Besucher aus dem Creator kostet je nach Rechner
## 10 bis 40 ms — vier pro Bild (früher) ließen das Spiel nach dem Start etwa 15 Sekunden auf 8 Bilder pro Sekunde
## einbrechen. Jetzt mindestens einer pro Bild, weitere nur, solange es billig bleibt, und gar keiner,
## wenn das Bild ohnehin schon lang dauert.
const BAU_MS := 10.0
const BAU_PAUSE_AB := 0.05

func _sync_step(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	var gebaut := 0
	if _visitors.size() < _target and delta < BAU_PAUSE_AB:
		while _visitors.size() < _target and gebaut < 4:
			if gebaut > 0 and float(Time.get_ticks_usec() - t0) / 1000.0 > BAU_MS:
				break
			var v := VISITOR.instantiate()
			add_child(v)
			v.setup(self)
			_visitors.append(v)
			gebaut += 1
	var weg := 4
	while _visitors.size() > _target and weg > 0:
		var v = _visitors.pop_back()
		if is_instance_valid(v):
			v.queue_free()
		weg -= 1
