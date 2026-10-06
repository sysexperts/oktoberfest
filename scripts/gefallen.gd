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
	var art := str((Daten.quest(id).get("gefallen", {}) as Dictionary).get("art", "spanner"))
	_lauf = {"id": id, "phase": "suchen", "traeger": -1, "art": art}
	var start := Vector3.ZERO
	if art == "dieb" and _gm._crowd != null:
		_dieb_knoten = _gm._crowd.weg_start()
		start = _gm._crowd.punkt(_dieb_knoten)
		_dieb_pos = start
		_dieb_richtung = Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
		_hetze = 0.0
	net_start.rpc(id, art, frei.pick_random(), start)

@rpc("authority", "reliable", "call_local")
func net_start(_id: String, art: String, ort: int, start: Vector3) -> void:
	_taeter_weg()
	if _orte.is_empty():
		_orte_sammeln()
	if ort < 0 or ort >= _orte.size():
		return
	_phase = "suchen"
	_traeger = -1
	_taeter = TAETER.instantiate() as Node3D
	_taeter.set("art", art)
	get_tree().current_scene.add_child(_taeter)
	_taeter.global_position = start if art == "dieb" else _orte[ort]

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
	var lohn := int((Daten.quest(id).get("belohnung", {}) as Dictionary).get("geld", 0))
	_gm._melde("MSG_GEFALLEN_UEBERGEBEN", [_gm._eur(lohn)], 2)
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

# ------------------------------------------------------------------ Dieb (Server)
## Der Dieb läuft die Wege der Menge entlang (scripts/crowd.gd). Kommt ein Spieler nah, rennt er vom Spieler weg,
## wird aber nach einer Weile müde (so lange rennt er, danach japst er) — mit Sprint ist er einzuholen.
const DIEB_GEHEN := 1.6
const DIEB_RENNEN := 5.0
const DIEB_MUEDE := 2.6
const DIEB_AUSDAUER := 7.0
const DIEB_ALARM := 14.0
var _dieb_knoten := -1
var _dieb_pos := Vector3.ZERO
var _dieb_richtung := Vector3.FORWARD
var _hetze := 0.0
var _melde_t := 0.0

func _naechster_spieler(von: Vector3) -> Vector3:
	var bester := Vector3(INF, INF, INF)
	var d := INF
	for sp in _gm._players_nodes.values():
		if sp is Node3D and is_instance_valid(sp):
			var a := von.distance_squared_to((sp as Node3D).global_position)
			if a < d:
				d = a
				bester = (sp as Node3D).global_position
	return bester

func _dieb_schritt(delta: float) -> void:
	var cr: Node = _gm._crowd
	if cr == null or _dieb_knoten < 0:
		return
	var sp_pos := _naechster_spieler(_dieb_pos)
	var nah := sp_pos.is_finite() and _dieb_pos.distance_to(sp_pos) < DIEB_ALARM
	if nah:
		_hetze += delta
	else:
		_hetze = maxf(0.0, _hetze - delta * 0.7)
	var tempo := DIEB_GEHEN
	if nah:
		tempo = DIEB_RENNEN if _hetze < DIEB_AUSDAUER else DIEB_MUEDE
	var ziel: Vector3 = cr.punkt(_dieb_knoten)
	var zu := ziel - _dieb_pos
	zu.y = 0.0
	if zu.length() < 0.5:
		var neu: int = cr.weiter(_dieb_knoten, _dieb_richtung)
		if nah and sp_pos.is_finite():
			# nicht dem Verfolger entgegen: dann lieber andersherum
			if cr.punkt(neu).distance_to(sp_pos) < cr.punkt(_dieb_knoten).distance_to(sp_pos):
				neu = cr.weiter(_dieb_knoten, -_dieb_richtung)
		var d: Vector3 = cr.punkt(neu) - cr.punkt(_dieb_knoten)
		d.y = 0.0
		if d.length() > 0.01:
			_dieb_richtung = d.normalized()
		_dieb_knoten = neu
	else:
		_dieb_pos += zu.normalized() * minf(tempo * delta, zu.length())
		_dieb_pos.y = ziel.y
	_melde_t -= delta
	if _melde_t <= 0.0:
		_melde_t = 0.1
		var richt := ziel - _dieb_pos
		net_dieb.rpc(_dieb_pos, atan2(-richt.x, -richt.z), tempo)

@rpc("authority", "unreliable_ordered", "call_local")
func net_dieb(pos: Vector3, yaw: float, tempo: float) -> void:
	if _taeter != null and is_instance_valid(_taeter) and _phase == "suchen" and _taeter.has_method("ziel_setzen"):
		_taeter.ziel_setzen(pos, yaw, tempo)

# ------------------------------------------------------------------ Darstellung
## Wird getragen, hängt der Täter über der Schulter des Trägers
func _process(delta: float) -> void:
	if multiplayer.is_server() and not _lauf.is_empty() and str(_lauf.get("art", "")) == "dieb" and str(_lauf.phase) == "suchen":
		_dieb_schritt(delta)
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
