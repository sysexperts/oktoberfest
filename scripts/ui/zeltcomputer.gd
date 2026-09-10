extends Control
## Zelt-Computer: Rollen im Koop wählen, Bilanz lesen, Zelt früher schließen.
## Aufbau liegt in scenes/ui/zeltcomputer.tscn.

const Texte := preload("res://scripts/ui/texte.gd")

var _gm: Node
var _z := {}
var _bilanz := {}

func _ready() -> void:
	visible = false
	# Rollen wie GameManager.ROLE_KITCHEN / ROLE_CLEAN / ROLE_WAITER
	%Kueche.pressed.connect(_rolle.bind(1))
	%Putzen.pressed.connect(_rolle.bind(2))
	%Bedienen.pressed.connect(_rolle.bind(3))
	%Keine.pressed.connect(_rolle.bind(0))
	%ZeltSchliessen.pressed.connect(func() -> void:
		if _gm:
			_gm.net_close_tent.rpc_id(1))
	%Schliessen.pressed.connect(schliessen)
	Einstellungen.geaendert.connect(_neu)

func einrichten(gm: Node) -> void:
	_gm = gm

func setze_zustand(z: Dictionary) -> void:
	_z = z
	_neu()

func setze_bilanz(b: Dictionary) -> void:
	_bilanz = b
	_neu()

func oeffnen() -> void:
	visible = true
	_neu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func schliessen() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func ist_offen() -> bool:
	return visible

func _neu() -> void:
	%Status.text = Texte.buero_status(_z)
	%RollenText.text = Texte.rollen(_z.get("roles", {}))
	# Früher schließen geht nur, solange das Zelt offen ist
	%ZeltSchliessen.disabled = not bool(_z.get("shift", false))
	%BilanzText.text = Texte.bilanz(_bilanz)

func _rolle(rolle: int) -> void:
	if _gm:
		_gm.net_set_role.rpc_id(1, rolle)
