extends Node
## Gefallen von Horst (Plan: docs/PLAN_STORY.md, Abschnitt 18.1): Aktions-Quests auf der Kirmes. Nimmt man einen Gefallen per Mail an,
## taucht ein Täter auf (Figur aus dem Creator), den man mit E packt und zu einem Security-Posten trägt.
## Bewusst ohne class_name. Liegt als Knoten „Gefallen" in scenes/main.tscn.
##
## Der Server hält den Ablauf (suchen → getragen → erledigt), alle Rechner zeigen Täter und Posten.
## Orte kommen aus den Budenbesitzern der Karte (Gruppe „nachtruhe"), sortiert, damit alle Rechner dieselben wählen.

const TAETER := preload("res://scenes/gefallen/taeter.tscn")
const POSTEN := preload("res://scenes/gefallen/security_posten.tscn")
## So viele feste Security-Posten stehen verteilt über die Kirmes
const POSTEN_ANZAHL := 4
## So weit vor der Bude steht der Täter oder Posten (Kundenseite)
const VOR_BUDE := 3.2

var _gm: Node
var _story: Node
var _orte: Array[Vector3] = []
var _posten_index: Array[int] = []
var _posten: Array[Node3D] = []
var _taeter: Node3D = null
## Server: laufender Gefallen {id, phase, traeger}; leer = keiner
var _lauf := {}
## Alle Rechner: Phase und Träger für die Darstellung
var _phase := ""
var _traeger := -1

func _ready() -> void:
	add_to_group("gefallen")
	_gm = get_parent()
	_story = _gm.get_node("Story")
	_story.geaendert.connect(_abgleich)
	_posten_bauen.call_deferred()

# ------------------------------------------------------------------ Orte und Posten
func _orte_sammeln() -> void:
	_orte.clear()
	var buden: Array[Node3D] = []
	for n in get_tree().get_nodes_in_group("nachtruhe"):
		if n is Node3D and n.has_method("ist_budenbesitzer"):
			buden.append(n)
	buden.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.x < b.global_position.x or (is_equal_approx(a.global_position.x, b.global_position.x) and a.global_position.z < b.global_position.z))
	for b in buden:
		var p: Vector3 = b.global_position + b.global_transform.basis.z * VOR_BUDE
		p.y = b.global_position.y
		_orte.append(p)

func _posten_bauen() -> void:
	await get_tree().create_timer(2.5).timeout
	_orte_sammeln()
	if _orte.size() < POSTEN_ANZAHL + 1:
		return
	for i in POSTEN_ANZAHL:
		var idx := roundi(float(i) * float(_orte.size() - 1) / float(POSTEN_ANZAHL - 1))
		_posten_index.append(idx)
		var p := POSTEN.instantiate() as Node3D
		get_tree().current_scene.add_child(p)
		p.global_position = _orte[idx]
		_posten.append(p)

# ------------------------------------------------------------------ Ablauf (Server)
## Passt den Ablauf an den Stand der Story-Quests an: angenommener Gefallen → Täter, abgelaufen → weg
func _abgleich() -> void:
	if not multiplayer.is_server() or not _story.aktiv:
		return
	if not _lauf.is_empty():
		if _story.zustand(str(_lauf.id)) != "offen":
			_lauf = {}
			net_ende.rpc()
		return
	for id: String in _story.quests.keys():
		if str(Daten.quest(id).get("typ", "")) == "gefallen" and _story.zustand(id) == "offen":
			_starten(id)
			return

const Daten := preload("res://scripts/story/daten.gd")

func _starten(id: String) -> void:
	if _orte.is_empty():
		_orte_sammeln()
	var frei: Array[int] = []
	for i in _orte.size():
		if not _posten_index.has(i):
			frei.append(i)
	if frei.is_empty():
		return
	_lauf = {"id": id, "phase": "suchen", "traeger": -1}
	net_start.rpc(id, frei.pick_random())

@rpc("authority", "reliable", "call_local")
func net_start(_id: String, ort: int) -> void:
	_taeter_weg()
	if _orte.is_empty():
		_orte_sammeln()
	if ort < 0 or ort >= _orte.size():
		return
	_phase = "suchen"
	_traeger = -1
	_taeter = TAETER.instantiate() as Node3D
	get_tree().current_scene.add_child(_taeter)
	_taeter.global_position = _orte[ort]

@rpc("any_peer", "reliable", "call_local")
func net_packen() -> void:
	if not multiplayer.is_server() or _lauf.is_empty() or str(_lauf.phase) != "suchen":
		return
	var peer := multiplayer.get_remote_sender_id()
	if peer == 0:
		peer = 1
	_lauf.phase = "getragen"
	_lauf.traeger = peer
	net_stand.rpc("getragen", peer)

@rpc("authority", "reliable", "call_local")
func net_stand(phase: String, traeger: int) -> void:
	_phase = phase
	_traeger = traeger
	var sp: Node = _gm._players_nodes.get(traeger) if "_players_nodes" in _gm else null
	if sp != null and is_instance_valid(sp):
		sp.set("traegt_taeter", phase == "getragen")

@rpc("any_peer", "reliable", "call_local")
func net_uebergeben() -> void:
	if not multiplayer.is_server() or _lauf.is_empty() or str(_lauf.phase) != "getragen":
		return
	var peer := multiplayer.get_remote_sender_id()
	if peer == 0:
		peer = 1
	if peer != int(_lauf.traeger):
		return
	var id := str(_lauf.id)
	# „fertig" hält den Ablauf fest, bis die Story die Quest abgeschlossen hat (sonst startet _abgleich ihn neu)
	_lauf.phase = "fertig"
	_story.ereignis("gefallen_" + id)
	_gm._melde("MSG_GEFALLEN_UEBERGEBEN", [], 2)
	_gm._broadcast_meta()
	_lauf = {}
	net_ende.rpc()

@rpc("authority", "reliable", "call_local")
func net_ende() -> void:
	if _traeger >= 0 and "_players_nodes" in _gm:
		var sp: Node = _gm._players_nodes.get(_traeger)
		if sp != null and is_instance_valid(sp):
			sp.set("traegt_taeter", false)
	_phase = ""
	_traeger = -1
	_taeter_weg()

func _taeter_weg() -> void:
	if _taeter != null and is_instance_valid(_taeter):
		_taeter.queue_free()
	_taeter = null

# ------------------------------------------------------------------ Darstellung
## Wird getragen, hängt der Täter über der Schulter des Trägers
func _process(_delta: float) -> void:
	if _phase != "getragen" or _taeter == null or not is_instance_valid(_taeter):
		return
	var sp := _gm._players_nodes.get(_traeger) as Node3D if "_players_nodes" in _gm else null
	if sp == null or not is_instance_valid(sp):
		return
	_taeter.global_position = sp.global_position + Vector3(0, 1.05, 0) - sp.global_transform.basis.z * 0.15
	_taeter.rotation = Vector3(deg_to_rad(-80.0), sp.rotation.y, 0.0)
	_taeter.remove_from_group("interactable")

## Für den Zielpfeil (scripts/ui/zielmarker.gd): wohin gerade?
func ziel_fuer(spieler: Node3D) -> Node3D:
	if _phase == "suchen" and _taeter != null and is_instance_valid(_taeter):
		return _taeter
	if _phase == "getragen" and bool(spieler.get("traegt_taeter")):
		var bester: Node3D = null
		var d := INF
		for p in _posten:
			var abstand := spieler.global_position.distance_squared_to(p.global_position)
			if abstand < d:
				d = abstand
				bester = p
		return bester
	return null
