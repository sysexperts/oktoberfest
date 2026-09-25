extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kulisse rund um den Platz prüfen: Terrain-Meshes ausgeben, Ansichten nach außen als PNG.
## Aufruf: Godot --path . res://tools/shot_kulisse.tscn  (SHOT_DIR = Zielordner)

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		if await Spielstart.starten(self) == null:
			return
		for i in 60:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		gm.set_process(false)
		gm.get_node("HUD").visible = false
		var terrain := gm.get_node_or_null("Kirmes/Terrain")
		if terrain:
			for m in terrain.find_children("*", "MeshInstance3D", true, false):
				var mi := m as MeshInstance3D
				print("MESH ", terrain.get_path_to(mi), " aabb=", mi.global_transform * mi.get_aabb())
		var cam := Camera3D.new()
		gm.add_child(cam)
		cam.current = true
		cam.fov = 70.0
		cam.far = 4000.0
		var ansichten := {
			"a_nord": [Vector3(0, 6, 30), Vector3(0, 8, 120)],
			"a_sued": [Vector3(0, 6, -20), Vector3(0, 8, -120)],
			"a_ost": [Vector3(20, 6, 0), Vector3(120, 8, 0)],
			"a_west": [Vector3(-20, 6, 0), Vector3(-120, 8, 0)],
			"a_trailer": [Vector3(-40, 26, 74), Vector3(0, 2, 10)],
			"a_hoch": [Vector3(0, 60, 90), Vector3(0, 0, -20)],
			"a_markt": [Vector3(26.0, 4.0, 58.0), Vector3(16.0, 2.0, 76.0)],
			"a_reihe": [Vector3(-6.0, 3.2, 19.0), Vector3(-26.0, 2.0, 27.0)],
		}
		for k in ansichten:
			cam.global_position = ansichten[k][0]
			cam.look_at(ansichten[k][1])
			for i in 10:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/%s.png" % k)
		print("Bilder gespeichert")
		get_tree().quit()
