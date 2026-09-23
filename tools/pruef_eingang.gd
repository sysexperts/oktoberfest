extends Node
## Sucht unsichtbare Sperren: schiebt eine Spielerkapsel über ein Raster im Zelt
## und am Eingang und meldet jeden Körper, der im Weg steht — mit Knotenpfad.
## Aufruf: godot --headless --path . res://tools/pruef_eingang.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		Net.start_solo(true)
		for i in 9000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		for i in 40:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		var raum: PhysicsDirectSpaceState3D = gm.get_world_3d().direct_space_state
		var kapsel := CapsuleShape3D.new()
		kapsel.radius = 0.35
		kapsel.height = 1.7
		var abf := PhysicsShapeQueryParameters3D.new()
		abf.shape = kapsel
		abf.collide_with_areas = false

		print("--- Eingangskorridor (x -3 … 3, z 13 … 6) ---")
		_raster(raum, abf, -3.0, 3.0, 6.0, 13.0, 0.5)
		print("--- Zeltfläche (x -12 … 12, z -14 … 11) ---")
		_raster(raum, abf, -11.5, 11.5, -13.5, 11.0, 1.0)
		get_tree().quit()

	func _raster(raum: PhysicsDirectSpaceState3D, abf: PhysicsShapeQueryParameters3D,
			x0: float, x1: float, z0: float, z1: float, schritt: float) -> void:
		var treffer := {}
		var x := x0
		while x <= x1:
			var z := z0
			while z <= z1:
				abf.transform = Transform3D(Basis.IDENTITY, Vector3(x, 1.0, z))
				for t: Dictionary in raum.intersect_shape(abf, 8):
					var k = t.get("collider")
					if k == null:
						continue
					var pfad := String(k.get_path())
					if not treffer.has(pfad):
						treffer[pfad] = []
					if treffer[pfad].size() < 4:
						treffer[pfad].append("%.1f/%.1f" % [x, z])
				z += schritt
			x += schritt
		var namen := treffer.keys()
		namen.sort()
		for pfad: String in namen:
			print("  %s  bei %s" % [pfad.replace("/root/Main/", ""), ", ".join(treffer[pfad])])
		if treffer.is_empty():
			print("  (frei)")
