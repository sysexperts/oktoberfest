extends Node3D
## Die frei gebaute Kirmes-Aufstellung (Baumodus, F8).
## Der Server hält die Karte und speichert sie in user://karte.json — wer
## beitritt, bekommt sie geschickt; jede Änderung geht über den Server an alle.
## Ohne gespeicherte Karte startet der Server mit res://daten/karte.json.
## Einträge: {p: Szenenpfad, x, y, z, r: Drehung (rad), s: Größe, sx: Breite}

const Katalog := preload("res://scripts/karten_katalog.gd")
const Figuren := preload("res://scripts/figuren.gd")
## Wohnwagen sind Pflicht: ohne einen kann niemand schlafen und der Tag endet nie.
## Fehlt auf der Karte einer, kommen diese Plätze dazu (Reihe südlich vom Zelt).
const WOHNWAGEN := "res://scenes/caravan.tscn"
const PFLICHT_PLAETZE := [
	{"p": WOHNWAGEN, "x": -2.5, "y": 0.0, "z": -48.0, "r": 0.0},
	{"p": WOHNWAGEN, "x": -9.0, "y": 0.0, "z": -47.5, "r": 0.14},
	{"p": WOHNWAGEN, "x": 4.0, "y": 0.0, "z": -48.5, "r": -0.105},
	{"p": WOHNWAGEN, "x": -15.5, "y": 0.0, "z": -48.0, "r": 0.087},
	{"p": WOHNWAGEN, "x": -22.0, "y": 0.0, "z": -47.0, "r": -0.175},
]

const SPEICHER := "user://karte.json"
const START := "res://daten/karte.json"
const VORLAGE := "res://daten/karte_vorlage.json"

signal geaendert
## Neues Teil steht — von: Peer, der es gesetzt hat (Baumodus merkt es sich fürs Rückgängig)
signal gesetzt(n: int, von: int)

var eintraege := {}   # Nummer -> Eintrag
var _naechste := 1
var _speichern_in := -1.0

func _ready() -> void:
	if multiplayer.is_server():
		var daten := _lesen(SPEICHER)
		if daten.is_empty():
			daten = _lesen(START)
		_alles_setzen(_mit_wohnwagen(daten))
	else:
		net_holen.rpc_id(1)

func _process(delta: float) -> void:
	if _speichern_in < 0.0:
		return
	_speichern_in -= delta
	if _speichern_in < 0.0:
		var f := FileAccess.open(SPEICHER, FileAccess.WRITE)
		if f:
			f.store_string(als_text())
			f.close()

static func _lesen(pfad: String) -> Array:
	if not FileAccess.file_exists(pfad):
		return []
	var d = JSON.parse_string(FileAccess.get_file_as_string(pfad))
	if d is Dictionary and d.get("eintraege") is Array:
		return d.eintraege
	return []

static func vorlage() -> String:
	return FileAccess.get_file_as_string(VORLAGE)

func als_text() -> String:
	return JSON.stringify({"eintraege": eintraege.values()})

## Nächster Eintrag in der Nähe (für die Auswahl im Baumodus)
func naechster(pos: Vector3, max_abstand: float) -> int:
	var beste := -1
	var best_d := max_abstand
	for n: int in eintraege:
		var knoten := get_node_or_null("K%d" % n) as Node3D
		if knoten == null:
			continue
		var d := Vector2(knoten.position.x - pos.x, knoten.position.z - pos.z).length()
		if d < best_d:
			best_d = d
			beste = n
	return beste

func knoten(n: int) -> Node3D:
	return get_node_or_null("K%d" % n) as Node3D

# ------------------------------------------------------------------ Netz
@rpc("any_peer", "reliable")
func net_holen() -> void:
	if multiplayer.is_server():
		_net_alles.rpc_id(multiplayer.get_remote_sender_id(), als_text())

## nummer: Wunschnummer (Rückgängig nach Löschen), b: gespeicherte Basis
@rpc("any_peer", "reliable", "call_local")
func net_setzen(pfad: String, pos: Vector3, r: float, s: float = 1.0, nummer: int = 0, b: Array = []) -> void:
	if not multiplayer.is_server() or not Katalog.erlaubt(pfad):
		return
	var e := {"p": pfad, "x": pos.x, "y": pos.y, "z": pos.z, "r": r, "s": s}
	if b.size() == 9:
		e.b = b
	var n := nummer if nummer > 0 and not eintraege.has(nummer) else _naechste
	var von := multiplayer.get_remote_sender_id()
	_net_setzen.rpc(n, e, von if von != 0 else 1)

@rpc("any_peer", "reliable", "call_local")
func net_bewegen(n: int, pos: Vector3, r: float) -> void:
	if multiplayer.is_server() and eintraege.has(n):
		_net_bewegen.rpc(n, pos, r)

