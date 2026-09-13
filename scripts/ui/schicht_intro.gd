extends Control
## Kurze Einführung „So läuft die Schicht": wer zapft, wer serviert, Küche,
## Lager, Putzen — mit den echten Tasten, die eigene Abteilung hervorgehoben.
## Erscheint beim ersten Schichtbeginn einmal pro Spielstart (auch für Spieler,
## die mitten in der Schicht dazukommen). Blockiert nichts: schließt mit Enter
## oder nach ANZEIGE_ZEIT von selbst. Aufbau: scenes/ui/schicht_intro.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
const ANZEIGE_ZEIT := 40.0
const GOLD := Color(1, 0.84, 0.35)
const NORMAL := Color(0.93, 0.92, 0.97)
## Zeile in der Szene → Übersetzungsschlüssel und zuständige Abteilung
const ZEILEN := {
	"Zapfen": ["INTRO_ZAPFEN", "service"],
	"Servieren": ["INTRO_SERVIEREN", "service"],
	"Kueche": ["INTRO_KUECHE", "kueche"],
	"Lager": ["INTRO_LAGER", "lager"],
	"Putzen": ["INTRO_PUTZEN", "sauberkeit"],
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
	var abt := ""
	if _gm and _gm.has_method("_abteilung_von") and not Net.solo:
		abt = str(_gm._abteilung_von(multiplayer.get_unique_id()))
	for zeile: String in ZEILEN:
		var l := get_node("%" + zeile) as Label
		var eigene: bool = abt != "" and ZEILEN[zeile][1] == abt
		l.text = Texte.mit_tasten(ZEILEN[zeile][0]) + ("   " + tr("INTRO_DEINE") if eigene else "")
		l.add_theme_color_override("font_color", GOLD if eigene else NORMAL)
	%Schliessen.text = Texte.mit_tasten("INTRO_CLOSE")
