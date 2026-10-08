extends Node
## Hauptmenü mit der Überschreiben-Rückfrage fotografieren → SHOT_DIR/dialog.png

func _ready() -> void:
	var m := (load("res://scenes/ui/hauptmenue.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(m)
	await get_tree().create_timer(3.0).timeout
	var d := m.get_node("%NeuBestaetigen") as ConfirmationDialog
	d.dialog_text = tr("NEWGAME_CONFIRM_TITLE") + "\n" + tr("NEWGAME_CONFIRM_TEXT")
	d.popup_centered()
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/dialog.png")
	get_tree().quit()
