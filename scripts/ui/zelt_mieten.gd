extends Control
## Zelt mieten: zeigt den Preis, fragt nach dem Zeltnamen und mietet erst nach
## Bestätigung. Geöffnet vom „Zu vermieten"-Schild und aus dem Festbüro.
## Aufbau: scenes/ui/zelt_mieten.tscn. Der Name wird auf dem Server geprüft
## (GameManager.zeltname_pruefen) und steht danach groß am Zelteingang und über
## der Theke (Label3D in der Gruppe "zeltname").

const Texte := preload("res://scripts/ui/texte.gd")

var _gm: Node

func _ready() -> void:
	visible = false
	%Mieten.pressed.connect(_bestaetigen)
	%Abbrechen.pressed.connect(schliessen)
	%Name.text_submitted.connect(func(_t: String) -> void: _bestaetigen())
	Einstellungen.geaendert.connect(_beschriften)

func einrichten(gm: Node) -> void:
	_gm = gm
	if _gm:
		%Name.max_length = int(_gm.ZELTNAME_MAX)

func oeffnen() -> void:
	visible = true
	%Name.text = ""
	_beschriften()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%Name.grab_focus.call_deferred()

func schliessen() -> void:
	visible = false
	%Name.release_focus()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func ist_offen() -> bool:
	return visible

func _beschriften() -> void:
	var preis := int(_gm.TENT_BOOK_COST) if _gm else 0
	%Info.text = tr("RENT_DIALOG_INFO") % Texte.euro(preis)
	%Mieten.text = tr("RENT_DIALOG_CONFIRM") % Texte.euro(preis)
	%Name.placeholder_text = tr("RENT_DIALOG_PLACEHOLDER")

func _bestaetigen() -> void:
	if _gm == null or not visible:
		return
	var zeltname: String = (%Name.text as String).strip_edges()
	if zeltname == "":
		zeltname = tr("TENT_NAME_DEFAULT")
	_gm.net_book_tent.rpc_id(1, zeltname)
	schliessen()
