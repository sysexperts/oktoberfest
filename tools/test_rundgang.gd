extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Rundgang des Festleiters prüfen: Tutorialschritte der Reihe nach setzen,
## warten bis er an der Station steht, ansprechen, Bild. → SHOT_DIR/rundgang_*.png

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		TranslationServer.set_locale("de")
		await _warten(5.0)
		var dialog = gm.get_node("Dialog")
		var chef = gm.get_node("Kirmes/Festleiter")
		var sp: Node3D = gm._players_nodes.get(1)
		var dir := OS.get_environment("SHOT_DIR")
		print("Start: neues ", chef.hat_neues(), " bei ", chef.global_position)

		for s in [1, 2, 3, 5, 7, 8, 10, 14]:
			gm._quest_step = s
			var t := 0.0
			await _warten(0.2)
			while chef.unterwegs() and t < 90.0:
				await _warten(0.5)
				t += 0.5
			var vorn: Vector3 = chef.global_position + chef.global_transform.basis.z * 2.2
			sp.global_position = vorn + Vector3(0, 0.1, 0)
			sp.look_at(chef.global_position + Vector3(0, 0.1, 0), Vector3.UP)
			await _warten(0.4)
			var neu: bool = chef.hat_neues()
			chef.ansprechen()
			await _warten(1.5)
			_bild(dir + "/rundgang_%d.png" % s)
			print("Schritt %d: %.0f s gelaufen, bei %s, neues %s, Text: %s" % [s, t, chef.global_position, neu, dialog._text.text.left(50)])
			while dialog.aktiv:
				dialog._weiter()
				await _warten(0.1)
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _bild(pfad: String) -> void:
		Schuss.speichern(get_viewport(), pfad)
