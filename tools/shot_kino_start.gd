extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Neue Eröffnung prüfen: Titel und Kamerafahrt, dann Horst (Begrüßung, Brief, Frage, Ja) → build/kino_start_*.png
##   godot --path . res://tools/shot_kino_start.tscn --resolution 1600x900

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _bild(name: String) -> void:
		get_viewport().get_texture().get_image().save_png("res://build/kino_start_%s.png" % name)

	func _warten(s: float) -> void:
		await get_tree().create_timer(s).timeout

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		TranslationServer.set_locale("de")
		var kino = gm.get_node("Kino")
		var dialog = gm.get_node("Dialog")
		var chef = gm.get_node("Kirmes/Festleiter")
		var sp: Node3D = gm._players_nodes.get(1)
		print("Eröffnung läuft: ", kino.aktiv, " Modus ", kino._modus, " t ", kino._titel_t)
		kino._titel_t = 0.0
		for ziel in [2.8, 5.0, 8.3, 10.6]:
			while kino._modus == "titel" and kino._titel_t < ziel:
				await get_tree().process_frame
			_bild("t%.1f" % ziel)
		while kino.aktiv:
			await get_tree().process_frame
		print("Eröffnung vorbei: ", not kino.aktiv)
		_bild("3_tor")
		# Horst ansprechen: Begrüßung, Brief, Frage
		sp.global_position = chef.global_position + Vector3(-3.0, 0.1, 0)
		sp.look_at(chef.global_position + Vector3(0, 0.1, 0), Vector3.UP)
		await _warten(0.5)
		chef.ansprechen()
		await _warten(0.8)
		_bild("4_horst")
		for i in 3:
			await _warten(0.5)
			dialog._weiter()
		await _warten(1.0)
		print("Brief offen: ", kino.aktiv)
		_bild("5_brief")
		kino._weiter()
		await _warten(0.4)
		kino._weiter()
		await _warten(0.4)
		kino._weiter()
		await _warten(3.5)
		print("Brief zu: ", not kino.aktiv, "  Dialog offen: ", dialog.aktiv)
		_bild("6_frage")
		print("FERTIG")
		get_tree().quit()