@rpc("any_peer", "reliable", "call_local")
func net_loeschen(n: int) -> void:
	if multiplayer.is_server() and eintraege.has(n):
		_net_loeschen.rpc(n)

## Ganze Karte ersetzen (Vorlage, Leeren, Einfügen aus der Zwischenablage)
@rpc("any_peer", "reliable", "call_local")
func net_ersetzen(text: String, nummern_behalten := false) -> void:
	if not multiplayer.is_server():
		return
	var d = JSON.parse_string(text)
	if not d is Dictionary or not d.get("eintraege") is Array:
		return
	var liste: Array = (d.eintraege as Array).filter(func(e) -> bool:
		return e is Dictionary and Katalog.erlaubt(str(e.get("p", ""))))
	if not nummern_behalten:
		for e: Dictionary in liste:
			e.erase("n")
	_net_alles.rpc(JSON.stringify({"eintraege": liste}))

@rpc("authority", "reliable", "call_local")
func _net_alles(text: String) -> void:
	var d = JSON.parse_string(text)
	_alles_setzen(_mit_wohnwagen(d.eintraege if d is Dictionary and d.get("eintraege") is Array else []))

@rpc("authority", "reliable", "call_local")
func _net_setzen(n: int, e: Dictionary, von: int = 0) -> void:
	_eintrag_setzen(n, e)
	_merken()
	gesetzt.emit(n, von)

@rpc("authority", "reliable", "call_local")
func _net_bewegen(n: int, pos: Vector3, r: float) -> void:
	var e: Dictionary = eintraege.get(n, {})
	if e.is_empty():
		return
	var b: Array = e.get("b", [])
	if b.size() == 9:
		var alt := Basis(Vector3(b[0], b[1], b[2]), Vector3(b[3], b[4], b[5]), Vector3(b[6], b[7], b[8]))
		var neu := Basis(Vector3.UP, r - float(e.get("r", 0.0))) * alt
		e.b = [neu.x.x, neu.x.y, neu.x.z, neu.y.x, neu.y.y, neu.y.z, neu.z.x, neu.z.y, neu.z.z]
	e.x = pos.x
	e.y = pos.y
	e.z = pos.z
	e.r = r
	var k := knoten(n)
	if k:
		k.transform = _transform(e)
	_merken()

@rpc("authority", "reliable", "call_local")
func _net_loeschen(n: int) -> void:
	eintraege.erase(n)
	var k := knoten(n)
	if k:
		k.name = "Weg%d" % n
		k.queue_free()
	_merken()

# ------------------------------------------------------------------ Aufbau
func _merken() -> void:
	if multiplayer.is_server():
		_speichern_in = 1.0
	geaendert.emit()

## Karte ohne Wohnwagen? Dann die Pflichtplätze anhängen (auch bei alten Karten).
static func _mit_wohnwagen(liste: Array) -> Array:
	for e in liste:
		if e is Dictionary and str(e.get("p", "")) == WOHNWAGEN:
			return liste
	return liste + PFLICHT_PLAETZE.duplicate(true)

func _alles_setzen(liste: Array) -> void:
	for c in get_children():
		c.name = "Weg_" + c.name
		c.queue_free()
	eintraege.clear()
	_naechste = 1
	for e in liste:
		if e is Dictionary and Katalog.erlaubt(str(e.get("p", ""))):
			_eintrag_setzen(int(e.get("n", _naechste)), e)
	_merken()

func _eintrag_setzen(n: int, e: Dictionary) -> void:
	_naechste = maxi(_naechste, n + 1)
	var szene := load(str(e.p)) as PackedScene
	if szene == null:
		return
	e.n = n
	eintraege[n] = e
	var k := szene.instantiate() as Node3D
	if k == null:
		return
	k.name = "K%d" % n
	k.transform = _transform(e)
	# Essensbuden: Verkäufer hinter die Theke
	var platz := k.get_node_or_null("Verkaeufer") as Node3D
	if platz:
		var figur := Figuren.ALLE[posmod(n * 7, Figuren.ALLE.size())].instantiate() as Node3D
		figur.name = "Figur"
		figur.transform = platz.transform
		k.add_child(figur)
	add_child(k)
	if figur_von(k):
		figur_von(k).stehen()

static func figur_von(k: Node) -> Figur:
	return k.get_node_or_null("Figur") as Figur

static func _transform(e: Dictionary) -> Transform3D:
	var pos := Vector3(float(e.get("x", 0.0)), float(e.get("y", 0.0)), float(e.get("z", 0.0)))
	var b: Array = e.get("b", [])
	if b.size() == 9:
		return Transform3D(Basis(Vector3(b[0], b[1], b[2]), Vector3(b[3], b[4], b[5]), Vector3(b[6], b[7], b[8])), pos)
	var s := float(e.get("s", 1.0))
	return Transform3D(Basis(Vector3.UP, float(e.get("r", 0.0))).scaled_local(Vector3(s, s, s)), pos)
