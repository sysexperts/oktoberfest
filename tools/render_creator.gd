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
	if "w" in OS.get_cmdline_user_args():
		l = Look.standard("w")
		l["frisur"] = OS.get_cmdline_user_args()[1] if OS.get_cmdline_user_args().size() > 1 else "bob"
		l["haar"] = "8a4a22"
		if "hut" in OS.get_cmdline_user_args():
			l["hut"] = "tirolerhut"
			l["hut_farbe"] = "4a6a3a"
	cc.oeffnen(l)
	for i in 3:
		cc._tab_zeigen(i, false)
		for j in 60:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://build/blender/creator_%d.png" % i)
	print("FERTIG")
	get_tree().quit()
