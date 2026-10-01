extends Control
## Auswahl der Welt für ein Koop-Spiel: drei Plätze, je „Weiterspielen" oder „Neu
## beginnen". Ein belegter Platz wird erst nach einer zweiten Bestätigung am
## selben Knopf überschrieben. Die Schwierigkeit gilt für neue Spiele.
## Der Host öffnet sie im Steam-Warteraum; gespielt wird nach seiner Wahl.
## Aufbau: scenes/ui/spielstandwahl.tscn.

const Texte := preload("res://scripts/ui/texte.gd")

## platz: 1..Net.SLOTS, neu: Welt neu beginnen (alter Stand wird überschrieben)
signal gewaehlt(platz: int, neu: bool, schwierigkeit: int)
signal geschlossen

@export var stil_platz: StyleBox
@export var stil_aktuell: StyleBox
@export var stil_gefahr: StyleBox
@export var stil_neu: StyleBox

var _aktuell_platz := 0
var _ueberschreiben_platz := 0

func _ready() -> void:
	for i in Net.SLOTS:
		var zeile := %Plaetze.get_child(i)
		(zeile.get_node("Zeile/Laden") as Button).pressed.connect(_laden.bind(i + 1))
		(zeile.get_node("Zeile/Neu") as Button).pressed.connect(_neu.bind(i + 1))
	%Zu.pressed.connect(schliessen)

## platz: der Platz, der gerade gewählt ist (wird hervorgehoben), 0 = keiner
func zeigen(platz: int, schwierigkeit: int) -> void:
	_aktuell_platz = platz
	_ueberschreiben_platz = 0
	var wahl: OptionButton = %Schwierigkeit
	wahl.clear()
	for i in 3:
		wahl.add_item(tr("DIFF_%d" % i), i)
	wahl.select(clampi(schwierigkeit, 0, 2))
	_anzeigen()
	visible = true
	((%Plaetze.get_child(maxi(platz, 1) - 1) as Control).get_node("Zeile/Laden") as Button).grab_focus.call_deferred()

func schliessen() -> void:
	if not visible:
		return
	visible = false
	geschlossen.emit()

func _anzeigen() -> void:
	for i in Net.SLOTS:
		var platz := i + 1
		var zeile := %Plaetze.get_child(i) as PanelContainer
		var info := Net.speicherstand_info(platz)
		var text: Label = zeile.get_node("Zeile/Info")
		var laden: Button = zeile.get_node("Zeile/Laden")
		var neu: Button = zeile.get_node("Zeile/Neu")
		zeile.add_theme_stylebox_override("panel", stil_aktuell if platz == _aktuell_platz else stil_platz)
		if info.is_empty():
			text.text = tr("SLOT_EMPTY") % platz
			laden.disabled = true
		elif info.zu_neu:
			text.text = tr("SLOT_TOO_NEW") % platz
			laden.disabled = true
		else:
			text.text = tr("SLOT_INFO") % [platz, info.day, Texte.euro(info.money), Net.zeit_text(info.saved_at)]
			laden.disabled = false
		var ueberschreiben := platz == _ueberschreiben_platz
		neu.text = tr("SW_WORLD_OVERWRITE") if ueberschreiben else tr("SW_WORLD_NEW_BTN")
		neu.add_theme_stylebox_override("normal", stil_gefahr if ueberschreiben else stil_neu)

func _laden(platz: int) -> void:
	gewaehlt.emit(platz, false, %Schwierigkeit.get_selected_id())
	schliessen()

func _neu(platz: int) -> void:
	# Leerer Platz: sofort. Belegter Platz: erst ein zweiter Druck überschreibt.
	if not Net.speicherstand_info(platz).is_empty() and _ueberschreiben_platz != platz:
		_ueberschreiben_platz = platz
		_anzeigen()
		return
	gewaehlt.emit(platz, true, %Schwierigkeit.get_selected_id())
	schliessen()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		schliessen()
