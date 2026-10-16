extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft F7 (Skript-Rangliste der Leistungsanzeige): Datei user://leistung_skripte.txt entsteht mit Zeilen.
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://leistung_skripte.txt"))
		var la: CanvasLayer = get_tree().root.get_node("Leistungsanzeige")
		la.visible = true
		var e := InputEventKey.new()
		e.keycode = KEY_F7
		e.pressed = true
		la._unhandled_input(e)
		var ende := Time.get_ticks_msec() + 400000
		while la._rangliste_laeuft and Time.get_ticks_msec() < ende:
			await get_tree().process_frame
		var f := FileAccess.open("user://leistung_skripte.txt", FileAccess.READ)
		var t := f.get_as_text() if f else ""
		print(t.left(700))
		print("ERGEBNIS: ", "OK" if t.count("\n") >= 5 else "FEHLGESCHLAGEN")
		get_tree().quit()
