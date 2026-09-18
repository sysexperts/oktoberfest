extends Node3D
## Der Wiesnchef führt durchs Tutorial. Am Anfang wartet er vor dem Wiesenbüro
## (Onkel Sepps Brief schickt die Spieler hin, scripts/ui/kino.gd). Ansprechen
## mit E öffnet das Gespräch unten im Bild (scripts/ui/dialog.gd).
##
## Rundgang: Stationen (scripts/rundgang_station.gd) unter „Rundgang" in
## kirmes.tscn. Erreicht das Tutorial den Schritt einer Station, läuft er
## schweigend dorthin und hat dann Neues zu erzählen („!" über dem Kopf, der
## Zielpfeil zeigt auf ihn). Unterwegs redet er nicht. Nach dem Tutorial erzählt
## er jeden Tag das Tagesziel und wie es um Sepps Schulden steht.
##
## Alles läuft bei jedem Spieler lokal nach dem Tutorialschritt, den der Server
## an alle schickt — so steht er überall an derselben Stelle. Nur das „Ja" im
## ersten Gespräch geht über game_manager.net_chef_zusage an den Server.

const Figuren := preload("res://scripts/figuren.gd")
const Texte := preload("res://scripts/ui/texte.gd")
const TEMPO := 1.7

## Welche Figur (Index in Figuren.ALLE)
@export var figur_nr := 2
@export var rundgang: NodePath = ^"../Rundgang"
## Texte (<Schlüssel>_DU / _IHR): erstes Gespräch am Büro, und wenn er nichts Neues hat
@export var zeilen_start: Array[String] = ["CHEF_1", "CHEF_2", "CHEF_3", "CHEF_HUBER", "CHEF_FRAGE"]
@export var zeilen_spaeter: Array[String] = ["CHEF_8"]

@onready var _ausruf: Label3D = get_node_or_null("Ausruf")

var _figur: Figur
var _weg: Array[Vector3] = []
var _punkt := 0
var _end_blick := 0.0
## Station, an der er steht oder zu der er läuft; null = Startplatz am Büro
var _station: RundgangStation = null
var _gehoert := {}
var _letzter_schritt := -1
var _alter := 0.0

func _ready() -> void:
	add_to_group("wiesnchef")
	add_to_group("interactable")
	_figur = Figuren.einsetzen(self, Figuren.ALLE[posmod(figur_nr, Figuren.ALLE.size())])
	_figur.stehen()

func ist_wiesnchef() -> bool:
	return true

func unterwegs() -> bool:
	return _punkt < _weg.size()

func ansprechbar() -> bool:
	return not unterwegs()

## Hat er etwas zu erzählen, das man noch nicht gehört hat?
func hat_neues() -> bool:
	if unterwegs():
		return false
	if _station == null:
		return _schritt() == 0
	if not _gehoert.has(_station) and not _station.zeilen.is_empty():
		return true
	return _tagesbericht_da() and _gehoert_tag != _tag()

func interact_point() -> Vector3:
	return global_position

func _welt() -> Node:
	return get_tree().current_scene

func _schritt() -> int:
	var w := _welt()
	return int(w._quest_step) if w and "_quest_step" in w else 0

func _stationen() -> Array[RundgangStation]:
	var s: Array[RundgangStation] = []
	var r := get_node_or_null(rundgang)
	if r:
		for c in r.get_children():
			if c is RundgangStation:
				s.append(c)
	s.sort_custom(func(a: RundgangStation, b: RundgangStation) -> bool: return a.schritt < b.schritt)
	return s

## Die Station für einen Tutorialschritt: die letzte mit schritt <= s
func _station_fuer(s: int) -> RundgangStation:
	var beste: RundgangStation = null
	for st in _stationen():
		if st.schritt <= s:
			beste = st
	return beste

func ansprechen() -> void:
	var dialog := get_tree().get_first_node_in_group("dialog")
	if dialog == null or not ansprechbar():
		return
	var welt := _welt()
	var mehrere := multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0
	var a := "_IHR" if mehrere else "_DU"
	# zum Sprecher drehen und gestikulieren
	var sp := welt._players_nodes.get(multiplayer.get_unique_id()) as Node3D if welt and "_players_nodes" in welt else null
	if sp:
		var zu := sp.global_position - global_position
		rotation.y = atan2(zu.x, zu.z)
	geste()
	var wer := String(TranslationServer.translate("WIESNCHEF_NAME"))
	if _station == null and _schritt() == 0:
		_frage_stellen(dialog, welt, wer, a)
		return
	var zeilen: Array[String] = zeilen_spaeter
	if _station and not _station.zeilen.is_empty() and not _gehoert.has(_station):
		zeilen = _station.zeilen
		_gehoert[_station] = true
	elif _station and not _station.zeilen.is_empty() and not _tagesbericht_da():
		# schon gehört: die letzte Zeile als Erinnerung
		zeilen = [_station.zeilen[-1]]
	var texte: Array[String] = []
	if zeilen == zeilen_spaeter and _tagesbericht_da():
		# Nach dem Tutorial: heutiges Ziel und Sepps Schulden
		texte = welt.chef_tageszeilen(mehrere, welt._hud._zustand)
		_gehoert_tag = _tag()
	else:
		for k in zeilen:
			texte.append(String(TranslationServer.translate(k + a)))
	dialog.zeigen(wer, texte, Callable())

