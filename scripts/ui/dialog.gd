extends CanvasLayer
## Gespräch mit einem NPC: Name und Text unten im Pergamentkasten, Linksklick
## oder E/Enter zur nächsten Zeile. Hält den Spieler wie ein Minispiel fest.
## Läuft nur beim Spieler, der redet. Aufbau: scenes/ui/dialog.tscn.
##
## Mit `auswahl` (zwei fertige Texte) stellt die letzte Zeile eine Frage: Knöpfe
## Ja/Nein (oder Taste 1/2), `fertig` bekommt dann 0 oder 1.

@onready var _kasten: Control = %Kasten
@onready var _sprecher: Label = %Sprecher
@onready var _text: Label = %Text
@onready var _hinweis: Label = %Hinweis
@onready var _auswahl: Control = %Auswahl
@onready var _ja: Button = %Ja
@onready var _nein: Button = %Nein

var aktiv := false
var _zeilen: Array[String] = []
var _nr := -1
var _t := 0.0
var _spieler: Node = null
var _fertig := Callable()
var _wahl: Array[String] = []

func _ready() -> void:
	add_to_group("dialog")
	visible = false
	_ja.pressed.connect(_waehlen.bind(0))
	_nein.pressed.connect(_waehlen.bind(1))

## player.gd hält das Gespräch wie ein Minispiel (blockiert Bewegung)
func laeuft() -> bool:
	return aktiv

## zeilen: fertig übersetzte Texte. fertig wird nach der letzten Zeile gerufen
## (mit Auswahl: fertig.call(0 oder 1)).
func zeigen(sprecher: String, zeilen: Array[String], fertig := Callable(), auswahl: Array[String] = []) -> void:
	var welt := get_parent()
	_spieler = welt._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in welt else null
	if aktiv or _spieler == null or zeilen.is_empty():
		return
	aktiv = true
	visible = true
	_zeilen = zeilen
	_fertig = fertig
	_wahl = auswahl
	_sprecher.text = sprecher
	_spieler.minispiel = self
	_nr = -1
	_weiter()

func _frage_offen() -> bool:
	return not _wahl.is_empty() and _nr == _zeilen.size() - 1

func eingabe(event: InputEvent) -> void:
	# kurz nach dem Öffnen nichts annehmen — sonst schluckt das E vom Ansprechen die erste Zeile
	if _t < 0.25:
		return
	if _frage_offen():
		var k := event as InputEventKey
		if k and k.pressed and not k.echo:
			if k.keycode == KEY_1 or k.keycode == KEY_J or k.keycode == KEY_Y:
				_waehlen(0)
			elif k.keycode == KEY_2 or k.keycode == KEY_N:
				_waehlen(1)
		return
	var mb := event as InputEventMouseButton
	if (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT) or event.is_action_pressed("ui_accept") \
			or event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		_weiter()

func _weiter() -> void:
	_nr += 1
	_t = 0.0
	if _nr >= _zeilen.size():
		beenden()
		return
	_text.text = _zeilen[_nr]
	var frage := _frage_offen()
	_auswahl.visible = frage
	_hinweis.visible = not frage
	if frage:
		_ja.text = "1  " + _wahl[0]
		_nein.text = "2  " + _wahl[1]
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_ja.grab_focus()
	else:
		_hinweis.text = String(TranslationServer.translate("DIALOG_WEITER" if _nr < _zeilen.size() - 1 else "DIALOG_ENDE"))

func _waehlen(i: int) -> void:
	if not aktiv or not _frage_offen():
		return
	var f := _fertig
	_fertig = Callable()
	beenden()
	if f.is_valid():
		f.call(i)

func _process(delta: float) -> void:
	if not aktiv:
		return
	_t += delta
	_text.visible_ratio = minf(1.0, _t * 60.0 / maxf(1.0, _text.text.length()))
	_kasten.modulate.a = minf(1.0, (_t + (0.0 if _nr == 0 else 1.0)) * 5.0)

func beenden() -> void:
	if not aktiv:
		return
	aktiv = false
	visible = false
	_auswahl.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()
	if _fertig.is_valid() and _wahl.is_empty():
		_fertig.call()
