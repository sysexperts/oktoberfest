extends Control
## Sichtprobe des Charakter-Creators: öffnet ihn mit einem Beispiel-Look und speichert ein Bild.
## godot --path . res://tools/render_creator.tscn --resolution 1500x850
const Look := preload("res://scripts/charakter_look.gd")

func _ready() -> void:
	var cc: Control = (load("res://scenes/ui/charakter_creator.tscn") as PackedScene).instantiate()
	add_child(cc)
	await get_tree().process_frame
	var l := Look.standard()
	l["bart"] = "schnauzer"
	l["hut"] = "tirolerhut"
	l["brille"] = "rund"
	l["emotion"] = "wuetend"
	l["augen"] = "gross"
	l["haut"] = Look.HAUTFARBEN[2].to_html(false)
	l["haar"] = "6a6a70"
	cc.oeffnen(l)
	for i in 8:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/blender/creator.png")
	print("FERTIG")
	get_tree().quit()
