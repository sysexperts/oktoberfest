extends Control
## Auswahl der Spielerfigur: Raster mit den Porträts aller wählbaren Figuren
## (Figuren.ALLE, Bilder aus tools/render_avatare.tscn). Figuren, die andere
## Spieler schon haben, sind ausgegraut.
## Aufbau: scenes/ui/figurenwahl.tscn.

const Figuren := preload("res://scripts/figuren.gd")

## Der Spieler hat eine Figur angeklickt (Nr. in Figuren.ALLE).
signal gewaehlt(nr: int)
signal geschlossen

var _aktuell := 0

func _ready() -> void:
	for i in Figuren.ALLE.size():
		(%Raster.get_child(i) as Button).pressed.connect(_waehlen.bind(i))
	%Zu.pressed.connect(schliessen)

## belegt: Nr → true für Figuren anderer Spieler
func zeigen(aktuell: int, belegt: Dictionary) -> void:
	_aktuell = aktuell
	_anzeigen(belegt)
	visible = true
	(%Raster.get_child(clampi(aktuell, 0, Figuren.ALLE.size() - 1)) as Button).grab_focus.call_deferred()

func schliessen() -> void:
	if not visible:
		return
	visible = false
	geschlossen.emit()

func _anzeigen(belegt: Dictionary) -> void:
	for i in Figuren.ALLE.size():
		var knopf := %Raster.get_child(i) as Button
		knopf.button_pressed = i == _aktuell
		knopf.disabled = belegt.has(i) and i != _aktuell
		knopf.modulate = Color(1, 1, 1, 0.4) if knopf.disabled else Color.WHITE

func _waehlen(i: int) -> void:
	_aktuell = i
	for k in Figuren.ALLE.size():
		(%Raster.get_child(k) as Button).button_pressed = k == i
	gewaehlt.emit(i)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		schliessen()
