extends Node3D
## Prüft die Besucher-Sperre: im Zelt gesperrt, davor frei, und normale
## Abfragen (Spieler, Kamera) sehen die Sperre nicht.
## Aufruf: godot --headless --path . res://tools/test_besucher_sperre.tscn
const BesucherSperre := preload("res://scripts/besucher_sperre.gd")

func _ready() -> void:
	add_child(load("res://scenes/tent.tscn").instantiate())
	var klein: Node3D = load("res://scenes/karte/besucher_sperre_streifen.tscn").instantiate()
	klein.position = Vector3(40, 0, 0)
	add_child(klein)
	for i in 3:
		await get_tree().physics_frame
	var raum := get_world_3d().direct_space_state
	var form := CapsuleShape3D.new()
	form.radius = 0.4
	form.height = 1.5
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = form
	var fehler := 0
	for fall in [[Vector3(0, 0, -5), true], [Vector3(0, 0, 20), false], [Vector3(40, 0, 0.5), true], [Vector3(40, 0, 3), false]]:
		q.transform = Transform3D(Basis.IDENTITY, (fall[0] as Vector3) + Vector3(0, 0.9, 0))
		var g := BesucherSperre.gesperrt(raum, q)
		print("  %s gesperrt=%s (erwartet %s)" % [fall[0], g, fall[1]])
		if g != fall[1]:
			fehler += 1
	# Normale Abfrage (Maske alles, Bereiche an) an einer freien Stelle der Sperre
	var strahl := PhysicsRayQueryParameters3D.create(Vector3(40, 5, 0), Vector3(40, -1, 0))
	strahl.collide_with_areas = true
	var t := raum.intersect_ray(strahl)
	print("  Strahl mit Standardmaske trifft Sperre: ", not t.is_empty() and t.collider is Area3D)
	print("TEST ", "OK" if fehler == 0 else "FEHLER %d" % fehler)
	get_tree().quit()
