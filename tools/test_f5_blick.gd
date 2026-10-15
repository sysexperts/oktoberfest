extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## F5-Ansicht: Maus schwenkt die Kamera um die Figur, die Figur bleibt stehen (man sieht sie von vorn)
## godot --path . res://tools/test_f5_blick.tscn --resolution 1280x720
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var ok := true
	func _check(n: String, b: bool) -> void:
		print(("OK     " if b else "FEHLER ") + n)
		ok = ok and b
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var sp: CharacterBody3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0, 0.1, 18)
		sp.rotation.y = 0.0
		await _warten(1.0)
		sp._schulterkamera = true
		await _warten(1.5)
		var welt_vorher: float = sp._model.global_rotation.y
		# Maus 180° nach rechts schwenken: der Körper (und die Kamera) drehen sich, die Figur nicht
		sp.rotation.y += PI
		await _warten(1.0)
		var welt_nachher: float = sp._model.global_rotation.y
		_check("Figur blieb stehen beim Schwenken (%.2f → %.2f)" % [welt_vorher, welt_nachher], absf(angle_difference(welt_vorher, welt_nachher)) < 0.1)
		var dir := OS.get_environment("SHOT_DIR")
		if dir != "":
			get_viewport().get_texture().get_image().save_png(dir + "/f5_vorn.png")
		# Laufen: Figur dreht sich in Laufrichtung
		sp.velocity = Vector3(-4.0, 0, 0)
		for i in 40:
			sp._modell_ausrichten(0.05)
		var blick: float = sp._model.global_rotation.y - sp.rotation.y * 0.0
		var soll := atan2(4.0, 0.0)   # Blick nach -X: atan2(-vx, -vz) = atan2(4, 0)
		_check("Figur blickt in Laufrichtung", absf(angle_difference(sp._modell_welt_yaw, soll)) < 0.15)
		sp._schulterkamera = false
		sp.velocity = Vector3.ZERO
		await _warten(1.0)
		_check("zurück in der Ich-Sicht: Figur wieder nach vorn", absf(angle_difference(sp._model.rotation.y, PI)) < 0.1)
		print("ERGEBNIS: %s" % ("BESTANDEN" if ok else "FEHLGESCHLAGEN"))
		get_tree().quit()
