extends Node
## Leistungsanzeige (F3) fotografieren → SHOT_DIR/leistung.png
func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	var a := get_node("/root/Leistungsanzeige")
	a.visible = true
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/leistung.png")
	get_tree().quit()
