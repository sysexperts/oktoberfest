extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft die F3-Mitschrift (user://leistung_log.csv): Anzeige an, ein paar Sekunden warten, Datei hat Kopf und Zeilen.
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		if FileAccess.file_exists("user://leistung_log.csv"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://leistung_log.csv"))
		var la: CanvasLayer = get_tree().root.get_node("Leistungsanzeige")
		var e := InputEventKey.new()
		e.keycode = KEY_F3
		e.pressed = true
		la._unhandled_input(e)
		await get_tree().create_timer(12.0).timeout
		var f := FileAccess.open("user://leistung_log.csv", FileAccess.READ)
		var zeilen: PackedStringArray = f.get_as_text().strip_edges().split("\n") if f else PackedStringArray()
		print("Zeilen: ", zeilen.size())
		for z in zeilen:
			print(z)
		print("ERGEBNIS: ", "OK" if zeilen.size() >= 3 and la.visible else "FEHLGESCHLAGEN")
		get_tree().quit()
