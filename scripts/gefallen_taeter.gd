extends Node3D
## Täter eines Gefallens (z. B. „Der Spanner"): eine Figur aus dem Creator, die verdächtig herumsteht. Bewusst ohne class_name.
## Wird mit E gepackt (scripts/gefallen.gd) und zu einem Security-Posten getragen. Aufbau: scenes/gefallen/taeter.tscn.

const Figuren := preload("res://scripts/figuren.gd")

var _figur: Figur
var _umschau := 0.0

func _ready() -> void:
	add_to_group("interactable")
	var l := Figuren.npc_look(7001, 3, "m")
	l["hut"] = "baseballcap"
	l["hut_farbe"] = Color(0.12, 0.12, 0.14).to_html(false)
	l["brille"] = "sonnenbrille_eckig"
	l["brille_farbe"] = Color(0.05, 0.05, 0.06).to_html(false)
	_figur = Figuren.einsetzen_look(self, l)
	_figur.stehen()

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(_geschlossen: bool) -> String:
	return "HINT_TAETER_PACKEN"

func gefallen_aktion(spieler: Node) -> void:
	var g := get_tree().get_first_node_in_group("gefallen")
	if g != null and not bool(spieler.get("traegt_taeter")):
		g.net_packen.rpc_id(1)

## Ab und zu verdächtig umschauen
func _process(delta: float) -> void:
	_umschau -= delta
	if _umschau <= 0.0:
		_umschau = randf_range(3.0, 7.0)
		rotation.y += randf_range(-0.9, 0.9)
