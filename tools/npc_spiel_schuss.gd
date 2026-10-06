extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Startet das Spiel, füllt die Kirmes mit Besuchern und speichert zwei Bilder (build/blender/npc_spiel_1.png, _2.png).
## godot --path . res://tools/npc_spiel_schuss.tscn --resolution 1600x900

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	func _ready() -> void:
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		gm.set_process(false)
		var menge := gm.get_node("Crowd")
		var cam := Camera3D.new()
		gm.add_child(cam)
		cam.current = true
		menge.set_density(1.0)
		for i in 600:
			await get_tree().process_frame
			if menge._visitors.size() == menge._target:
				break
		await get_tree().create_timer(3.0).timeout
		var orte := [[Vector3(-6, 1.9, 24), Vector3(0, 1.0, 8)], [Vector3(6, 2.2, 16), Vector3(-2, 1.0, 0)]]
		for i in orte.size():
			cam.global_position = orte[i][0]
			cam.look_at(orte[i][1])
			await get_tree().create_timer(0.5).timeout
			get_viewport().get_texture().get_image().save_png("res://build/blender/npc_spiel_%d.png" % (i + 1))
		print("FERTIG")
		get_tree().quit()
