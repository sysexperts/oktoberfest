extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Ist vor jeder Wohnwagentür Platz? Listet je Wagen, was dort im Weg steht.
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await get_tree().create_timer(3.0).timeout
		var kapsel := CapsuleShape3D.new()
		kapsel.radius = 0.35
		kapsel.height = 1.6
		var abfrage := PhysicsShapeQueryParameters3D.new()
		abfrage.shape = kapsel
		var frei := 0
		var gesamt := 0
		for c in get_tree().get_nodes_in_group("interactable"):
			if not (c is Caravan):
				continue
			var w := c as Caravan
			var tuer: Vector3 = w.interact_point()          # Höhe der Tür + 1 m
			var boden := Vector3(tuer.x, 0.0, tuer.z)
			var aus := boden - Vector3(w.global_position.x, 0.0, w.global_position.z)
			aus.y = 0.0
			aus = aus.normalized()
			gesamt += 1
			# Kapsel steht auf dem Boden (Mitte 0,9 m); frei = irgendwo im Umkreis von 2 m ohne Treffer
			var gefunden := false
			var erster := []
			for r in [0.7, 1.1, 1.6, 2.0]:
				for k in 16:
					var a := TAU * float(k) / 16.0
					var p := boden + Vector3(cos(a), 0.0, sin(a)) * float(r) + Vector3(0, 0.95, 0)
					abfrage.transform = Transform3D(Basis(), p)
					var treffer: Array = gm.get_world_3d().direct_space_state.intersect_shape(abfrage, 4)
					if treffer.is_empty():
						gefunden = true
						break
					elif erster.is_empty():
						erster = treffer.map(func(t): return str((t.collider as Node).get_path()).right(40))
				if gefunden:
					break
			if gefunden:
				frei += 1
			else:
				print("TUER Wagen %d (%s) bei %s: KEIN freier Platz, z.B. %s" % [w.nummer, w.name, str(boden), str(erster)])
		print("TUER frei %d von %d" % [frei, gesamt])
		get_tree().quit()
