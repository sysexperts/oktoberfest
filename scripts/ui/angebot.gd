extends PanelContainer
## Eine Zeile im Wiesenbüro: Titel, Beschreibung, bis zu drei Knöpfe und —
## wenn etwas gesperrt ist — der Grund in Orange. Aufbau: scenes/ui/angebot.tscn.

signal gedrueckt(index: int)

@export var stil_normal: StyleBox
@export var stil_hervor: StyleBox

var _knoepfe: Array[Button] = []
var _hervorgehoben := false
var _puls: Tween

func _ready() -> void:
	_knoepfe = [%Knopf1, %Knopf2, %Knopf3]
	for i in _knoepfe.size():
		_knoepfe[i].pressed.connect(gedrueckt.emit.bind(i))

func setze(titel: String, info: String) -> void:
	%Titel.text = titel
	%Info.text = info
	%Info.visible = info != ""

## Knopf i (0..2) zeigen. gesperrt = ausgegraut, der Grund steht per grund().
func knopf(i: int, text: String, gesperrt := false) -> void:
	var k := _knoepfe[i]
	k.visible = true
	k.text = text
	k.disabled = gesperrt

func knopf_node(i: int) -> Button:
	return _knoepfe[i]

func grund(text: String) -> void:
	%Grund.text = text
	%Grund.visible = text != ""

func grund_text() -> String:
	return %Grund.text if %Grund.visible else ""

## Goldener Rahmen mit sanftem Pulsieren — fürs Tutorial.
func hervorheben(an: bool) -> void:
	if an == _hervorgehoben:
		return
	_hervorgehoben = an
	add_theme_stylebox_override("panel", stil_hervor if an else stil_normal)
	if _puls:
		_puls.kill()
		_puls = null
	modulate = Color.WHITE
	if an:
		_puls = create_tween().set_loops()
		_puls.tween_property(self, "modulate", Color(1.18, 1.12, 0.92), 0.6)
		_puls.tween_property(self, "modulate", Color.WHITE, 0.6)

func ist_hervorgehoben() -> bool:
	return _hervorgehoben
