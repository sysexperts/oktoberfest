extends Node
## Gefallen von Horst (Plan: docs/PLAN_STORY.md, Abschnitt 18.1): Aktions-Quests auf der Kirmes. Nimmt man einen Gefallen per Mail an,
## taucht ein Täter auf (Figur aus dem Creator), den man mit E packt und zu einem Security-Posten trägt.
## Bewusst ohne class_name. Liegt als Knoten „Gefallen" in scenes/main.tscn.
##
## Der Server hält den Ablauf (suchen → getragen → erledigt), alle Rechner zeigen Täter und Posten.
## Orte kommen aus den Budenbesitzern der Karte (Gruppe „nachtruhe"), sortiert, damit alle Rechner dieselben wählen.

const TAETER := preload("res://scenes/gefallen/taeter.tscn")
const POSTEN := preload("res://scenes/gefallen/security_posten.tscn")
const GEHEGE := preload("res://scenes/gefallen/gehege.tscn")
const PUNKT := preload("res://scenes/gefallen/punkt.tscn")
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
var _gehege: Node3D = null
var _art := ""
## Gefallen mit Punkten (Sturm, Feuer): die Knoten und die Variante
var _punkte: Array[Node3D] = []
var _quelle: Node3D = null
var _variante := ""
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
		if str(Daten.quest(id).get("typ", "")) in ["gefallen", "kirmes"] and Daten.quest(id).has("gefallen") and _story.zustand(id) == "offen":
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
	if art == "punkte":
		_punkte_starten(id, frei)
		return
	_lauf = {"id": id, "phase": "suchen", "traeger": -1, "art": art}
	var start := Vector3.ZERO
	var ort: int = frei.pick_random()
	var gehege_pos := Vector3.INF
	if art == "sau":
		frei.erase(ort)
		var ort2: int = frei.pick_random() if not frei.is_empty() else ort
		gehege_pos = _gehege_platz(_orte[ort2])
	if art != "spanner" and _gm._crowd != null:
		_dieb_knoten = _gm._crowd.weg_start()
		start = _gm._crowd.punkt(_dieb_knoten)
		_dieb_pos = start
		_dieb_richtung = Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
		_hetze = 0.0
	net_start.rpc(id, art, ort, start, gehege_pos)

@rpc("authority", "reliable", "call_local")
func net_start(_id: String, art: String, ort: int, start: Vector3, gehege_pos: Vector3) -> void:
	_taeter_weg()
	if _orte.is_empty():
		_orte_sammeln()
	if ort < 0 or ort >= _orte.size():
		return
	_phase = "suchen"
	_traeger = -1
	_taeter = TAETER.instantiate() as Node3D
	_taeter.set("art", art)
	_taeter.set("figur", str((Daten.quest(_id).get("gefallen", {}) as Dictionary).get("figur", "")))
	get_tree().current_scene.add_child(_taeter)
	_art = art
	_taeter.global_position = start if art != "spanner" else _orte[ort]
	if art == "sau" and gehege_pos.is_finite():
		_gehege = GEHEGE.instantiate() as Node3D
		get_tree().current_scene.add_child(_gehege)
		_gehege.global_position = gehege_pos

## Freier Platz neben der Straße (nur Server, Ergebnis geht per RPC an alle)
func _gehege_platz(von: Vector3) -> Vector3:
	var cr: Node = _gm._crowd
	return cr.gehege_platz(von) if cr != null and cr.has_method("gehege_platz") else von

@rpc("authority", "reliable", "call_local")
func net_gehege_setzen(pos: Vector3) -> void:
	if _gehege != null and is_instance_valid(_gehege):
		_gehege.global_position = pos

