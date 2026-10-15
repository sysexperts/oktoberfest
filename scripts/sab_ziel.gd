extends Node3D
## Eine Stelle in Konrads Zelt, an der man Gustavs Werkzeug einsetzen kann (scenes/sab_ziel.tscn).
## art: "fass" (Fassbohrer), "strom" (Zange), "stink" (Stinkbombe), "juck" (Juckpulver).
## Ablauf: E drücken startet, E gehalten füllt den Balken (die Figur kniet und werkelt, man steht still); loslassen
## oder wegschauen bricht ab. Ist der Balken voll, entscheidet sich hier, ob Konrad oder eine Kamera hinsieht, den
## Rest macht der Server (GameManager.net_sabotage) und lässt an dieser Stelle den Effekt für alle laufen
## (Nebel, Bierstrahl, Funken, Juckstaub) — die Gäste in Konrads Zelt rennen dann hinaus (scripts/huber_figur.gd).
## Der Spieler erkennt die Stelle an den Methoden hinweis_text und sabotage_aktion.

@export_enum("fass", "strom", "stink", "juck") var art := "fass"

## So lange muss E gehalten werden (Sekunden)
const DAUER := {"fass": 2.8, "strom": 3.4, "stink": 2.2, "juck": 2.4}
## So lange läuft der Effekt (Sekunden)
const EFFEKT_DAUER := {"fass": 7.0, "strom": 1.4, "stink": 24.0, "juck": 16.0}
const LICHT_AUS := 45.0
const PFUETZE_BLEIBT := 70.0
## Klang beim Werkeln (scripts/sfx.gd)
const KLANG := {"fass": "scrub", "strom": "scrub", "stink": "sizzle", "juck": "scrub"}

@onready var _balken: Node3D = $Balken
@onready var _balken_vorn: Node3D = $Balken/Vorn

var _spieler: Node = null
var _t := 0.0
var _lichter_aus := false

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("sab_ziel")
	# Der Sicherungskasten ist die einzige Stelle mit eigenem Modell
	var kasten := get_node_or_null("Kasten")
	if kasten:
		kasten.visible = art == "strom"

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(_geschlossen: bool) -> String:
	return "HINT_SAB_" + art.to_upper()

## Der Spieler drückt E: Werkeln beginnt (wenn er Werkzeug hat und es heute noch nicht gemacht hat)
func sabotage_aktion(spieler: Node) -> void:
	if _spieler != null:
		return
	var welt: Node = spieler.get("_world")
	if welt == null:
		return
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	var werkzeug: String = welt.SAB_WERKZEUG[art]
	var inv: Dictionary = z.get("sab_inv", {})
	if int(inv.get(werkzeug, 0)) <= 0:
		hud.melde_text(tr("MSG_SAB_KEIN_WERKZEUG") % tr("SAB_" + werkzeug.to_upper()), 1)
		return
	if int((z.get("sab_tag", {}) as Dictionary).get(art, -1)) == int(z.get("day", -2)):
		hud.melde_text(tr("MSG_SAB_HEUTE_SCHON"), 1)
		return
	if art == "strom" and int((z.get("story", {}) as Dictionary).get("kapitel", 1)) >= int(welt.SAB_SCHLOSS_AB) and int(inv.get("dietrich", 0)) <= 0:
		hud.melde_text(tr("MSG_SAB_SCHLOSS"), 1)
		return
	_spieler = spieler
	_t = 0.0
	spieler.sabotage_beginnen()
	_balken.visible = true
	_balken_vorn.scale.x = 0.001

func _process(delta: float) -> void:
	if _spieler == null:
		return
	if not is_instance_valid(_spieler) or not Input.is_action_pressed("interact") or _spieler.get("_current_target") != self:
		_abbrechen()
		return
	_t += delta
	_balken_vorn.scale.x = clampf(_t / float(DAUER[art]), 0.001, 1.0)
	_spieler._sfx_loop(KLANG[art])
	if _t >= float(DAUER[art]):
		_fertig()

func _abbrechen() -> void:
	if _spieler != null and is_instance_valid(_spieler):
		_spieler.sabotage_ende()
	_spieler = null
	_balken.visible = false

func _fertig() -> void:
	var spieler := _spieler
	_abbrechen()
	var welt: Node = spieler.get("_world")
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	var stufe := int(z.get("tarnung_stufe", 0)) if bool(z.get("tarnung_an", false)) else 0
	var konrad := get_tree().get_first_node_in_group("huber") as Node3D
	var erwischt: bool = konrad != null and konrad.has_method("sieht") and konrad.sieht((spieler as Node3D).global_position, stufe)
	# Konrads Kameras schwenken über die Stellen: wer im Bild steht, fliegt auf
	if not erwischt:
		for k in get_tree().get_nodes_in_group("konrad_kamera"):
			if k.sieht((spieler as Node3D).global_position, stufe):
				erwischt = true
				break
	welt.net_sabotage.rpc_id(1, art, erwischt)

## Der Server hat die Sabotage bestätigt: Effekt für alle (GameManager._net_sab_effekt)
func effekt_abspielen() -> void:
	var name := {"fass": "EffektFass", "strom": "EffektStrom", "stink": "EffektStink", "juck": "EffektJuck"}[art] as String
	var teilchen := get_node(name) as GPUParticles3D
	teilchen.restart()
	teilchen.emitting = true
	get_tree().create_timer(float(EFFEKT_DAUER[art])).timeout.connect(func() -> void:
		if is_instance_valid(teilchen):
			teilchen.emitting = false)
	match art:
		"fass":
			_pfuetze_zeigen()
		"strom":
			_licht_aus()

## Bierlache wächst und trocknet nach einer Weile
func _pfuetze_zeigen() -> void:
	var p := $Pfuetze as MeshInstance3D
	p.visible = true
	p.scale = Vector3(0.05, 1.0, 0.05)
	var tw := create_tween()
	tw.tween_property(p, "scale", Vector3(1.0, 1.0, 1.0), 5.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(PFUETZE_BLEIBT)
	tw.tween_callback(func() -> void: p.visible = false)

## Licht in Konrads Zelt geht aus und nach einer Weile wieder an
func _licht_aus() -> void:
	if _lichter_aus:
		return
	var zelt := get_tree().get_first_node_in_group("huber_zelt")
	if zelt == null:
		return
	var lichter: Array = []
	for l in zelt.find_children("*", "Light3D", true, false):
		lichter.append([l, (l as Light3D).light_energy])
		(l as Light3D).light_energy = 0.0
	_lichter_aus = true
	get_tree().create_timer(LICHT_AUS).timeout.connect(func() -> void:
		for e in lichter:
			if is_instance_valid(e[0]):
				(e[0] as Light3D).light_energy = float(e[1])
		_lichter_aus = false)
