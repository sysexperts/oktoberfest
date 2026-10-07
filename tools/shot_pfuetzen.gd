extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kotze und Urin im Zelt, Nahaufnahme (build/pfuetzen.png).
##   godot --path . res://tools/shot_pfuetzen.tscn --resolution 1280x720

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._spawn_mess_at(Vector3(-0.6, 0, 3.0), 0)
		gm._spawn_mess_at(Vector3(0.6, 0, 3.0), 1)
		await get_tree().create_timer(0.5).timeout
		for m in gm._messes.values():
			print("Mess ", m.kind, " ", m.global_position)
		var sp: PhysicsDirectSpaceState3D = gm.get_world_3d().direct_space_state
		for x in [[0.8, 3.0], [-0.6, 1.8], [10.0, 8.0], [0.0, -5.0]]:
			var q := PhysicsRayQueryParameters3D.create(Vector3(x[0], 3.0, x[1]), Vector3(x[0], -1.0, x[1]))
			var r := sp.intersect_ray(q)
			print("Boden bei ", x, ": ", r.get("position", "nichts"), " ", r.get("collider", null))
		for mi in gm.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
			if a.position.x < 0.8 and a.end.x > 0.8 and a.position.z < 3.0 and a.end.z > 3.0 and a.end.y < 0.5 and a.end.y > -0.5 and (mi as MeshInstance3D).is_visible_in_tree():
				print("Flaeche ", mi.get_path(), " y ", a.position.y, "..", a.end.y)
		var kam := Camera3D.new()
		gm.add_child(kam)
		kam.global_position = Vector3(0, 1.6, 5.0)
		kam.look_at(Vector3(0, 0, 3.0))
		kam.current = true
		await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_png("res://build/pfuetzen.png")
		get_tree().quit()
