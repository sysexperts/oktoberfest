extends Node
## Bilder vom Studio-Intro zu festen Zeitpunkten. Aufruf: godot --path . res://tools/render_intro.tscn
func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/hauptmenue.tscn")

class Lauf extends Node:
	func _ready() -> void:
		var ziel := OS.get_environment("VORSCHAU")
		var start := Time.get_ticks_msec()
		for t: float in [2.0, 3.8, 4.4, 5.5]:
			while Time.get_ticks_msec() - start < t * 1000.0:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(ziel % str(t))
		get_tree().quit()
