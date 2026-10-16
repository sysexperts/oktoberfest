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
		var story: Node = gm.get_node("Story")
		gm._quest_step = gm.QUEST_COUNT
		story.kapitel_setzen(3)
		story.quests["2.6"] = {"z": "erfuellt"}
		await get_tree().create_timer(0.5).timeout
		story.ereignis("wette_gewonnen")
		story.quests["3.2"] = {"z": "erfuellt"}
		story.quests["3.3"] = {"z": "erfuellt"}
		story.ereignis("saboteur_gefasst")
		Game.money = 5000
		gm._tarnung_stufe = 2
		gm._tarnung_an = true
		gm._casino_tag = gm._day
		gm._broadcast_meta()
		await get_tree().create_timer(4.0).timeout
		# Weltkoordinaten: x = 44 - z_zelt, z = -21 + x_zelt (Zelt um 90 Grad gedreht). Tür auf der Wiesenseite bei (58, -12).
		await _bild("1_aussen_vorn", Vector3(64, 2.2, -2.0), Vector3(58, 1.8, -13))
		await _bild("2_tuer", Vector3(58, 1.7, -5.0), Vector3(58, 1.5, -12))
		await _bild("3_ueberblick", Vector3(72, 9, -4), Vector3(57, 1.5, -20))
		await _bild("4_oben", Vector3(58, 38, -21.01), Vector3(58, 0, -21))
		await _bild("5_innen_tuer", Vector3(58, 1.65, -12.9), Vector3(57, 1.3, -22))
		await _bild("6_innen_bar", Vector3(60.5, 1.9, -23.5), Vector3(54.8, 1.2, -20.2))
		await _bild("7_innen_tische", Vector3(54.2, 2.0, -12.9), Vector3(60.5, 1.1, -22.0))
		await _bild("8_innen_slots", Vector3(58.5, 2.0, -26.5), Vector3(53.4, 1.4, -19.0))
		await _bild("9_innen_klavier", Vector3(55.5, 2.0, -24.5), Vector3(61.5, 1.1, -27.0))
		get_tree().quit()
