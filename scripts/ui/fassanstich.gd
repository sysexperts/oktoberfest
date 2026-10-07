extends CanvasLayer
## Fassanstich am Festtag: ein Zeiger pendelt über die Leiste, die grüne Mitte ist der Treffer. Drei Schläge
## (Linksklick oder E), je näher an der Mitte, desto besser. Der Durchschnitt (0 bis 10) geht an den Server
## (GameManager.net_fassanstich). Hält den Spieler wie ein Minispiel fest. Aufbau: scenes/ui/fassanstich.tscn.

const SCHLAEGE := 3

var aktiv := false
var _spieler: Node = null
var _t := 0.0
var _zeiger := 0.0
var _uebrig := SCHLAEGE
var _summe := 0.0
var _pause := 0.0

@onready var _leiste: ProgressBar = %Leiste
@onready var _info: Label = %Info

func _ready() -> void:
	add_to_group("fassanstich_ui")
	visible = false
	%Schliessen.pressed.connect(beenden)

func laeuft() -> bool:
	return aktiv

func zeigen(spieler: Node) -> void:
	if aktiv:
		return
	_spieler = spieler
	aktiv = true
	visible = true
	_t = 0.0
	_uebrig = SCHLAEGE
	_summe = 0.0
	_pause = 0.0
	spieler.minispiel = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_info_neu()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _t > 0.25:
		beenden()
		return
	var mb := event as InputEventMouseButton
	if _t > 0.25 and _pause <= 0.0 and ((mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT) or event.is_action_pressed("interact")):
		_schlagen()

func _process(delta: float) -> void:
	if not aktiv:
		return
	_t += delta
	_pause = maxf(0.0, _pause - delta)
	# Pendelt immer schneller: Tempo wächst mit jedem Schlag
	var tempo := 0.8 + 0.5 * float(SCHLAEGE - _uebrig)
	_zeiger = 0.5 - 0.5 * cos(TAU * tempo * _t * 0.5)
	_leiste.value = _zeiger

func _schlagen() -> void:
	# Mitte = 0,5: 10 Punkte, am Rand 0
	var genauigkeit := 1.0 - minf(1.0, absf(_zeiger - 0.5) * 2.0)
	_summe += genauigkeit * 10.0
	_uebrig -= 1
	_pause = 0.4
	_info_neu()
	if _uebrig <= 0:
		var punkte := roundi(_summe / float(SCHLAEGE))
		var welt := get_parent()
		welt.net_fassanstich.rpc_id(1, punkte)
		beenden()

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("ANSTICH_INFO")) % [_uebrig, roundi(_summe / float(maxi(1, SCHLAEGE - _uebrig)))] if _uebrig < SCHLAEGE else String(TranslationServer.translate("ANSTICH_START"))

func beenden() -> void:
	if not aktiv:
		return
	aktiv = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()