@rpc("any_peer", "reliable", "call_local")
func net_packen() -> void:
	if not multiplayer.is_server() or _lauf.is_empty() or str(_lauf.phase) != "suchen":
		return
	var peer := multiplayer.get_remote_sender_id()
	if peer == 0:
		peer = 1
	var packer := _gm._players_nodes.get(peer) as Node3D if "_players_nodes" in _gm else null
	if packer == null or not is_instance_valid(packer) or _taeter == null or not is_instance_valid(_taeter):
		return
	if packer.global_position.distance_to(_taeter.global_position) > 3.6:
		return   # zu weit weg (Nachzügler-Klick)
	_lauf.phase = "getragen"
	_lauf.traeger = peer
	if str(_lauf.get("art", "")) == "sau":
		net_gehege_setzen.rpc(_gehege_platz(packer.global_position))
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
	_erfuellt()

## Gefallen geschafft: Quest abschließen, Belohnung, aufräumen (nur Server)
func _erfuellt() -> void:
	var id := str(_lauf.id)
	# „fertig" hält den Ablauf fest, bis die Story die Quest abgeschlossen hat (sonst startet _abgleich ihn neu)
	_lauf.phase = "fertig"
	_story.ereignis("gefallen_" + id)
	var lohn := int((Daten.quest(id).get("belohnung", {}) as Dictionary).get("geld", 0))
	_gm._melde("MSG_GEFALLEN_UEBERGEBEN" if str(_lauf.get("art", "")) != "punkte" else "MSG_GEFALLEN_GESCHAFFT", [_gm._eur(lohn)], 2)
	_gm._broadcast_meta()
	_lauf = {}
	net_ende.rpc()

@rpc("authority", "reliable", "call_local")
func net_ende() -> void:
	# Geschafft: der Träger wirft ihn in Gehege oder Posten, dann verschwindet er
	if _phase == "getragen" and _taeter != null and is_instance_valid(_taeter):
		_einwerfen(_taeter)
		_taeter = null
	if _traeger >= 0 and "_players_nodes" in _gm:
		var sp: Node = _gm._players_nodes.get(_traeger)
		if sp != null and is_instance_valid(sp):
			sp.set("traegt_taeter", false)
	_phase = ""
	_traeger = -1
	_taeter_weg()

## Bogen vom Träger ins Ziel (Gehege bei der Sau, sonst der nächste Posten)
func _einwerfen(t: Node3D) -> void:
	var ziel := t.global_position
	if _gehege != null and is_instance_valid(_gehege) and _art == "sau":
		ziel = _gehege.global_position + Vector3(0, 0.1, 0)
	else:
		var best := INF
		for p in _posten:
			if is_instance_valid(p) and t.global_position.distance_squared_to(p.global_position) < best:
				best = t.global_position.distance_squared_to(p.global_position)
				ziel = p.global_position
	var start := t.global_position
	var tw := t.create_tween()
	var flug := func(f: float) -> void:
		if is_instance_valid(t):
			t.global_position = start.lerp(ziel, f) + Vector3(0, sin(f * PI) * 1.6, 0)
			t.rotation.x = f * TAU
	tw.tween_method(flug, 0.0, 1.0, 0.7)
	if _art == "sau" and _gehege != null and is_instance_valid(_gehege):
		# Das Gehege bleibt noch kurz stehen, die Sau landet darin
		var g := _gehege
		_gehege = null
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			if is_instance_valid(g):
				g.queue_free())
		tw.tween_interval(1.2)
	tw.tween_callback(t.queue_free)

func _taeter_weg() -> void:
	for p in _punkte:
		if is_instance_valid(p):
			p.queue_free()
	_punkte.clear()
	if _quelle != null and is_instance_valid(_quelle):
		_quelle.queue_free()
	_quelle = null
	if "_players_nodes" in _gm:
		for sp in _gm._players_nodes.values():
			if sp != null and is_instance_valid(sp):
				sp.set("traegt_wasser", false)
	if _gehege != null and is_instance_valid(_gehege):
		_gehege.queue_free()
	_gehege = null
	if _taeter != null and is_instance_valid(_taeter):
		_taeter.queue_free()
	_taeter = null

