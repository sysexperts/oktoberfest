extends SceneTree
func _init() -> void:
	var ps := load("res://scenes/menu.tscn") as PackedScene
	print("menu.tscn geladen: ", ps != null)
	var n := ps.instantiate()
	print("Wurzel: ", n.name, "  Skript: ", n.get_script().resource_path if n.get_script() else "KEINS")
	print("UpdateHinweis gefunden: ", n.get_node_or_null("%UpdateHinweis") != null)
	print("hauptmenue.tscn existiert: ", ResourceLoader.exists("res://scenes/ui/hauptmenue.tscn"))
	print("autoload/Einstellungen im Projekt: ", ProjectSettings.has_setting("autoload/Einstellungen"))
	n.free()
	quit()
