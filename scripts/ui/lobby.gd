extends Control
## Lobby beim Einstieg in ein Mehrspieler-Spiel: Name, Schalfarbe und eine kurze
## Anleitung, damit eine neue Gruppe gleich weiß, was zu tun ist. Ein Fenster
## über dem laufenden Spiel — funktioniert so auch auf dem Dauerserver und für
## Spieler, die später dazukommen.
## Aufbau: scenes/ui/lobby.tscn. Gespeichert und an alle verteilt wird die Wahl
## vom GameManager (net_lobby_setzen → _spieler_info).

const Texte := preload("res://scripts/ui/texte.gd")
const Figuren := preload("res://scripts/figuren.gd")
## Porträts der wählbaren Figuren (tools/render_avatare.tscn), Nr. = Platz in Figuren.ALLE
const AVATAR := "res://assets/ui/avatare/figur_%d.png"
## Gleiche Farben wie player.gd COSTUME_COLORS (Schal)
const FARBEN := [Color(0.85, 0.2, 0.2), Color(0.2, 0.45, 0.85), Color(0.2, 0.7, 0.3),
	Color(0.7, 0.3, 0.8), Color(0.95, 0.85, 0.2), Color(0.95, 0.95, 0.95)]

var _gm: Node
var _info := {}
var _farbe := 0
var _figur := 0

func _ready() -> void:
	visible = false
	for i in FARBEN.size():
		var knopf := %Farben.get_child(i) as Button
		(knopf.get_node("Flaeche") as ColorRect).color = FARBEN[i]
		knopf.pressed.connect(_farbe_waehlen.bind(i))
	%Los.pressed.connect(_los)
	%FigurWaehlen.pressed.connect(_wahl_oeffnen)
	%Zu.pressed.connect(_wahl_schliessen)
	for i in Figuren.ALLE.size():
		(%Raster.get_child(i) as Button).pressed.connect(_figur_waehlen.bind(i))
	%Name.text_submitted.connect(func(_t: String) -> void: _los())
	# Am Steam Deck gibt es keine Tastatur — Steam blendet seine eigene ein,
	# sobald das Feld den Fokus bekommt. Ohne Steam oder mit Maus passiert nichts.
	%Name.focus_entered.connect(func() -> void: SteamDienst.tastatur_zeigen(%Name))
	Einstellungen.geaendert.connect(_neu)

func einrichten(gm: Node) -> void:
	_gm = gm

func oeffnen() -> void:
	var ich := multiplayer.get_unique_id()
	var eigen: Dictionary = _info.get(ich, {})
	_farbe = int(eigen.get("farbe", absi(ich) % FARBEN.size()))
	_figur = int(eigen.get("figur", _erste_freie_figur()))
	%Wahl.visible = false
	var name_vorher := str(eigen.get("name", ""))
	if name_vorher == "":
		name_vorher = Net.player_name if Net.player_name != "Spieler" else ""
	%Name.text = name_vorher
	visible = true
	_neu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%Name.grab_focus.call_deferred()

func schliessen() -> void:
	visible = false
	%Wahl.visible = false
	%Name.release_focus()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func ist_offen() -> bool:
	return visible

## Neuer Stand aller Spieler vom Server
func aktualisieren(info: Dictionary) -> void:
	_info = info
	if visible:
		_neu()

func _neu() -> void:
	for i in FARBEN.size():
		var knopf := %Farben.get_child(i) as Button
		# Gewählte Farbe: Fläche kleiner, der helle Knopfrand darum ist die Markierung
		var flaeche := knopf.get_node("Flaeche") as ColorRect
		var rand := 9.0 if i == _farbe else 4.0
		flaeche.offset_left = rand
		flaeche.offset_top = rand
		flaeche.offset_right = -rand
		flaeche.offset_bottom = -rand
		knopf.button_pressed = i == _farbe
		knopf.toggle_mode = true
	_figuren_zeigen()
	# Wer schon dabei ist — ohne die eigene Zeile
	var ich := multiplayer.get_unique_id()
	var andere: Array[String] = []
	for peer in _info.keys():
		if int(peer) == ich:
			continue
		var n := str((_info[peer] as Dictionary).get("name", ""))
		if n != "":
			andere.append(n)
	%Mitspieler.text = tr("LOBBY_OTHERS") % ", ".join(andere) if not andere.is_empty() else tr("LOBBY_ALONE")
	%Anleitung.text = Texte.mit_tasten("LOBBY_HOWTO")

## Figuren, die andere Spieler schon haben: Nr → true
func _belegt() -> Dictionary:
	var ich := multiplayer.get_unique_id()
	var belegt := {}
	for peer in _info.keys():
		if int(peer) != ich:
			belegt[int((_info[peer] as Dictionary).get("figur", -1))] = true
	return belegt

## Neue Spieler bekommen die erste Figur, die keiner hat
func _erste_freie_figur() -> int:
	var belegt := _belegt()
	for i in Figuren.ALLE.size():
		if not belegt.has(i):
			return i
	return 0

func _figuren_zeigen() -> void:
	%FigurAvatar.texture = load(AVATAR % _figur)
	%FigurName.text = tr("KOOP_FIG_%d" % _figur)
	var belegt := _belegt()
	for i in Figuren.ALLE.size():
		var knopf := %Raster.get_child(i) as Button
		knopf.button_pressed = i == _figur
		knopf.disabled = belegt.has(i) and i != _figur
		knopf.modulate = Color(1, 1, 1, 0.4) if knopf.disabled else Color.WHITE

func _wahl_oeffnen() -> void:
	%Wahl.visible = true
	(%Raster.get_child(_figur) as Button).grab_focus.call_deferred()

func _wahl_schliessen() -> void:
	%Wahl.visible = false
	%FigurWaehlen.grab_focus.call_deferred()

func _figur_waehlen(i: int) -> void:
	_figur = i
	_neu()
	_senden()

func _farbe_waehlen(i: int) -> void:
	_farbe = i
	_neu()
	_senden()

func _senden() -> void:
	if _gm:
		_gm.net_lobby_setzen.rpc_id(1, (%Name.text as String).strip_edges(), _farbe, _figur)

func _los() -> void:
	_senden()
	var n := (%Name.text as String).strip_edges()
	if n != "":
		Net.player_name = n
	schliessen()
