extends CanvasLayer
## Gespräch mit einem NPC: Name und Text unten im Pergamentkasten, Linksklick
## oder E/Enter zur nächsten Zeile. Hält den Spieler wie ein Minispiel fest.
## Läuft nur beim Spieler, der redet. Aufbau: scenes/ui/dialog.tscn.

@onready var _kasten: Control = %Kasten
@onready var _sprecher: Label = %Sprecher
@onready var _text: Label = %Text
@onready var _hinweis: Label = %Hinweis

var aktiv := false
var _zeilen: Array[String] = []
var _nr := -1
var _t := 0.0
var _spieler: Node = null
var _fertig := Callable()

func _ready() -> void:
	add_to_group("dialog")
	visible = false

## player.gd hält das Gespräch wie ein Minispiel (blockiert Bewegung)
func laeuft() -> bool:
	return aktiv

## zeilen: fertig übersetzte Texte. fertig wird nach der letzten Zeile gerufen.
func zeigen(sprecher: String, zeilen: Array[String], fertig := Callable()) -> void:
	var welt := get_parent()
	_spieler = welt._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in welt else null
	if aktiv or _spieler == null or zeilen.is_empty():
		return
	aktiv = true
	visible = true
	_zeilen = zeilen
	_fertig = fertig
	_sprecher.text = sprecher
	_spieler.minispiel = self
	_nr = -1
	_weiter()

func eingabe(event: InputEvent) -> void:
	# kurz nach dem Öffnen nichts annehmen — sonst schluckt das E vom Ansprechen die erste Zeile
	if _t < 0.25:
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
	_hinweis.text = String(TranslationServer.translate("DIALOG_WEITER" if _nr < _zeilen.size() - 1 else "DIALOG_ENDE"))

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
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()
	if _fertig.is_valid():
		_fertig.call()
