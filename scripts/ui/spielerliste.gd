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
@export var ereignis: PackedScene

const Meldung := preload("res://scripts/ui/meldung.gd")

var _gm: Node
var _t := 0.0
var _ereignis_stand := ""
var _spieler_zahl := 0

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
	_spieler_zahl = peers.size()
	%Titel.text = tr("SPIELERLISTE_TITEL") % peers.size()
	_ereignisse_zeigen()

## Die Meldungen des heutigen Tages zum Nachlesen (neueste oben), in der Farbe ihrer Art
func _ereignisse_zeigen() -> void:
	var hud := get_parent()
	var alle: Array = hud.verlauf if "verlauf" in hud else []
	# Nur der heutige Tag; nach dem Schlafen beginnt die Liste neu
	var liste: Array = alle.filter(func(e: Dictionary) -> bool: return int(e.get("tag", -1)) == int(hud._day))
	# Nur neu bauen, wenn sich etwas geändert hat (sonst flackert das Kürzen unten)
	var stand := "%d|%d|%d" % [liste.size(), get_viewport_rect().size.y, _spieler_zahl]
	if stand == _ereignis_stand and %Ereignisse.get_child_count() > 0:
		return
	_ereignis_stand = stand
	for k in %Ereignisse.get_children():
		k.queue_free()
	%Ereignisse.visible = not liste.is_empty()
	for i in range(liste.size() - 1, -1, -1):
		var e: Dictionary = liste[i]
		var z := ereignis.instantiate()
		%Ereignisse.add_child(z)
		var farbe: Color = Meldung.FARBEN[clampi(int(e.get("art", 0)), 0, Meldung.FARBEN.size() - 1)]
		(z.get_node("%Strich") as ColorRect).color = Color(farbe.r, farbe.g, farbe.b, 0.9)
		(z.get_node("%Zeit") as Label).text = str(e.get("zeit", ""))
		(z.get_node("%Text") as RichTextLabel).text = Meldung.auszeichnen(str(e.get("text", "")), farbe)
	_ereignisse_kuerzen()

## Die Liste ist zu lang für den Bildschirm: die ältesten Einträge (unten) fallen weg,
## damit alles, was sichtbar ist, auch ganz zu sehen ist.
func _ereignisse_kuerzen() -> void:
	var panel := %Titel.get_parent().get_parent() as Control
	var grenze := get_viewport_rect().size.y - 70.0 - 30.0
	for i in 60:
		await get_tree().process_frame
		if not is_instance_valid(panel) or %Ereignisse.get_child_count() <= 1 or panel.size.y <= grenze:
			return
		var letzter := %Ereignisse.get_child(%Ereignisse.get_child_count() - 1)
		%Ereignisse.remove_child(letzter)
		letzter.queue_free()
