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

## Ein Schritt: Dauer (Höchstzeit, Linksklick geht früher weiter), Kamera von → nach,
## Blickziel ("chef", "spieler" oder Punkt), Sprecher und Textschlüssel (ohne _DU/_IHR).
## geste: wer dazu gestikuliert ("spieler", "jubel" = Spieler jubelt, "chef").
const SCHRITTE := [
	{"dauer": 5.0, "von": Vector3(0, 5.2, 101), "nach": Vector3(0, 2.6, 92), "blick": Vector3(0, 1.7, 84.5),
		"sprecher": "INTRO_NAME_FREUND", "text": "INTRO_1"},
	{"dauer": 4.5, "von": Vector3(4.2, 1.9, 80.5), "nach": Vector3(3.4, 1.8, 81.8), "blick": "spieler",
		"sprecher": "INTRO_NAME_SPIELER", "text": "INTRO_2", "geste": "jubel"},
	{"dauer": 6.0, "von": Vector3(4.0, 1.9, 81.5), "nach": Vector3(3.2, 1.8, 80.0), "blick": "chef",
		"sprecher": "INTRO_NAME_CHEF", "text": "INTRO_3", "geste": "chef"},
	{"dauer": 5.5, "von": Vector3(-3.8, 1.9, 81.5), "nach": Vector3(-3.0, 1.8, 80.0), "blick": "chef",
		"sprecher": "INTRO_NAME_CHEF", "text": "INTRO_4", "geste": "chef"},
	{"dauer": 4.5, "von": Vector3(-3.6, 1.9, 80.5), "nach": Vector3(-3.0, 1.8, 81.6), "blick": "spieler",
		"sprecher": "INTRO_NAME_SPIELER", "text": "INTRO_5", "geste": "spieler"},
	{"dauer": 4.5, "von": Vector3(-3.6, 1.8, 80.5), "nach": Vector3(-3.0, 1.75, 79.2), "blick": "chef",
		"sprecher": "INTRO_NAME_CHEF", "text": "INTRO_6", "geste": "chef"},
	{"dauer": 6.5, "von": Vector3(2.8, 1.9, 80.5), "nach": Vector3(2.0, 1.85, 81.6), "blick": "spieler",
		"sprecher": "INTRO_NAME_SPIELER", "text": "INTRO_7", "geste": "spieler"},
	{"dauer": 6.5, "von": Vector3(-2.6, 1.8, 80.2), "nach": Vector3(-2.0, 1.75, 79.0), "blick": "chef",
		"sprecher": "INTRO_NAME_CHEF", "text": "INTRO_8", "geste": "chef"},
	{"dauer": 4.5, "von": Vector3(2.5, 2.4, 80.0), "nach": Vector3(0.0, 8.0, 86.0), "blick": "chef",
		"sprecher": "INTRO_NAME_CHEF", "text": "INTRO_9", "chef_geht": true},
]

## Wo die Spieler während der Einleitung stehen (Reihenfolge = Spielerliste)
const PLAETZE := [Vector3(-1.8, 0.1, 84.0), Vector3(1.8, 0.1, 84.0), Vector3(-4.0, 0.1, 85.0), Vector3(4.0, 0.1, 85.0)]

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
	if _spieler.has_method("kino_zeigen"):
		_spieler.kino_zeigen(true)   # eigene Figur zeigen — sonst sieht man sich nicht
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
	if event.is_action_pressed("ui_cancel"):
		var welt := get_parent()
		if welt.has_method("net_kino_ueberspringen"):
			welt.net_kino_ueberspringen.rpc_id(1)
		else:
			beenden()
		return
	# Linksklick oder Enter: nächste Zeile
	var mb := event as InputEventMouseButton
	if (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT) or event.is_action_pressed("ui_accept"):
		_weiter()

func _weiter() -> void:
	_schritt += 1
	_t = 0.0
	if _schritt >= SCHRITTE.size():
		beenden()
		return
	var s: Dictionary = SCHRITTE[_schritt]
	_sprecher.text = _wort(str(s.sprecher))
	_text.text = _wort(str(s.text))
	_hinweis.text = String(TranslationServer.translate("INTRO_WEITER"))
	match str(s.get("geste", "")):
		"chef":
			if _chef and _chef.has_method("geste"):
				_chef.geste()
		"spieler", "jubel":
			if _spieler and _spieler.has_method("geste"):
				_spieler.geste(str(s.get("geste", "")) == "jubel")
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
		return _spieler.global_position + Vector3(0, 1.25, 0)
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
		if _spieler.has_method("kino_zeigen"):
			_spieler.kino_zeigen(false)
		_spieler.minispiel_beendet()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
