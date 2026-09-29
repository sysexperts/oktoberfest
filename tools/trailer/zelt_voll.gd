extends Node
const Figuren := preload("res://scripts/figuren.gd")
## Trailer: Zelt voll ausgebaut — alle Tische, Gäste auf allen Plätzen, Band
## spielt. Nur Darstellung, das Spiel läuft dafür nicht (Uhr steht).

## Ausbaustufe des Zelts (höchste = alles)
@export var stufe := 3
## Höchstens so viele Gäste
@export var gaeste := 160
## Anteil der Gäste, die auf den Tischen tanzen (0 = keiner)
@export_range(0.0, 1.0, 0.05) var tanzen := 0.0
## Stehgäste (stehen hinter der Bank, also im Gang) ausblenden — sonst laufen
## Kellner und Spieler im Trailer durch sie hindurch
@export var ohne_stehgaeste := true
## Tische/Plätze auf der Konsole ausgeben (zum Planen der Kamerafahrt)
@export var plan_ausgeben := false

var gm: Node

func aufstellen() -> void:
	gm = get_tree().current_scene
	gm._popularity = 95.0
	gm._hygiene = 100.0
	gm._tent_stage = stufe
	gm._active_count = gm._all_tables.size()
	gm._apply_tent()
	gm._rebuild_seats()
	gm._apply_stage(true)
	for i in mini(gaeste, gm._seats.size()):
		var vorher: int = gm._guest_next
		gm._spawn_guest()
		if gm._guest_next == vorher:
			break
		var id: int = vorher
		var g: Dictionary = gm._guest_sim[id]
		var platz: Vector3 = gm._platz_pos_fuer(id, int(g.seat))
		g.pos = platz
		g.mode = 1
		g.weg = []
		g.tgt = platz
		(gm._guests[id] as Node3D).position = platz
		gm._guests[id].set_net(platz, float(gm._seats[int(g.seat)].yaw))
		if ohne_stehgaeste and Figuren.ist_stehgast(id):
			(gm._guests[id] as Node3D).visible = false
	if tanzen > 0.0:
		_tische_tanzen()
	if plan_ausgeben:
		for t in gm._all_tables:
			print("  Tisch %s bei %s" % [t.name, (t as Node3D).global_position.snapped(Vector3.ONE * 0.1)])
		print("  Plätze: %d, Gäste: %d" % [gm._seats.size(), gm._guest_sim.size()])

func starten() -> void:
	pass

func zuruecksetzen() -> void:
	pass

## Auf jeden Tisch so viele Tänzer, wie das Spiel erlaubt (tanz_max), an die
## Tanzplätze aus dem Spiel (TANZ_PLAETZE) — direkt, ohne Simulation.
## tanzen = Anteil der Tische.
func _tische_tanzen() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var frei := {}   # Tisch -> Gäste an diesem Tisch
	for id in gm._guest_sim.keys():
		var knoten = gm._guests.get(id)
		if knoten == null or not (knoten as Node3D).visible:
			continue
		var ti := int(gm._seats[int(gm._guest_sim[id].seat)].table)
		if not frei.has(ti):
			frei[ti] = []
		frei[ti].append(id)
	for ti: int in frei:
		if ti >= gm._beertables.size() or rng.randf() > tanzen:
			continue
		var bt := gm._beertables[ti] as Node3D
		if gm.auf_buehne(bt.global_position):
			continue
		var gaeste_hier: Array = frei[ti]
		for platz in mini(mini(gm.tanz_max(ti), gm.TANZ_PLAETZE.size()), gaeste_hier.size()):
			var id: int = gaeste_hier[platz]
			var versatz: Vector2 = gm.TANZ_PLAETZE[platz]
			var ziel: Vector3 = bt.global_position + bt.global_transform.basis.x * versatz.x + bt.global_transform.basis.z * versatz.y
			ziel.y = bt.global_position.y + 0.1
			var g: Dictionary = gm._guest_sim[id]
			g.mode = 5
			g.pos = ziel
			g.tgt = ziel
			var k: Node3D = gm._guests[id]
			k.position = ziel
			k.set_net(ziel, rng.randf() * TAU)
			k.set_tanz(true)
