class_name FoodStation
extends Node3D
## Kochstelle: 1 = Brezn, 2 = Wurst, 3 = Hendl. Auf dem Kochtresen liegen mehrere Portionen gleichzeitig
## (Knoten Slot0 … in scenes/food_station.tscn). E legt eine neue auf, nach GAR_ZEIT ist sie fertig,
## nach weiteren BRENN_ZEIT verbrennt sie. Fertiges kommt mit E auf den Teller, Verbranntes (carry_state 4)
## gehört in den Mülleimer daneben (scripts/muell_eimer.gd).
## Der Server rechnet die Zeiten und meldet jeden Wechsel an alle, die Farbe läuft bei jedem selbst mit.

const FOOD_NAMES := {1: "Pretzel", 2: "Sosis", 3: "Hendl"}
const FOOD_COLORS := {1: Color(0.72, 0.45, 0.15), 2: Color(0.8, 0.3, 0.2), 3: Color(0.9, 0.6, 0.25)}
## Die Modelle (assets/models/grill_*.glb) sind klein gebaut: so groß liegen sie auf dem Grill
const MODELL_GROESSE := {1: 1.5, 2: 1.6, 3: 1.2}
const GAR_ZEIT := 8.0
const BRENN_ZEIT := 20.0
## Farben der Portion: roh → gar → verkohlt
const ROH := Color(0.93, 0.62, 0.62)
const GAR := Color(0.62, 0.34, 0.16)
const KOHLE := Color(0.06, 0.05, 0.05)

enum { LEER, BRAET, FERTIG, VERBRANNT }

@export var food_type := 1
## Wie viele Portionen gleichzeitig auf den Grill passen und wie weit sie auseinanderliegen (m, quer zum Tresen)
@export_range(1, 4) var plaetze := 4
@export var abstand := 0.27


var _zustand: Array[int] = []
var _zeit: Array[float] = []
var _slots: Array[Node3D] = []

func _ready() -> void:
	add_to_group("interactable")
	for i in 16:
		var s := get_node_or_null("Slot%d" % i) as Node3D
		if s == null:
			break
		if i >= plaetze:
			s.queue_free()
			continue
		_slots.append(s)
		_zustand.append(LEER)
		_zeit.append(0.0)
		s.position = Vector3((float(i) - float(plaetze - 1) * 0.5) * abstand, 0.0, 0.0)
		(s.get_node("Wuerstl") as Node3D).visible = food_type == 2
		(s.get_node("Brezn") as Node3D).visible = food_type == 1
		(s.get_node("Hendl") as Node3D).visible = food_type == 3
		for n in ["Wuerstl", "Brezn", "Hendl"]:
			(s.get_node(n) as Node3D).scale = Vector3.ONE * float(MODELL_GROESSE.get(food_type, 1.0))
		# Jede Portion bekommt ihr eigenes Material, damit sie einzeln gar wird (roh → braun → schwarz)
		for n in ["Wuerstl", "Brezn", "Hendl"]:
			var m := StandardMaterial3D.new()
			m.roughness = 0.5
			m.albedo_color = ROH
			for mi in s.get_node(n).find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = m
	# Statt Text zeigt der fertige Teller über dem Grill, was hier gebraten wird
	var schild := get_node_or_null("Schild") as EssenTeller
	if schild:
		schild.sorte = clampi(food_type, 1, 3)

func hat_frei() -> bool:
	return _zustand.has(LEER)

func hat_fertig() -> bool:
	return _zustand.has(FERTIG)

func hat_verbrannt() -> bool:
	return _zustand.has(VERBRANNT)

# ------------------------------------------------------------ Ablauf (Server)
@rpc("any_peer", "reliable", "call_local")
func net_legen() -> void:
	if not multiplayer.is_server():
		return
	var i := _zustand.find(LEER)
	if i < 0:
		return
	_setze.rpc(i, BRAET)

## Nimmt die am besten durchgegarte Portion (fertig vor verbrannt) und gibt sie dem Spieler.
@rpc("any_peer", "reliable", "call_local")
func net_nehmen() -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	var i := _zustand.find(FERTIG)
	if i < 0:
		i = _zustand.find(VERBRANNT)
	if i < 0:
		return
	var verbrannt := _zustand[i] == VERBRANNT
	_setze.rpc(i, LEER)
	if s == multiplayer.get_unique_id():
		_bekommen(verbrannt)
	else:
		_bekommen.rpc_id(s, verbrannt)

## Beim Nehmenden: die Portion kommt auf den Teller in die Hand
@rpc("authority", "reliable", "call_local")
func _bekommen(verbrannt: bool) -> void:
	var gm := get_tree().current_scene
	var p = gm._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in gm else null
	if p == null or int(p.carry_state) != 0:
		return
	p.carry_state = 4 if verbrannt else 2
	p.carry_type = food_type
	p.carry_fill = 1.0

@rpc("authority", "reliable", "call_local")
func _setze(i: int, z: int) -> void:
	if i < 0 or i >= _slots.size():
		return
	_zustand[i] = z
	_zeit[i] = BRENN_ZEIT if z == VERBRANNT else 0.0
	_anzeigen(i)

func _process(delta: float) -> void:
	for i in _slots.size():
		var z := _zustand[i]
		if z != BRAET and z != FERTIG:
			continue
		_zeit[i] += delta
		if multiplayer.is_server():
			if z == BRAET and _zeit[i] >= GAR_ZEIT:
				_setze.rpc(i, FERTIG)
				continue
			if z == FERTIG and _zeit[i] >= BRENN_ZEIT:
				_setze.rpc(i, VERBRANNT)
				continue
		_anzeigen(i)

# ------------------------------------------------------------ Darstellung
func _anzeigen(i: int) -> void:
	var s := _slots[i]
	var z := _zustand[i]
	s.visible = z != LEER
	if z == LEER:
		return
	var farbe := ROH
	var anteil := 0.0
	match z:
		BRAET:
			anteil = clampf(_zeit[i] / GAR_ZEIT, 0.0, 1.0)
			farbe = ROH.lerp(GAR, anteil)
		FERTIG:
			anteil = clampf(_zeit[i] / BRENN_ZEIT, 0.0, 1.0)
			farbe = GAR.lerp(Color(0.3, 0.17, 0.09), anteil)
		VERBRANNT:
			farbe = KOHLE
	for n in ["Wuerstl", "Brezn", "Hendl"]:
		for mi in s.get_node(n).find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).material_override as StandardMaterial3D
			if m:
				m.albedo_color = farbe
	# Balken: beim Garen füllt er sich (grün), fertig läuft er rückwärts von gelb nach rot („jetzt nehmen!")
	var balken := s.get_node("Balken") as MeshInstance3D
	balken.visible = z != VERBRANNT
	balken.scale.x = maxf(0.02, anteil if z == BRAET else 1.0 - anteil)
	var bm := balken.get_surface_override_material(0) as StandardMaterial3D
	if bm:
		bm.albedo_color = Color(0.4, 0.85, 0.35) if z == BRAET else Color(1, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.15), anteil)
	var dampf := s.get_node("Dampf") as CPUParticles3D
	dampf.emitting = (z == BRAET and anteil > 0.15) or z == VERBRANNT
