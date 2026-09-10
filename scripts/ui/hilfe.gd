extends CanvasLayer
## Hilfeseite (F1): Steuerung und Spielablauf auf einen Blick.
## Aufbau liegt in scenes/ui/hilfe.tscn. Nur die Tastenliste entsteht hier im
## Code, aus Einstellungen.STANDARD_TASTEN — so steht jede umbelegte Taste
## richtig da, genau wie im Einstellungsmenü.
## Liegt in main.tscn hinter Spielern und Pausemenü, bekommt F1 und ESC also zuerst.

const Texte := preload("res://scripts/ui/texte.gd")

@onready var _liste: GridContainer = %TastenListe

var _war_pausiert := false
var _maus_vorher := Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	visible = false
	%Schliessen.pressed.connect(schliessen)
	Einstellungen.geaendert.connect(_neu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("help") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if visible:
			schliessen()
		else:
			oeffnen()
	elif visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		schliessen()

## Im Solo steht die Zeit still, solange man liest. Was vorher war (Pausemenü
## offen, Maus frei im Wiesenbüro), wird beim Schließen wiederhergestellt.
func oeffnen() -> void:
	if visible:
		return
	_neu()
	visible = true
	_war_pausiert = get_tree().paused
	get_tree().paused = Net.solo or _war_pausiert
	_maus_vorher = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%Schliessen.grab_focus()

func schliessen() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = _war_pausiert
	Input.mouse_mode = _maus_vorher

func ist_offen() -> bool:
	return visible

func _neu() -> void:
	%Schliessen.text = Texte.mit_tasten("HELP_CLOSE")
	for c in _liste.get_children():
		_liste.remove_child(c)
		c.queue_free()
	_zeile(tr("ACTION_LOOK"), tr("HELP_MOUSE"))
	for aktion: String in Einstellungen.STANDARD_TASTEN:
		_zeile(tr("ACTION_" + aktion.to_upper()), Einstellungen.tasten_name(aktion))
	_zeile(tr("ACTION_PAUSE"), "Esc")

func _zeile(aktion: String, taste: String) -> void:
	var name_label := Label.new()
	name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	name_label.text = aktion
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tasten_label := Label.new()
	tasten_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	tasten_label.text = taste
	tasten_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tasten_label.add_theme_color_override("font_color", Color(1, 0.839, 0.349))
	_liste.add_child(name_label)
	_liste.add_child(tasten_label)
