extends Control
## Tab halten: wer gerade im Zelt mitspielt (Porträt, Name, Schalfarbe).
## Die Daten kommen aus GameManager._spieler_info ({peer: {name, farbe, figur}}).
## Aufbau: scenes/ui/spielerliste.tscn, Zeilen: spielerliste_zeile.tscn.

const Figuren := preload("res://scripts/figuren.gd")
const AVATAR := "res://assets/ui/avatare/figur_%d.png"
## Gleiche Farben wie player.gd COSTUME_COLORS (Schal)
const FARBEN := [Color(0.85, 0.2, 0.2), Color(0.2, 0.45, 0.85), Color(0.2, 0.7, 0.3),
	Color(0.7, 0.3, 0.8), Color(0.95, 0.85, 0.2), Color(0.95, 0.95, 0.95)]

@export var zeile: PackedScene

var _gm: Node
var _t := 0.0

func einrichten(gm: Node) -> void:
	_gm = gm

func zeigen(an: bool) -> void:
	if an == visible:
		return
	visible = an
	if an:
		_aufbauen()

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _t >= 0.5:
		_t = 0.0
		_aufbauen()

func _aufbauen() -> void:
	var info: Dictionary = {}
	if _gm and "_spieler_info" in _gm:
		info = _gm._spieler_info
	var ich := multiplayer.get_unique_id()
	var peers: Array = info.keys()
	# Im Solospiel gibt es keine Lobby-Daten: nur man selbst
	if not peers.has(ich):
		peers.append(ich)
	peers.sort()
	for k in %Liste.get_children():
		k.queue_free()
	for peer in peers:
		var d: Dictionary = info.get(peer, {})
		var z := zeile.instantiate()
		%Liste.add_child(z)
		var nr := clampi(int(d.get("figur", 0)), 0, Figuren.ALLE.size() - 1)
		(z.get_node("%Avatar") as TextureRect).texture = load(AVATAR % nr)
		(z.get_node("%Farbe") as ColorRect).color = FARBEN[clampi(int(d.get("farbe", 0)), 0, FARBEN.size() - 1)]
		var name_text := str(d.get("name", ""))
		if name_text == "":
			name_text = Net.player_name
		(z.get_node("%Name") as Label).text = name_text
		(z.get_node("%Ich") as Label).visible = int(peer) == ich
	%Titel.text = tr("SPIELERLISTE_TITEL") % peers.size()
