extends CanvasLayer
## Einleitung („Warum betreiben wir überhaupt ein Zelt?"): Kamerafahrt am
## Kirmestor, Untertitel mit Sprechernamen, danach die erste Mission
## „Folge dem Wiesnchef zum Zelt". Aufbau: scenes/ui/kino.tscn.
##
## Läuft einmal beim ersten Start eines neuen Spielstands. Der Server startet sie
## (game_manager.net_kino_start), danach spielt sie bei jedem Spieler lokal —
## gesendet wird nur Start und Überspringen. Esc/Enter überspringt für alle.
##
## Die Texte liegen in locale/texte.csv doppelt: INTRO_<n>_DU für Solo und
## INTRO_<n>_IHR für Koop. Welche Fassung gilt, entscheidet die Spielerzahl.

## Ein Schritt: Dauer, Kamera von → nach, Blickziel ("chef", "spieler" oder Punkt),
## Sprecher (Schlüssel) und Textschlüssel (ohne _DU/_IHR).
const SCHRITTE := [
	{"dauer": 5.0, "von": Vector3(0, 5.2, 105), "nach": Vector3(0, 2.6, 94), "blick": Vector3(0, 1.7, 88),
		"sprecher": "INTRO_NAME_FREUND", "text": "INTRO_1"},
	{"dauer": 4.5, "von": Vector3(5.5, 2.1, 93.5), "nach": Vector3(4.0, 1.9, 91.5), "blick": "spieler",
		"sprecher": "INTRO_NAME_SPIELER", "text": "INTRO_2"},
	{"dauer": 6.0, "von": Vector3(6.0, 2.0, 85.0), "nach": Vector3(4.8, 1.8, 83.8), "blick": "chef",
		"sprecher": "INTRO_NAME_CHEF", "text": "INTRO_3"},
	{"dauer": 5.5, "von": Vector3(-3.8, 1.9, 84.5), "nach": Vector3(-3.0, 1.8, 83.5), "blick": "chef",
		"sprecher": "INTRO_NAME_CHEF", "text": "INTRO_4"},
	{"dauer": 4.5, "von": Vector3(-4.5, 2.0, 84.0), "nach": Vector3(-3.8, 1.9, 85.2), "blick": "spieler",
		"sprecher": "INTRO_NAME_SPIELER", "text": "INTRO_5"},
	{"dauer": 4.5, "von": Vector3(-4.8, 1.8, 83.0), "nach": Vector3(-4.0, 1.75, 82.2), "blick": "chef",
		"sprecher": "INTRO_NAME_CHEF", "text": "INTRO_6"},
	{"dauer": 6.5, "von": Vector3(4.2, 2.0, 84.5), "nach": Vector3(3.2, 1.9, 85.6), "blick": "spieler",
		"sprecher": "INTRO_NAME_SPIELER", "text": "INTRO_7"},
	{"dauer": 6.5, "von": Vector3(5.0, 1.9, 84.2), "nach": Vector3(4.0, 1.8, 83.2), "blick": "chef",
		"sprecher": "INTRO_NAME_CHEF", "text": "INTRO_8"},
	{"dauer": 4.0, "von": Vector3(3.5, 2.6, 83.0), "nach": Vector3(0.0, 9.0, 90.0), "blick": "chef",
		"sprecher": "INTRO_NAME_CHEF", "text": "INTRO_9", "chef_geht": true},
]

## Wo die Spieler während der Einleitung stehen (Reihenfolge = Spielerliste)
const PLAETZE := [Vector3(-1.8, 0.1, 88.0), Vector3(1.8, 0.1, 88.0), Vector3(-4.0, 0.1, 89.0), Vector3(4.0, 0.1, 89.0)]

@onready var _kamera: Camera3D = $Kamera
@onready var _balken_oben: ColorRect = %BalkenOben
@onready var _balken_unten: ColorRect = %BalkenUnten
@onready var _sprecher: Label = %Sprecher
@onready var _text: Label = %Text
@onready var _hinweis: Label = %Hinweis

var aktiv := false
var _schritt := -1
var _t := 0.0
var _spieler: Node = null
var _chef: Node3D = null
var _mehrere := false
var _hud: Node = null
var _marker: Node3D = null

func _ready() -> void:
	visible = false

## Läuft gerade ein Werkzeug aus tools/ (Test, Bilder)? Dann keine Einleitung —
## sie würde Eingaben blockieren und die Kamera übernehmen. Das Kino-Werkzeug
## selbst will sie natürlich sehen.
static func werkzeuglauf() -> bool:
	for a in OS.get_cmdline_args():
		if a.begins_with("res://tools/") and not a.contains("kino"):
			return true
	return false