## Erstes Gespräch im Büro: Lage erklären (Dreck, Schulden) und fragen, ob man
## Sepps Zelt übernimmt. Ja → net_chef_zusage (Schritt 0 erledigt, er geht vor),
## Nein → er ist traurig, man kann jederzeit wiederkommen.
func _frage_stellen(dialog: Node, welt: Node, wer: String, a: String) -> void:
	var schulden := 0
	if welt and "_hud" in welt and welt._hud:
		schulden = int(welt._hud._zustand.get("bank_rest", 0))
	var texte: Array[String] = []
	for k in zeilen_start:
		var t := String(TranslationServer.translate(k + a))
		texte.append(t % Texte.euro(schulden) if t.contains("%s") else t)
	var wahl: Array[String] = [String(TranslationServer.translate("CHEF_WAHL_JA" + a)),
		String(TranslationServer.translate("CHEF_WAHL_NEIN" + a))]
	dialog.zeigen(wer, texte, func(i: int) -> void:
		var antwort: Array[String] = []
		if i == 0:
			antwort.append(String(TranslationServer.translate("CHEF_JA" + a)))
			if welt and welt.has_method("net_chef_zusage"):
				welt.net_chef_zusage.rpc_id(1)
		else:
			antwort.append(String(TranslationServer.translate("CHEF_NEIN_1" + a)))
			antwort.append(String(TranslationServer.translate("CHEF_NEIN_2" + a)))
		geste()
		dialog.zeigen(wer, antwort, Callable()), wahl)

## Zur ersten Station (Zelteingang) vorlaufen — läuft sonst über den Tutorialschritt
func losgehen() -> void:
	if _station == null:
		_gehe_zu(_station_fuer(1), false)

func _gehe_zu(st: RundgangStation, sofort: bool) -> void:
	if st == null or st == _station:
		return
	_station = st
	var marker := st.wegpunkte()
	if marker.is_empty():
		return
	_end_blick = marker[-1].global_rotation.y
	if sofort or st.springen:
		global_position = marker[-1].global_position
		rotation.y = _end_blick
		_weg.clear()
		_punkt = 0
		_figur.stehen()
		return
	_weg.clear()
	for m in marker:
		_weg.append(m.global_position)
	_punkt = 0
	_figur.gehen()

## true, sobald er an der ersten Station (Zelt) steht
func angekommen() -> bool:
	return _station != null and not unterwegs()

func _process(delta: float) -> void:
	_alter += delta
	var s := _schritt()
	if s != _letzter_schritt:
		# Gleich nach dem Laden (oder Beitritt) direkt hinstellen, sonst hinlaufen
		var st := _station_fuer(s)
		if st:
			_gehe_zu(st, _alter < 4.0)
		_letzter_schritt = s
	if _ausruf:
		_ausruf.visible = hat_neues()
	if not unterwegs():
		return
	var ziel: Vector3 = _weg[_punkt]
	var zu := ziel - global_position
	zu.y = 0.0
	if zu.length() < 0.25:
		global_position.y = ziel.y
		_punkt += 1
		if not unterwegs():
			_figur.stehen()
			rotation.y = _end_blick
		return
	global_position += zu.normalized() * minf(TEMPO * delta, zu.length())
	rotation.y = atan2(zu.x, zu.z)

## Beim Reden gestikulieren: eine Steh-Extraanimation, danach wieder stehen.
func geste() -> void:
	if unterwegs() or _figur == null:
		return
	if not _figur.extra():
		return
	get_tree().create_timer(2.6).timeout.connect(func() -> void:
		if not unterwegs() and is_instance_valid(_figur):
			_figur.stehen())

## Nach dem Tutorial erzählt er jeden Tag das Tagesziel (GameManager.chef_tageszeilen)
var _gehoert_tag := -1

func _tag() -> int:
	var w := _welt()
	return int(w._day) if w and "_day" in w else 0

func _tagesbericht_da() -> bool:
	var w := _welt()
	return w != null and w.has_method("chef_tageszeilen") and _schritt() >= int(w.QUEST_COUNT) \
		and "_hud" in w and w._hud != null
