extends CanvasLayer
## Gustavs Koffer: Tarnung und Werkzeuge kaufen. Der Server prüft und bucht (GameManager.net_sab_kauf).
## Hält den Spieler wie ein Minispiel fest. Aufbau: scenes/ui/gustav_laden.tscn.

var aktiv := false
var _spieler: Node = null
var _t := 0.0

@onready var _liste: VBoxContainer = %Liste
@onready var _info: Label = %Info
@onready var _tarnung: Button = %Tarnung

func _ready() -> void:
	add_to_group("gustav_laden")
	visible = false
	for k in _liste.get_children():
		var b := k as Button
		if b:
			b.pressed.connect(_kaufen.bind(String(b.name).to_lower()))
	_tarnung.pressed.connect(_tarnung_wechseln)
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
	spieler.minispiel = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_aktualisieren()

func eingabe(event: InputEvent) -> void:
	if _t > 0.25 and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		beenden()

func beenden() -> void:
	if not aktiv:
		return
	aktiv = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()

func _welt() -> Node:
	return get_parent()

func _kaufen(id: String) -> void:
	_welt().net_sab_kauf.rpc_id(1, id)

func _tarnung_wechseln() -> void:
	_welt().net_tarnung_wechseln.rpc_id(1)

func _process(delta: float) -> void:
	if aktiv:
		_t += delta
		_aktualisieren()

func _aktualisieren() -> void:
	var welt := _welt()
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	var inv: Dictionary = z.get("sab_inv", {})
	for k in _liste.get_children():
		var b := k as Button
		if b == null:
			continue
		var id := String(b.name).to_lower()
		var preis: int = int(welt.SAB_WAREN.get(id, 0))
		b.text = "%s  ·  %d €  ·  %s" % [tr("SAB_" + id.to_upper()), preis, tr("SAB_BESITZ") % int(inv.get(id, 0))]
	var besitzt := int(z.get("tarnung_stufe", 0)) > 0
	_tarnung.visible = besitzt
	_tarnung.text = tr("SAB_TARNUNG_AN") if bool(z.get("tarnung_an", false)) else tr("SAB_TARNUNG_AUS")
	_info.text = tr("SAB_INFO") % int(z.get("kasse", Game.money))