## player.gd hält die Einleitung wie ein Minispiel (blockiert Bewegung)
func laeuft() -> bool:
	return aktiv

func starten(mehrere: bool) -> void:
	if aktiv:
		return
	var welt := get_parent()
	_mehrere = mehrere
	_chef = welt.get_tree().get_first_node_in_group("wiesnchef") as Node3D
	_spieler = welt._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in welt else null
	if _spieler == null:
		return
	aktiv = true
	visible = true
	_schritt = -1
	# Alle Figuren ans Tor stellen: jeder setzt seine eigene, die Reihenfolge ist
	# die Spielerliste, damit niemand auf demselben Fleck landet.
	var ids: Array = (welt._players_nodes as Dictionary).keys()
	ids.sort()
	var platz: int = maxi(0, ids.find(multiplayer.get_unique_id()))
	_spieler.global_position = PLAETZE[platz % PLAETZE.size()]
	# Spielerkamera schaut bei Drehung 0 nach -Z, also nach Süden in die Kirmes
	(_spieler as Node3D).rotation.y = 0.0
	_spieler.minispiel = self
	if _chef and _chef.has_method("warten"):
		_chef.warten()
	# HUD und Zielpfeil gehören nicht in eine Zwischensequenz
	_hud = welt.get_node_or_null("HUD")   # CanvasLayer oder Control — beide haben visible
	_marker = welt.get_node_or_null("Zielmarker") as Node3D
	if _hud:
		_hud.set("visible", false)
	if _marker:
		_marker.visible = false
		_marker.process_mode = Node.PROCESS_MODE_DISABLED
	_kamera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_weiter()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		var welt := get_parent()
		if welt.has_method("net_kino_ueberspringen"):
			welt.net_kino_ueberspringen.rpc_id(1)
		else:
			beenden()

func _weiter() -> void:
	_schritt += 1
	_t = 0.0
	if _schritt >= SCHRITTE.size():
		beenden()
		return
	var s: Dictionary = SCHRITTE[_schritt]
	_sprecher.text = _wort(str(s.sprecher))
	_text.text = _wort(str(s.text))
	_hinweis.text = String(TranslationServer.translate("INTRO_UEBERSPRINGEN"))
	if s.get("chef_geht", false) and _chef and _chef.has_method("losgehen"):
		_chef.losgehen()

## Text in der passenden Anrede (Solo „du", Koop „ihr")
func _wort(key: String) -> String:
	return String(TranslationServer.translate(key + ("_IHR" if _mehrere else "_DU")))

func _process(delta: float) -> void:
	if not aktiv or _schritt < 0 or _schritt >= SCHRITTE.size():
		return
	var s: Dictionary = SCHRITTE[_schritt]
	_t += delta
	var t := clampf(_t / float(s.dauer), 0.0, 1.0)
	# weich anfahren und ausrollen
	var w := t * t * (3.0 - 2.0 * t)
	_kamera.global_position = (s.von as Vector3).lerp(s.nach as Vector3, w)
	var ziel: Vector3 = _blickpunkt(s.blick)
	_kamera.look_at(ziel, Vector3.UP)
	# Balken und Text fahren am Anfang ein, am Ende wieder aus
	var rand := minf(1.0, minf(_t, maxf(0.0, float(s.dauer) - _t)) * 4.0)
	_balken_oben.modulate.a = 1.0
	_balken_unten.modulate.a = 1.0
	_sprecher.modulate.a = rand
	_text.modulate.a = rand
	if _t >= float(s.dauer):
		_weiter()

func _blickpunkt(blick) -> Vector3:
	if blick is Vector3:
		return blick
	if str(blick) == "chef" and _chef and is_instance_valid(_chef):
		return _chef.global_position + Vector3(0, 1.5, 0)
	if _spieler and is_instance_valid(_spieler):
		return _spieler.global_position + Vector3(0, 1.5, 0)
	return Vector3(0, 1.5, 84)

func beenden() -> void:
	if not aktiv:
		return
	aktiv = false
	visible = false
	if _hud:
		_hud.set("visible", true)
	if _marker:
		_marker.process_mode = Node.PROCESS_MODE_INHERIT
	_kamera.current = false
	if _chef and _chef.has_method("losgehen"):
		_chef.losgehen()
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
