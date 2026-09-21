extends Control
## Kurze Einführung „So läuft die Schicht" (dezent oben rechts unter der
## Aufgabenkarte): zapfen, servieren, Küche, Lager, Putzen — mit den echten
## Tasten.
## Erscheint beim ersten Schichtbeginn einmal pro Spielstart (auch für Spieler,
## die mitten in der Schicht dazukommen). Blockiert nichts: schließt mit Enter
## oder nach ANZEIGE_ZEIT von selbst. Aufbau: scenes/ui/schicht_intro.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
const ANZEIGE_ZEIT := 20.0
const NORMAL := Color(0.93, 0.92, 0.97)
## Zeile in der Szene → Übersetzungsschlüssel
const ZEILEN := {
	"Zapfen": "INTRO_ZAPFEN",
	"Servieren": "INTRO_SERVIEREN",
	"Kueche": "INTRO_KUECHE",
	"Lager": "INTRO_LAGER",
	"Putzen": "INTRO_PUTZEN",
}

## Einmal pro Spielstart — auch nach Wiederbeitritt nicht noch einmal
static var schon_gezeigt := false

var _gm: Node

func _ready() -> void:
	visible = false
	%Zeit.timeout.connect(schliessen)
	Einstellungen.geaendert.connect(_texte)

func einrichten(gm: Node) -> void:
	_gm = gm

## Beim ersten Schichtbeginn zeigen (vom HUD aufgerufen).
func beim_schichtbeginn() -> void:
	# Im Tutorial erklärt der Wiesnchef das an der Theke — dann nicht doppelt
	if _gm and _gm.has_method("tutorial_active") and _gm.tutorial_active():
		return
	if schon_gezeigt:
		return
	schon_gezeigt = true
	zeigen()

func zeigen() -> void:
	_texte()
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)
	%Zeit.start(ANZEIGE_ZEIT)

func schliessen() -> void:
	if not visible:
		return
	%Zeit.stop()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void: visible = false)

func ist_offen() -> bool:
	return visible

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		schliessen()
		get_viewport().set_input_as_handled()

func _texte() -> void:
	for zeile: String in ZEILEN:
		var l := get_node("%" + zeile) as Label
		l.text = Texte.mit_tasten(ZEILEN[zeile])
		l.add_theme_color_override("font_color", NORMAL)
	%Schliessen.text = Texte.mit_tasten("INTRO_CLOSE")
