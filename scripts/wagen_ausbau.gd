extends Node3D
## Einrichtung im Wohnwagen (scenes/wohnwagen_innen.tscn): zeigt nur, was gekauft wurde (Stand aus dem Zustand
## des GameManagers, "wagen"), und den goldenen Krug auf dem Trophäenregal, sobald der Titel Fest-Meister da ist.

var _t := 0.0

func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.5
	var welt := get_tree().current_scene
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	var items: Array = (z.get("wagen", {}) as Dictionary).get("items", [])
	for k in get_children():
		(k as Node3D).visible = items.has(String(k.name).to_lower())
	var krug := get_node_or_null("Regal/GoldKrug") as Node3D
	if krug:
		krug.visible = items.has("regal") and int(z.get("meister_titel", 0)) > 0
