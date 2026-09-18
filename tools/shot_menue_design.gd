extends Node
## Neues Menü-Design (scenes/ui/menue_design_test.tscn) fotografieren → SHOT_DIR/menue_design*.png

func _ready() -> void:
	var m := (load("res://scenes/ui/menue_design_test.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(m)
	await get_tree().create_timer(3.0).timeout
	var dir := OS.get_environment("SHOT_DIR")
	get_viewport().get_texture().get_image().save_png(dir + "/menue_design.png")
	# Hover auf „Spiel laden" nachstellen
	var laden := m.get_node("Mitte/Spalte/Laden") as Button
	laden.add_theme_stylebox_override("normal", laden.get_theme_stylebox("hover"))
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png(dir + "/menue_design_hover.png")
	get_tree().quit()
