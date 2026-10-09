extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Probelauf des F4-Selbsttests der Leistungsanzeige (mit Fenster).
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0, 0.1, 25)
		await get_tree().create_timer(60.0).timeout
		var a := get_node("/root/Leistungsanzeige")
		a.visible = true
		a._selbsttest(gm)
		await get_tree().create_timer(1.0).timeout
		while a._test_laeuft:
			await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/selbsttest.png")
		get_tree().quit()
