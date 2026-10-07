extends CanvasLayer
## Watten im Casino (Mini-Version gegen Konrads Bank): drei Karten, wer zwei Stiche holt, gewinnt den Einsatz.
## Die Bank spielt zuerst aus, der Spieler legt eine Karte dagegen, die höhere gewinnt (Gleichstand: Bank).
## Mit „Watten!“ verdoppelt der Spieler den Einsatz, die Bank kann aufgeben. Der Server mischt und rechnet
## (GameManager.net_watten), hier wird nur gezeigt. Hält den Spieler wie ein Minispiel fest.
## Aufbau: scenes/ui/watten.tscn.

const RAENGE := ["WATTEN_R0", "WATTEN_R1", "WATTEN_R2", "WATTEN_R3", "WATTEN_R4", "WATTEN_R5", "WATTEN_R6", "WATTEN_R7"]

var aktiv := false
var _spieler: Node = null
var _t := 0.0
var _daten := {}

@onready var _karten: Array[Button] = [%Karte0, %Karte1, %Karte2]

func _ready() -> void:
	add_to_group("watten_ui")
	visible = false
	for i in _karten.size():
		_karten[i].pressed.connect(_karte_gelegt.bind(i))
	%Watten.pressed.connect(func() -> void: _welt().net_watten.rpc_id(1, 2, 0))
	%Neu.pressed.connect(func() -> void: _welt().net_watten.rpc_id(1, 0, 0))
	%Schliessen.pressed.connect(beenden)

func laeuft() -> bool:
	return aktiv

func _welt() -> Node:
	return get_parent()

## Vom Spieler am Kartentisch: Fenster öffnen und eine neue Runde anfordern
func zeigen(spieler: Node) -> void:
	if aktiv:
		return
	_spieler = spieler
	aktiv = true
	visible = true
	_t = 0.0
	spieler.minispiel = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_daten = {}
	_anzeigen()
	_welt().net_watten.rpc_id(1, 0, 0)

func eingabe(event: InputEvent) -> void:
	if _t > 0.25 and event.is_action_pressed("ui_cancel"):
		beenden()

func beenden() -> void:
	if not aktiv:
		return
	aktiv = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()

func _process(delta: float) -> void:
	if aktiv:
		_t += delta

func _karte_gelegt(i: int) -> void:
	_welt().net_watten.rpc_id(1, 1, i)

## Stand vom Server (GameManager._watten_senden)
func stand_zeigen(daten: Dictionary) -> void:
	_daten = daten
	if not aktiv:
		return
	_anzeigen()

func _anzeigen() -> void:
	var d := _daten
	var vorbei := bool(d.get("vorbei", true))
	var hand: Array = d.get("hand", [])
	for i in _karten.size():
		_karten[i].visible = i < hand.size() and not vorbei
		if i < hand.size():
			_karten[i].text = tr(RAENGE[clampi(int(hand[i]), 0, 7)])
	if d.is_empty():
		%Stand.text = tr("WATTEN_WARTEN")
		%BankKarte.text = ""
	else:
		%Stand.text = tr("WATTEN_STAND") % [int(d.get("stich_spieler", 0)), int(d.get("stich_bank", 0)), int(d.get("einsatz", 0))]
		if str(d.get("ende", "")) != "":
			%Stand.text += "\n" + tr(str(d.ende)) % int(d.get("betrag", 0))
		var bank := int(d.get("bank_karte", -1))
		%BankKarte.text = (tr("WATTEN_BANK_SPIELT") % tr(RAENGE[clampi(bank, 0, 7)])) if bank >= 0 and not vorbei else str(d.get("meldung", "")) if d.has("meldung") else ""
	%Watten.visible = not vorbei and not bool(d.get("gewattet", false))
	%Neu.visible = vorbei and not d.is_empty()
