extends Node3D
## Der Wiesnchef: wartet in seinem Wiesenbüro (Onkel Sepps Brief schickt die
## Spieler dorthin, scripts/ui/kino.gd). Ansprechen mit E öffnet das Gespräch
## unten im Bild (scripts/ui/dialog.gd). Danach läuft er schweigend zum
## Zelteingang voraus — das ist die erste Mission — und erklärt dort, wenn man
## ihn wieder anspricht, den Rest.
##
## Das Gespräch sieht nur, wer redet. Das Loslaufen geht über
## game_manager.net_chef_los an alle, damit er überall denselben Weg läuft.
## Die Figur steckt als Kind „Model" in der Szene (siehe scripts/figur.gd).

const Figuren := preload("res://scripts/figuren.gd")
const TEMPO := 1.55

## Welche Figur (Index in Figuren.ALLE)
@export var figur_nr := 2
## Strecke vom Büro zum Zelteingang
@export var weg: Array[Vector3] = []
## Texte (locale/texte.csv, <Schlüssel>_DU / _IHR): im Büro, am Zelt, danach
@export var zeilen_buero: Array[String] = ["CHEF_1", "CHEF_2", "CHEF_3"]
@export var zeilen_zelt: Array[String] = ["CHEF_4", "CHEF_5", "CHEF_6", "CHEF_7"]
@export var zeilen_spaeter: Array[String] = ["CHEF_8"]

var _figur: Figur
var _punkt := -1
var _zelt_erzaehlt := false
var _blick := 0.0

func _ready() -> void:
	add_to_group("wiesnchef")
	add_to_group("interactable")
	_figur = Figuren.einsetzen(self, Figuren.ALLE[posmod(figur_nr, Figuren.ALLE.size())])
	_figur.stehen()
	_blick = rotation.y

func ist_wiesnchef() -> bool:
	return true

## Unterwegs redet er nicht
func ansprechbar() -> bool:
	return not unterwegs()

func unterwegs() -> bool:
	return _punkt >= 0 and _punkt < weg.size()

func interact_point() -> Vector3:
	return global_position

func ansprechen() -> void:
	var dialog := get_tree().get_first_node_in_group("dialog")
	if dialog == null or not ansprechbar():
		return
	var welt := get_tree().current_scene
	var zeilen: Array[String] = zeilen_spaeter
	var danach := Callable()
	if _punkt < 0 and not _zelt_erzaehlt:
		zeilen = zeilen_buero
		danach = func() -> void:
			if welt and welt.has_method("net_chef_los"):
				welt.net_chef_los.rpc()
			else:
				losgehen()
	elif angekommen() and not _zelt_erzaehlt:
		zeilen = zeilen_zelt
		_zelt_erzaehlt = true
	var mehrere := multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0
	var texte: Array[String] = []
	for k in zeilen:
		texte.append(String(TranslationServer.translate(k + ("_IHR" if mehrere else "_DU"))))
	# zum Sprecher drehen und gestikulieren
	var sp := welt._players_nodes.get(multiplayer.get_unique_id()) as Node3D if welt and "_players_nodes" in welt else null
	if sp:
		var zu := sp.global_position - global_position
		rotation.y = atan2(zu.x, zu.z)
	geste()
	dialog.zeigen(String(TranslationServer.translate("WIESNCHEF_NAME")), texte, danach)

## Zum Zelteingang vorlaufen
func losgehen() -> void:
	if _punkt >= 0 or weg.is_empty():
		return
	_punkt = 0
	_figur.gehen()

## true, sobald er am Zelt angekommen ist
func angekommen() -> bool:
	return _punkt >= weg.size()

func _process(delta: float) -> void:
	if not unterwegs():
		return
	var ziel: Vector3 = weg[_punkt]
	var zu := ziel - global_position
	zu.y = 0.0
	if zu.length() < 0.25:
		_punkt += 1
		if _punkt >= weg.size():
			_figur.stehen()
			# am Eingang den nachkommenden Spielern zuwenden
			rotation.y = atan2(-zu.x, -zu.z) if zu.length() > 0.01 else rotation.y + PI
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
