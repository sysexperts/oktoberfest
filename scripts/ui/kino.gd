extends CanvasLayer
## Einleitung: Brief von Onkel Sepp („Ich vermache dir mein Festzelt …") auf
## schwarzem Grund, danach Überblende auf die Kirmes. Der Brief schickt die
## Spieler zum Festleiter in sein Festbüro (scripts/npc_festleiter.gd), dort
## beginnt die erste Mission. Aufbau: scenes/ui/kino.tscn.
##
## Läuft einmal beim ersten Start eines neuen Spielstands. Der Server startet sie
## (game_manager.net_kino_start), danach blättert jeder Spieler selbst — Esc
## schließt den Brief nur bei sich.
##
## Texte in locale/texte.csv: BRIEF_<n>_DU für Solo, BRIEF_<n>_IHR für Koop.

const SEITEN := 3
var _seiten := SEITEN
var _praefix := "BRIEF"

## Wo die Spieler am Tor stehen (Reihenfolge = Spielerliste)
const PLAETZE := [Vector3(-1.8, 0.1, 84.0), Vector3(1.8, 0.1, 84.0), Vector3(-4.0, 0.1, 85.0), Vector3(4.0, 0.1, 85.0)]

@onready var _brief: Control = %Brief
@onready var _schwarz: ColorRect = %Abdunkeln
@onready var _titel: Label = %Titel
@onready var _text: Label = %Text
@onready var _hinweis: Label = %Hinweis

var aktiv := false
var _seite := -1
var _t := 0.0
var _spieler: Node = null
var _mehrere := false

func _ready() -> void:
	visible = false

## Läuft gerade ein Werkzeug aus tools/ (Test, Bilder)? Dann keine Einleitung —
## sie würde Eingaben blockieren. Das Kino-Werkzeug selbst will sie sehen.
static func werkzeuglauf() -> bool:
	for a in OS.get_cmdline_args():
		if a.begins_with("res://tools/") and not a.contains("kino"):
			return true
	return false

## player.gd hält den Brief wie ein Minispiel (blockiert Bewegung)
func laeuft() -> bool:
	return aktiv

func starten(mehrere: bool) -> void:
	if aktiv:
		return
	var welt := get_parent()
	_mehrere = mehrere
	_praefix = "BRIEF"
	_seiten = SEITEN
	_spieler = welt._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in welt else null
	if _spieler == null:
		return
	aktiv = true
	visible = true
	_schwarz.color.a = 1.0
	_brief.modulate.a = 1.0
	# Alle ans Kirmestor stellen (Ankunft), Blick nach Süden in die Kirmes
	var ids: Array = (welt._players_nodes as Dictionary).keys()
	ids.sort()
	var platz: int = maxi(0, ids.find(multiplayer.get_unique_id()))
	_spieler.global_position = PLAETZE[platz % PLAETZE.size()]
	(_spieler as Node3D).rotation.y = 0.0
	_spieler.minispiel = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_titel.text = String(TranslationServer.translate("BRIEF_TITEL"))
	_seite = -1
	_weiter()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		beenden()
		return
	var mb := event as InputEventMouseButton
	if (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT) or event.is_action_pressed("ui_accept"):
		_weiter()

func _weiter() -> void:
	_seite += 1
	if _seite >= _seiten:
		beenden()
		return
	_t = 0.0
	_text.text = _wort(_praefix + "_%d" % (_seite + 1))
	_hinweis.text = String(TranslationServer.translate("BRIEF_WEITER" if _seite < _seiten - 1 else ("BRIEF_ENDE" if _praefix == "BRIEF" else "BRIEF_SCHLIESSEN")))

## Text in der passenden Anrede (Solo „du", Koop „ihr")
func _wort(key: String) -> String:
	return String(TranslationServer.translate(key + ("_IHR" if _mehrere else "_DU")))

func _process(delta: float) -> void:
	if not aktiv:
		return
	# jede Seite sanft einblenden
	_t += delta
	_text.modulate.a = minf(1.0, _t * 2.5)
	_brief.scale = Vector2.ONE * lerpf(0.96, 1.0, minf(1.0, _t * 4.0))
	_brief.pivot_offset = _brief.size * 0.5

func beenden() -> void:
	if not aktiv:
		return
	aktiv = false
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Übergang: Brief ausblenden, kurz schwarz, dann wird es auf der Kirmes hell
	var tw := create_tween()
	tw.tween_property(_brief, "modulate:a", 0.0, 0.6)
	tw.tween_interval(0.7)
	tw.tween_property(_schwarz, "color:a", 0.0, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: visible = false)

## Weiterer Brief mitten im Spiel (z. B. Sepps letzter Brief nach dem Sieg
## über Huber): ohne ans Tor zu stellen, Seiten <praefix>_<n>_DU/_IHR.
func brief_zeigen(mehrere: bool, praefix: String, seiten: int, titel: String) -> void:
	var welt := get_parent()
	_spieler = welt._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in welt else null
	if aktiv or _spieler == null:
		return
	_mehrere = mehrere
	_praefix = praefix
	_seiten = seiten
	aktiv = true
	visible = true
	_schwarz.color.a = 0.75
	_brief.modulate.a = 1.0
	_spieler.minispiel = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_titel.text = String(TranslationServer.translate(titel))
	_seite = -1
	_weiter()
