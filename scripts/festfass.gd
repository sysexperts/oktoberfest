extends Node3D
## Das Festfass für den Fassanstich: steht am Festtag vor der Bühne, bis es angestochen ist (scenes/festfass.tscn).
## Der Spieler erkennt es an hinweis_text und fest_aktion (Duck-Typing, kein class_name). Die Anzeige liegt in
## scenes/ui/fassanstich.tscn, der Server wertet aus (GameManager.net_fassanstich).

var _t := 0.0

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.4
	var welt := get_tree().current_scene
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	var offen := bool(z.get("anstich_offen", false))
	visible = offen
	if offen:
		add_to_group("interactable")
	else:
		remove_from_group("interactable")

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(_geschlossen: bool) -> String:
	return "HINT_FASSANSTICH"

func fest_aktion(spieler: Node) -> void:
	var anzeige := get_tree().get_first_node_in_group("fassanstich_ui")
	if anzeige != null:
		anzeige.zeigen(spieler)
