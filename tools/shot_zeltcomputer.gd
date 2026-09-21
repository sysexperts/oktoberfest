extends Node
## Fotografiert den Zelt-Computer (scenes/ui/zeltcomputer.tscn) ohne das ganze
## Spiel zu starten — mit erfundenen Werten, dafür in mehreren Bildgrößen.
## Aufruf: godot --path . res://tools/shot_zeltcomputer.tscn
## Bilder: tools/zeltcomputer_<Breite>x<Hoehe>.png (nicht im Git)

const GROESSEN := [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Gm extends Node:
	var PACK_COST := {1: 40, 2: 50}

class Lauf extends Node:
	func _ready() -> void:
		var hintergrund := ColorRect.new()
		hintergrund.set_anchors_preset(Control.PRESET_FULL_RECT)
		hintergrund.color = Color(0.13, 0.17, 0.26)
		get_tree().root.add_child(hintergrund)
		var ui: Control = load("res://scenes/ui/zeltcomputer.tscn").instantiate()
		get_tree().root.add_child(ui)
		var gm := Gm.new()
		add_child(gm)
		ui.einrichten(gm)
		ui.setze_zustand({
			"stage": 1, "day": 1, "bierpreis": 1.0, "essenpreis": 1.0,
			"bier": 0, "essen": 0, "pending": 0, "shift": false,
			"lic": {"brezn": true},
		})
		ui.visible = true
		for g: Vector2i in GROESSEN:
			DisplayServer.window_set_size(g)
			get_window().size = g
			await _frames(20)
			get_viewport().get_texture().get_image().save_png("res://tools/zeltcomputer_%dx%d.png" % [g.x, g.y])
			print("  gespeichert: %dx%d" % [g.x, g.y])
		print("SCHUSS FERTIG")
		get_tree().quit()

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
