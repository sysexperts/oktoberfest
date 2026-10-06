extends Node3D
## Täter eines Gefallens: eine Figur aus dem Creator. Bewusst ohne class_name. Aufbau: scenes/gefallen/taeter.tscn.
##   art "spanner": steht verdächtig herum (Sonnenbrille, Cap)
##   art "dieb":    läuft durch die Menge und rennt vor Spielern weg (scripts/gefallen.gd simuliert ihn auf dem Server,
##                  hier wird nur sanft zur gemeldeten Position gelaufen)
## Wird mit E gepackt (scripts/gefallen.gd) und zu einem Security-Posten getragen.

const Figuren := preload("res://scripts/figuren.gd")

## Muss vor add_child gesetzt werden
var art := "spanner"
var _figur: Figur
var _umschau := 0.0
var _ziel := Vector3.ZERO
var _hat_ziel := false
var _tempo := 0.0
var _anim := ""

func _ready() -> void:
	add_to_group("interactable")
	var l: Dictionary
	if art == "dieb":
		l = Figuren.npc_look(7002, 5, "m")
		l["hut"] = "wollmuetze"
		l["hut_farbe"] = Color(0.1, 0.1, 0.12).to_html(false)
		l["brille"] = "ohne"
	else:
		l = Figuren.npc_look(7001, 3, "m")
		l["hut"] = "baseballcap"
		l["hut_farbe"] = Color(0.12, 0.12, 0.14).to_html(false)
		l["brille"] = "sonnenbrille_eckig"
		l["brille_farbe"] = Color(0.05, 0.05, 0.06).to_html(false)
	_figur = Figuren.einsetzen_look(self, l)
	# Die Figuren schauen nicht in Godots Standardrichtung (wie bei den Besuchern)
	_figur.rotation.y = deg_to_rad(180.0)
	_figur.stehen()
	_anim = "stehen"

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(_geschlossen: bool) -> String:
	return "HINT_TAETER_PACKEN"

func gefallen_aktion(spieler: Node) -> void:
	var g := get_tree().get_first_node_in_group("gefallen")
	if g != null and not bool(spieler.get("traegt_taeter")):
		g.net_packen.rpc_id(1)

## Server meldet Ort, Blickrichtung und Tempo des Diebs
func ziel_setzen(pos: Vector3, yaw: float, tempo: float) -> void:
	if not _hat_ziel:
		global_position = pos
	_hat_ziel = true
	_ziel = pos
	_tempo = tempo
	rotation.y = lerp_angle(rotation.y, yaw, 0.5)

func _process(delta: float) -> void:
	if art == "dieb":
		if _hat_ziel:
			global_position = global_position.lerp(_ziel, clampf(delta * 10.0, 0.0, 1.0))
		var neu := "rennen" if _tempo > 3.5 else ("gehen" if _tempo > 0.3 else "stehen")
		if neu != _anim and _figur != null:
			_anim = neu
			match neu:
				"rennen": _figur.rennen(1.3)
				"gehen": _figur.gehen(1.0)
				_: _figur.stehen()
		return
	# Spanner: ab und zu verdächtig umschauen
	_umschau -= delta
	if _umschau <= 0.0:
		_umschau = randf_range(3.0, 7.0)
		rotation.y += randf_range(-0.9, 0.9)
