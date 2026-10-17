extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft F8 (Zerlegung der Bildzeit): läuft durch, schreibt user://leistungstest.txt, stellt alles wieder her.
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
		var la: CanvasLayer = get_tree().root.get_node("Leistungsanzeige")
		la.visible = true
		var e := InputEventKey.new()
		e.keycode = KEY_F8
		e.pressed = true
		la._unhandled_input(e)
		var ende := Time.get_ticks_msec() + 420000
		await get_tree().create_timer(2.0).timeout
		while la._test_laeuft and Time.get_ticks_msec() < ende:
			await get_tree().process_frame
		var f := FileAccess.open("user://leistungstest.txt", FileAccess.READ)
		var t := f.get_as_text() if f else ""
		print(t)
		var ok: bool = t.contains("alle Skripte aus") and t.contains("Töne aus") and gm.process_mode == Node.PROCESS_MODE_INHERIT and gm.is_processing() and not get_viewport().disable_3d
		print("ERGEBNIS: ", "OK" if ok else "FEHLGESCHLAGEN")
		get_tree().quit()
