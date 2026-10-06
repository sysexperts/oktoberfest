extends Node3D
## Gehege für die ausgebüxte Sau (Gefallen „Die Sau ist los", scripts/gefallen.gd). Bewusst ohne class_name.
## Wer die Sau trägt, setzt sie hier mit E ab. Aufbau: scenes/gefallen/gehege.tscn.

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("gefallen_gehege")

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func _spieler() -> Node:
	var gm := get_tree().current_scene
	return gm._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in gm else null

func hinweis_text(_geschlossen: bool) -> String:
	var sp := _spieler()
	return "HINT_GEHEGE_ABSETZEN" if sp != null and bool(sp.get("traegt_taeter")) else "HINT_GEHEGE"

func gefallen_aktion(spieler: Node) -> void:
	var g := get_tree().get_first_node_in_group("gefallen")
	if g != null and bool(spieler.get("traegt_taeter")):
		g.net_uebergeben.rpc_id(1)
