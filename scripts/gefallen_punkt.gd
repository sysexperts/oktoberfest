extends Node3D
## Ein Punkt in einem Gefallen, an dem man mit E etwas tut (scripts/gefallen.gd). Bewusst ohne class_name.
##   variante "sturm":  lose Plane, die vor dem Sturm gesichert werden muss
##   variante "feuer":  Feuer an einer Bude, braucht einen Eimer Wasser
##   variante "quelle": Brunnen, an dem man den Eimer füllt
## Aufbau: scenes/gefallen/punkt.tscn (alle Teile sind Knoten, das Skript blendet nur die der Variante ein).

var variante := "sturm"
var index := 0
var erledigt := false

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("gefallen_punkt")
	$Plane.visible = variante == "sturm"
	$Feuer.visible = variante == "feuer"
	$Brunnen.visible = variante == "quelle"
	var etikett := get_node_or_null("Label") as Label3D
	if etikett:
		etikett.visible = variante == "quelle"

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func erledigt_setzen() -> void:
	erledigt = true
	remove_from_group("interactable")
	match variante:
		"sturm":
			$Plane.rotation = Vector3.ZERO
			$Plane.scale = Vector3(1, 1, 1)
			$Plane.position.y = 1.4
		"feuer":
			$Feuer.visible = false

func _spieler() -> Node:
	var gm := get_tree().current_scene
	return gm._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in gm else null

func hinweis_text(_geschlossen: bool) -> String:
	match variante:
		"sturm":
			return "HINT_STURM_SICHERN"
		"feuer":
			var sp := _spieler()
			return "HINT_FEUER_LOESCHEN" if sp != null and bool(sp.get("traegt_wasser")) else "HINT_FEUER_WASSER"
	return "HINT_QUELLE"

func gefallen_aktion(_spieler_knoten: Node) -> void:
	var g := get_tree().get_first_node_in_group("gefallen")
	if g == null:
		return
	if variante == "quelle":
		g.net_wasser.rpc_id(1)
	else:
		g.net_punkt.rpc_id(1, index)

## Planen flattern, Flammen flackern
func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	if variante == "sturm" and not erledigt:
		$Plane.rotation = Vector3(sin(t * 5.0 + index) * 0.35, 0.0, cos(t * 4.0 + index) * 0.3)
	elif variante == "feuer" and not erledigt:
		var licht := $Feuer/Licht as OmniLight3D
		licht.light_energy = 2.2 + sin(t * 17.0 + index) * 0.6
		$Feuer.scale = Vector3(1, 1.0 + sin(t * 11.0 + index) * 0.12, 1)