# ------------------------------------------------------------------ Punkte (Sturm, Feuer)
func _punkte_starten(id: String, frei: Array[int]) -> void:
	var d: Dictionary = Daten.quest(id).get("gefallen", {})
	var variante := str(d.get("variante", "sturm"))
	var anzahl := mini(int(d.get("anzahl", 5)), frei.size())
	frei.shuffle()
	var orte := PackedInt32Array()
	for i in anzahl:
		orte.append(frei[i])
	var quelle := -1
	if variante in ["feuer", "lieferung"] and frei.size() > anzahl:
		quelle = frei[anzahl]
	_lauf = {"id": id, "phase": "suchen", "traeger": -1, "art": "punkte", "variante": variante, "offen": anzahl,
		"zeit": float(d.get("zeit", 150.0)), "wasser": {}}
	net_punkte_start.rpc(id, variante, orte, quelle)

@rpc("authority", "reliable", "call_local")
func net_punkte_start(_id: String, variante: String, orte: PackedInt32Array, quelle: int) -> void:
	_taeter_weg()
	if _orte.is_empty():
		_orte_sammeln()
	_art = "punkte"
	_variante = variante
	_phase = "suchen"
	for i in orte.size():
		if orte[i] < 0 or orte[i] >= _orte.size():
			continue
		var p := PUNKT.instantiate() as Node3D
		p.set("variante", variante)
		p.set("index", i)
		get_tree().current_scene.add_child(p)
		p.global_position = _orte[orte[i]]
		_punkte.append(p)
	if quelle >= 0 and quelle < _orte.size():
		_quelle = PUNKT.instantiate() as Node3D
		_quelle.set("variante", "lager" if variante == "lieferung" else "quelle")
		get_tree().current_scene.add_child(_quelle)
		_quelle.global_position = _orte[quelle]

## Feuerlöschen: am Brunnen einen Eimer füllen
@rpc("any_peer", "reliable", "call_local")
func net_wasser() -> void:
	if not multiplayer.is_server() or _lauf.is_empty() or str(_lauf.get("art", "")) != "punkte":
		return
	var peer := multiplayer.get_remote_sender_id()
	if peer == 0:
		peer = 1
	(_lauf.wasser as Dictionary)[peer] = true
	net_wasser_stand.rpc(peer, true)
	_gm._melde("MSG_KISTE_GENOMMEN" if str(_lauf.get("variante", "")) == "lieferung" else "MSG_EIMER_VOLL", [], 0)

@rpc("authority", "reliable", "call_local")
func net_wasser_stand(peer: int, voll: bool) -> void:
	var sp: Node = _gm._players_nodes.get(peer) if "_players_nodes" in _gm else null
	if sp != null and is_instance_valid(sp):
		sp.set("traegt_wasser", voll)

## Einen Punkt erledigen (Plane sichern, Feuer löschen)
@rpc("any_peer", "reliable", "call_local")
func net_punkt(i: int) -> void:
	if not multiplayer.is_server() or _lauf.is_empty() or str(_lauf.get("art", "")) != "punkte":
		return
	var peer := multiplayer.get_remote_sender_id()
	if peer == 0:
		peer = 1
	if i < 0 or i >= _punkte.size() or bool(_punkte[i].get("erledigt")):
		return
	if str(_lauf.variante) in ["feuer", "lieferung"]:
		if not bool((_lauf.wasser as Dictionary).get(peer, false)):
			return
		(_lauf.wasser as Dictionary)[peer] = false
		net_wasser_stand.rpc(peer, false)
	net_punkt_fertig.rpc(i)
	_lauf.offen = int(_lauf.offen) - 1
	if int(_lauf.offen) <= 0:
		_erfuellt()
	else:
		_gm._melde("MSG_GEFALLEN_REST", [int(_lauf.offen)], 0)

@rpc("authority", "reliable", "call_local")
func net_punkt_fertig(i: int) -> void:
	if i >= 0 and i < _punkte.size() and is_instance_valid(_punkte[i]):
		_punkte[i].erledigt_setzen()

