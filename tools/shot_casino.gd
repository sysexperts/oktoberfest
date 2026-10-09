extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Das Casino mit freien Kameras: außen, Tür, innen aus drei Ecken, von oben → SHOT_DIR/casino_ansicht_*.png
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _bild(name: String, von: Vector3, nach: Vector3) -> void:
		var k := Camera3D.new()
		get_tree().current_scene.add_child(k)
		k.fov = 75.0
		k.global_position = von
		k.look_at(nach)
		k.current = true
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/casino_ansicht_%s.png" % name)
		k.queue_free()
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._start_shift()
		gm._zelt_offen = true
		await get_tree().create_timer(4.0).timeout
		await _bild("1_aussen", Vector3(80, 2.2, -21), Vector3(64, 1.4, -21))
		await _bild("2_tuer", Vector3(68.5, 1.7, -21), Vector3(62, 1.3, -21))
		await _bild("3_innen_ecke1", Vector3(62.5, 2.3, -16.2), Vector3(55, 1.0, -24))
		await _bild("4_innen_ecke2", Vector3(53.6, 2.3, -25.6), Vector3(61, 1.0, -18))
		await _bild("5_innen_ecke3", Vector3(62.5, 2.3, -26), Vector3(54.5, 1.0, -17))
		await _bild("6_oben", Vector3(58.6, 22, -21.01), Vector3(58.6, 0, -21))
		get_tree().quit()
