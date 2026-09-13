extends Control
## Abstimmung „Nächster Tag?" — erscheint bei allen Spielern, sobald jemand am
## Wohnwagen schlafen will. Die Mehrheit entscheidet (GameManager.abstimmung_ergebnis).
## Aufbau: scenes/ui/abstimmung.tscn. Zahlen und Restzeit kommen vom Server.

var _gm: Node
var _abgestimmt := false

func _ready() -> void:
	visible = false
	%Ja.pressed.connect(_stimme.bind(true))
	%Nein.pressed.connect(_stimme.bind(false))

func einrichten(gm: Node) -> void:
	_gm = gm

## Stand vom Server: aktiv = läuft noch; ja/nein = Stimmen; gesamt = Spieler; rest = Sekunden.
func zeige(aktiv: bool, starter: String, ja: int, nein: int, gesamt: int, rest: int, schon_gestimmt: bool) -> void:
	if not aktiv:
		if visible:
			visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_abgestimmt = false
		return
	if not visible:
		visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_abgestimmt = schon_gestimmt
	%Text.text = tr("VOTE_TEXT") % starter
	%Stand.text = tr("VOTE_COUNT") % [ja, nein, gesamt, rest]
	%Balken.max_value = maxi(1, gesamt)
	%Balken.value = ja
	%Ja.disabled = _abgestimmt
	%Nein.disabled = _abgestimmt
	%Warten.visible = _abgestimmt

func ist_offen() -> bool:
	return visible

## Fenster schließen ohne abzustimmen (Esc) — die Abstimmung läuft weiter.
func schliessen() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _stimme(ja: bool) -> void:
	if _gm == null or _abgestimmt:
		return
	_abgestimmt = true
	%Ja.disabled = true
	%Nein.disabled = true
	%Warten.visible = true
	_gm.net_abstimmen.rpc_id(1, ja)
