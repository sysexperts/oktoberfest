extends Node
const Figuren := preload("res://scripts/figuren.gd")
func _ready() -> void:
	for id in [18, 25, 32, 39, 46]:
		var look := Figuren.npc_look(id)
		var f := Figuren.Look.bauen(look)
		add_child(f)
		var namen := []
		for m in f.find_children("*", "MeshInstance3D", true, false):
			if String(m.name).begins_with("hemd") or String(m.name).begins_with("jacke") or String(m.name).begins_with("hose") or String(m.name).begins_with("kleid") or String(m.name).begins_with("dirndl"):
				namen.append(m.name)
		print("LOOK id %d  hemd=%s jacke=%s hose=%s kleid=%s  -> Teile %s" % [id, look.get("hemd"), look.get("jacke"), look.get("hose"), look.get("kleid"), namen])
	get_tree().quit()
