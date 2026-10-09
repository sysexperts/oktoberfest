extends Node
## Zeigt den Pose-Editor kurz und speichert ein Bild nach build/pose_editor.png
## godot --path . res://tools/pose_editor_schuss.tscn --resolution 1600x900
func _ready() -> void:
	var e := (load("res://tools/pose_editor.tscn") as PackedScene).instantiate()
	add_child(e)
	for i in 20:
		await get_tree().process_frame
	e.get_node("Oberflaeche/Leiste/Spalte/Ansichten/HandNah").pressed.emit()
	for i in 20:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/pose_editor.png")
	get_tree().quit()
