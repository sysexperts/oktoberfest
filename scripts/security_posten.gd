extends Node3D
## Fester Security-Posten auf der Kirmes: steht da und nimmt Täter entgegen, die man ihm bringt (scripts/gefallen.gd).
## Bewusst ohne class_name. Aufbau: scenes/gefallen/security_posten.tscn.

const Figuren := preload("res://scripts/figuren.gd")

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("security_posten")
	var f := Figuren.einsetzen_beruf(self, 8100 + int(absf(global_position.x + global_position.z)) % 50, "security")
	f.stehen()

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func _spieler() -> Node:
	var gm := get_tree().current_scene
	return gm._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in gm else null

func hinweis_text(_geschlossen: bool) -> String:
	var sp := _spieler()
	return "HINT_SECURITY_UEBERGEBEN" if sp != null and bool(sp.get("traegt_taeter")) else "HINT_SECURITY_HALLO"

func gefallen_aktion(spieler: Node) -> void:
	var g := get_tree().get_first_node_in_group("gefallen")
	if g != null and bool(spieler.get("traegt_taeter")):
		g.net_uebergeben.rpc_id(1)