## Zeit läuft (nur bei Gefallen mit Zeitlimit): abgelaufen = gescheitert
func _punkte_zeit(delta: float) -> void:
	_lauf.zeit = float(_lauf.zeit) - delta
	if float(_lauf.zeit) > 0.0:
		return
	var id := str(_lauf.id)
	_lauf = {}
	_gm._melde("MSG_GEFALLEN_ZU_SPAET", [], 1)
	_story._verfallen(id)
	net_ende.rpc()
	_gm._broadcast_meta()

# ------------------------------------------------------------------ Dieb (Server)
## Der Dieb läuft die Wege der Menge entlang (scripts/crowd.gd). Kommt ein Spieler nah, rennt er vom Spieler weg,
## wird aber nach einer Weile müde (so lange rennt er, danach japst er) — mit Sprint ist er einzuholen.
## Tempo je Art: [gehen, rennen, müde, Ausdauer in s, Alarmabstand]
const TEMPO := {"dieb": [1.6, 5.0, 2.6, 7.0, 14.0], "sau": [1.4, 5.6, 2.2, 6.0, 12.0], "spion": [1.8, 5.2, 2.4, 5.5, 18.0]}
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
	var tp: Array = TEMPO[str(_lauf.get("art", "dieb"))]
	var sp_pos := _naechster_spieler(_dieb_pos)
	var nah := sp_pos.is_finite() and _dieb_pos.distance_to(sp_pos) < float(tp[4])
	if nah:
		_hetze += delta
	else:
		_hetze = maxf(0.0, _hetze - delta * 0.7)
	var tempo := float(tp[0])
	if nah:
		tempo = float(tp[1]) if _hetze < float(tp[3]) else float(tp[2])
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
	if multiplayer.is_server() and not _lauf.is_empty() and str(_lauf.get("art", "")) == "punkte":
		_punkte_zeit(delta)
	if multiplayer.is_server() and not _lauf.is_empty() and str(_lauf.get("art", "")) in ["dieb", "sau", "spion"] and str(_lauf.phase) == "suchen":
		_dieb_schritt(delta)
	if _phase != "getragen" or _taeter == null or not is_instance_valid(_taeter):
		return
	var sp := _gm._players_nodes.get(_traeger) as Node3D if "_players_nodes" in _gm else null
	if sp == null or not is_instance_valid(sp):
		return
	# Wie der Raufbold: vor dem Träger auf dem Arm, schaut ihn an und zappelt
	var vorn := -sp.global_transform.basis.z
	vorn.y = 0.0
	vorn = vorn.normalized() if vorn.length() > 0.01 else Vector3(0, 0, 1)
	var ziel := sp.global_position + vorn * 0.9 + Vector3(0, 0.55, 0)
	_taeter.global_position = _taeter.global_position.lerp(ziel, clampf(delta * 14.0, 0.0, 1.0))
	_taeter.rotation = Vector3(0.0, sp.rotation.y + PI, sin(Time.get_ticks_msec() * 0.012) * 0.25)
	if _taeter.has_method("zappeln"):
		_taeter.zappeln()
	_taeter.set("getragen", true)
	_taeter.remove_from_group("interactable")

## Für den Zielpfeil (scripts/ui/zielmarker.gd): wohin gerade?
func ziel_fuer(spieler: Node3D) -> Node3D:
	if _art == "punkte" and _phase == "suchen":
		if _variante in ["feuer", "lieferung"] and not bool(spieler.get("traegt_wasser")) and _quelle != null and is_instance_valid(_quelle):
			return _quelle
		var bester_punkt: Node3D = null
		var abstand_min := INF
		for p in _punkte:
			if is_instance_valid(p) and not bool(p.get("erledigt")):
				var a := spieler.global_position.distance_squared_to(p.global_position)
				if a < abstand_min:
					abstand_min = a
					bester_punkt = p
		return bester_punkt
	if _phase == "suchen" and _taeter != null and is_instance_valid(_taeter):
		return _taeter
	if _phase == "getragen" and bool(spieler.get("traegt_taeter")) and _art == "sau":
		return _gehege
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
