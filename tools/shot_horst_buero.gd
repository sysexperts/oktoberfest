extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Büroraum mit Computer und Festbüro-Hütte mit Schreibtisch (build/horst_buero_*.png).
## godot --path . res://tools/shot_horst_buero.tscn --resolution 1600x900

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _bild(name: String, von: Vector3, nach: Vector3) -> void:
		var k := Camera3D.new()
		get_tree().current_scene.add_child(k)
		k.global_position = von
		k.look_at(nach)
		k.current = true
		await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_png("res://build/horst_buero_%s.png" % name)

	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var horst := get_tree().get_first_node_in_group("festleiter") as Node3D
		if horst:
			horst.global_position = Vector3(-9.7, 0, 9)
		await _bild("raum", Vector3(-9.1, 1.9, 6.0), Vector3(-10.2, 1.0, 10.4))
		await _bild("huette", Vector3(33, 2.5, 22), Vector3(41.5, 1.0, 18.4))
		get_tree().quit()
