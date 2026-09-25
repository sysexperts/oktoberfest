extends Node
## Fotografiert den Warteraum (scenes/ui/koop_lobby.tscn): Startansicht und
## Warteraum mit drei erfundenen Mitspielern. Fragt keinen Vermittler.
## Aufruf: godot --path . res://tools/render_koop_lobby.tscn --resolution 1280x720
## Bilder: tools/koop_lobby_start_<breite>.png, tools/koop_lobby_raum_<breite>.png (nicht im Git)

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	func _ready() -> void:
		TranslationServer.set_locale("de")
		get_tree().change_scene_to_file("res://scenes/ui/koop_lobby.tscn")
		for i in 600:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("_anzeigen"):
				break
			await get_tree().process_frame
		var lobby := get_tree().current_scene
		var breite := get_viewport().get_visible_rect().size.x
		var fenster := DisplayServer.window_get_size().x
		(lobby.get_node("%StartName") as LineEdit).text = "Fest-Sepp"
		await _frames(40)
		_foto("koop_lobby_start_%d" % fenster)
		lobby._id = "a1"
		lobby._code = "BREZN-42"
		lobby._figur = 2
		lobby._name_gesendet = "Fest-Sepp"
		lobby._raum = {"code": "BREZN-42", "status": "warten", "port": 0, "host": "a1", "max": 4, "fehler": "",
			"spieler": [
				{"id": "a1", "name": "Fest-Sepp", "figur": 2, "host": true, "ich": true},
				{"id": "b2", "name": "Anna", "figur": 1, "host": false, "ich": false},
				{"id": "c3", "name": "Toni", "figur": 0, "host": false, "ich": false},
			]}
		lobby.get_node("%Start").visible = false
		lobby.get_node("%Warteraum").visible = true
		lobby._anzeigen()
		await _frames(60)
		_foto("koop_lobby_raum_%d" % fenster)
		print("  Ansichtsbreite %d, Fenster %d" % [breite, fenster])
		print("RENDER FERTIG")
		get_tree().quit()

	func _foto(name: String) -> void:
		get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
		print("  gespeichert: ", name)

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
