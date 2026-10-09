extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Wohnwagengasse von oben und auf Augenhöhe → SHOT_DIR/gasse_oben.png, gasse_boden.png
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _bild(name: String, von: Vector3, nach: Vector3) -> void:
		var k := Camera3D.new()
		get_tree().current_scene.add_child(k)
		k.global_position = von
		k.look_at(nach, Vector3.UP)
		k.current = true
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/gasse_%s.png" % name)
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		await get_tree().create_timer(3.0).timeout
		await _bild("oben", Vector3(-10, 38, -50), Vector3(-10, 0, -50.5))
		await _bild("boden", Vector3(-3, 1.7, -40), Vector3(-17, 1.2, -52))
		get_tree().quit()
