extends Node
## Kellner mit Tablett im Spiel fotografieren (stehend und gehend).
## Aufruf: VORSCHAU=pfad_%s.png godot --path . res://tools/render_kellner.tscn
const Spielstart := preload("res://tools/spielstart.gd")
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		var gm = await Spielstart.starten(self)
		if gm == null:
			return
		for i in 40: await get_tree().process_frame
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm.set_process(false)
		gm.get_node("HUD").visible = false
		var ich: Node3D = gm._players_nodes[1]
		ich.set_physics_process(false)
		var ort := ich.global_position + (-ich.global_transform.basis.z) * 2.5
		gm._add_staff(991, ort, gm.ROLE_KELLNER, 3)
		var k: Node3D = gm._staff_container.get_child(gm._staff_container.get_child_count() - 1)
		k.set_carrying(4)
		k.set_net(ort, 0.0)
		k.rotation.y = ich.rotation.y + deg_to_rad(60)
		for i in 20: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(OS.get_environment("VORSCHAU") % "stehen")
		# gehen: langsam auf den Spieler zu
		var tw := create_tween()
		tw.tween_method(func(v: Vector3) -> void: k.set_net(v, k.rotation.y), ort, ort + ich.global_transform.basis.x * 1.5, 1.5)
		for i in 25: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(OS.get_environment("VORSCHAU") % "gehen")
		get_tree().quit()
