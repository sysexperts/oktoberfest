extends Node3D
## Fotografiert Konrads Auftritt beim großen Fest (build/konrad_fest.png).
##   godot --path . res://tools/render_konrad_fest.tscn --resolution 1280x720
var _players_nodes := {}

func _ready() -> void:
	var attrappe := GDScript.new()
	attrappe.source_code = "extends Node
var minispiel
"
	attrappe.reload()
	var sp := Node.new()
	sp.set_script(attrappe)
	add_child(sp)
	_players_nodes[1] = sp
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.02, 0.03, 0.09)
	add_child(env)
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true
	kamera.look_at_from_position(Vector3(0, 2, 20), Vector3(0, 20, 0))
	var fw: Node3D = (load("res://scenes/effekte/feuerwerk.tscn") as PackedScene).instantiate()
	add_child(fw)
	fw.ausloesen(14, 0.12)
	var dialog: Node = (load("res://scenes/ui/dialog.tscn") as PackedScene).instantiate()
	add_child(dialog)
	await get_tree().process_frame
	dialog.zeigen("Konrad", [String(TranslationServer.translate("KONRAD_FEST_1_DU"))] as Array[String])
	await get_tree().create_timer(2.2).timeout
	get_viewport().get_texture().get_image().save_png("res://build/konrad_fest.png")
	print("RENDER FERTIG")
	get_tree().quit()
