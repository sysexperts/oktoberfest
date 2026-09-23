class_name Crowd
extends Node3D
## Kirmes-Besucher draußen. Läuft rein lokal auf jedem Client (kein Netz-Traffic),
## die Menge hat keinen Einfluss aufs Spiel.
##
## Die Besucher bummeln zwischen Wegpunkten in den Gassen zwischen den Ständen.
## Sie suchen sich immer ein Ziel in der Nähe — dadurch wirkt es wie ein Gedränge
## und nicht wie eine Prozession in Reih und Glied.
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
@export var max_visitors := 400

## Abstand der Probepunkte
const RASTER := 2.5
## Nur Punkte, bei denen so nah etwas Gebautes steht (sonst Wiese und Wald)
const NAH_AN_STAENDEN := 10.0
## So dick und hoch ist ein Besucher (Probe auf Platz)
const FREI_RADIUS := 0.45
const FREI_HOEHE := 1.5
## Festzelt: da gehören die Kirmes-Besucher nicht hinein (Gäste macht der Server)
const ZELT := Rect2(-13.5, -16.0, 27.0, 29.0)
## Fällt die Suche aus (Menühintergrund ohne Karte): altes Ringraster
const RING_Z := [19.0, -22.0]

var _visitors := []
var _target := 0
var _points: Array = []
var _neu_bauen := -1.0   # Karte geändert: nach kurzer Ruhe neu suchen
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
	var gebaut := _gebaute_orte()
	if gebaut.is_empty():
		_ringraster()
		return
	var raster := _ortsraster(gebaut)
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
			if ZELT.has_point(p):
				continue
			if not _nah_an_gebautem(raster, p):
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
			_points.append(g)
	if _points.is_empty():
		_ringraster()

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
	return raum.intersect_shape(_probe, 1).is_empty()

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

## Notfall: das alte feste Ringraster der ursprünglichen Kirmes.
func _ringraster() -> void:
	for x in [-28.0, -21.0, -14.0, -7.0, 0.0, 7.0, 14.0, 21.0, 28.0]:
		for z: float in RING_Z:
			_points.append(Vector3(x, 0.1, z))
	for z in [-16.0, -9.0, -2.0, 5.0, 12.0]:
		_points.append(Vector3(22.0, 0.1, z))
		_points.append(Vector3(-22.0, 0.1, z))

## Ein Ziel in der Nähe — so bummeln sie von Stand zu Stand statt im Kreis zu marschieren.
func next_point(from: Vector3) -> Vector3:
	if _points.is_empty():
		_build_points()
	var near := []
	for p in _points:
		var d: float = from.distance_to(p)
		if d > 4.0 and d < 18.0:
			near.append(p)
	var base: Vector3 = (near.pick_random() if not near.is_empty() else _points.pick_random()) as Vector3
	# leichter Zufallsversatz, damit nicht alle exakt denselben Punkt anlaufen
	return base + Vector3(randf_range(-0.8, 0.8), 0.0, randf_range(-0.8, 0.8))

func random_start() -> Vector3:
	if _points.is_empty():
		_build_points()
	return (_points.pick_random() as Vector3) + Vector3(randf_range(-0.8, 0.8), 0.0, randf_range(-0.8, 0.8))

## f: 0.0 = leer, 1.0 = volle Kirmes.
func set_density(f: float) -> void:
	_target = int(round(clampf(f, 0.0, 1.0) * float(max_visitors)))

func _process(delta: float) -> void:
	if _neu_bauen >= 0.0:
		_neu_bauen -= delta
		if _neu_bauen < 0.0:
			_build_points()
	if _visitors.size() != _target:
		_sync_step()

func _sync_step() -> void:
	var budget := 4
	while _visitors.size() < _target and budget > 0:
		var v := VISITOR.instantiate()
		add_child(v)
		v.setup(self)
		_visitors.append(v)
		budget -= 1
	while _visitors.size() > _target and budget > 0:
		var v = _visitors.pop_back()
		if is_instance_valid(v):
			v.queue_free()
		budget -= 1
