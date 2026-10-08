extends Node3D
## Täter eines Gefallens: eine Figur aus dem Creator. Bewusst ohne class_name. Aufbau: scenes/gefallen/taeter.tscn.
##   art "spanner": steht verdächtig herum (Sonnenbrille, Cap)
##   art "sau":     eine ausgebüxte Sau (assets/models/sau.glb, tools/blender/sau.py), rennt wie der Dieb weg
##   art "dieb":    läuft durch die Menge und rennt vor Spielern weg (scripts/gefallen.gd simuliert ihn auf dem Server,
##                  hier wird nur sanft zur gemeldeten Position gelaufen)
## Wird mit E gepackt (scripts/gefallen.gd) und zu einem Security-Posten getragen.

const Figuren := preload("res://scripts/figuren.gd")
const SAU := preload("res://assets/models/sau.glb")

## Muss vor add_child gesetzt werden
var art := "spanner"
## Aussehen des Täters (aus dem Quest-Feld gefallen.figur): "", "faelscher", "kruege", "reporter"
var figur := ""
var _figur: Figur
var _umschau := 0.0
var _ziel := Vector3.ZERO
var _hat_ziel := false
var _tempo := 0.0
var _anim := ""
var _sau: Node3D
var _lauf_t := 0.0
## Gepackt: scripts/gefallen.gd setzt ihn jetzt jedes Bild auf die Schulter des Trägers, er läuft nicht mehr selbst
var getragen := false

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("gefallen_taeter")
	if art == "sau":
		_sau = SAU.instantiate() as Node3D
		_sau.rotation.y = PI   # Modell blickt nach +Z, die Spielwelt nach -Z
		add_child(_sau)
		return
	var l: Dictionary
	if art == "spion":
		l = Figuren.npc_look(7003, 9, "m")
		l["hut"] = "melone"
		l["hut_farbe"] = Color(0.18, 0.12, 0.1).to_html(false)
		l["brille"] = "sonnenbrille_rund"
		l["brille_farbe"] = Color(0.05, 0.05, 0.06).to_html(false)
	elif art == "dieb":
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
	match figur:
		"faelscher":
			l = Figuren.npc_look(7004, 11, "m")
			l["hut"] = "melone"
			l["hut_farbe"] = Color(0.12, 0.12, 0.14).to_html(false)
			l["brille"] = "monokel"
			l["brille_farbe"] = Color(0.75, 0.6, 0.2).to_html(false)
			l["bart"] = "schnauzer"
		"kruege":
			l = Figuren.npc_look(7005, 13, "m")
			l["hut"] = "fischerhut"
			l["hut_farbe"] = Color(0.3, 0.32, 0.2).to_html(false)
			l["bart"] = "vollbart"
		"reporter":
			l = Figuren.npc_look(7006, 17, "w")
			l["hut"] = "schiebermuetze"
			l["hut_farbe"] = Color(0.45, 0.3, 0.2).to_html(false)
			l["brille"] = "wayfarer"
			l["brille_farbe"] = Color(0.1, 0.1, 0.12).to_html(false)
	_figur = Figuren.einsetzen_look(self, l)
	# Die Figuren schauen nicht in Godots Standardrichtung (wie bei den Besuchern)
	_figur.rotation.y = deg_to_rad(180.0)
	_figur.stehen()
	_anim = "stehen"

## Auf dem Arm: strampelt (wie der gepackte Raufbold in scripts/pruegel/raufbold.gd)
func zappeln() -> void:
	if art == "sau":
		_tempo = 6.0
		_sau_laufen(get_process_delta_time())
	elif _figur != null and _anim != "rennen":
		_anim = "rennen"
		_figur.rennen(1.3)

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(_geschlossen: bool) -> String:
	return "HINT_SAU_PACKEN" if art == "sau" else "HINT_TAETER_PACKEN"

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
	if getragen:
		return
	if art == "sau":
		if _hat_ziel:
			global_position = global_position.lerp(_ziel, clampf(delta * 10.0, 0.0, 1.0))
		_sau_laufen(delta)
		return
	if art == "dieb" or art == "spion":
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

## Beine schwingen diagonal, der Rumpf wippt; steht die Sau, sind alle Beine still
func _sau_laufen(delta: float) -> void:
	if _sau == null:
		return
	var schwung := 0.0
	if _tempo > 0.3:
		_lauf_t += delta * (6.0 + _tempo * 2.4)
		schwung = 0.75 if _tempo > 3.5 else 0.45
	var s := sin(_lauf_t) * schwung
	for n in ["BeinVL", "BeinHR"]:
		var b := _sau.get_node_or_null(n) as Node3D
		if b:
			b.rotation.x = s
	for n in ["BeinVR", "BeinHL"]:
		var b := _sau.get_node_or_null(n) as Node3D
		if b:
			b.rotation.x = -s
	_sau.position.y = absf(sin(_lauf_t)) * 0.05 * (schwung * 2.0)
