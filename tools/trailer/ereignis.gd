extends Node3D
## Trailer: echtes Spielereignis auslösen, sobald die Aufnahme läuft.
##   art = "schlaegerei" — Massenschlägerei mit den Gästen am nächsten zu diesem Knoten
##   art = "kotzen"      — Gäste nahe diesem Knoten übergeben sich nacheinander
##   art = "lieferwagen" — Lieferwagen rast den Pfad „Fahrt“ (Kind, Path3D) entlang,
##                         Besucher im Weg fliegen durch die Luft; dazu werden
##                         „anzahl“ Besucher auf den Weg gestellt
## Braucht für Schlägerei/Kotzen ein volles Zelt (ZeltVoll in derselben Szene).

@export_enum("schlaegerei", "kotzen", "lieferwagen") var art := "schlaegerei"
@export var anzahl := 14
## Sekunden nach Aufnahmebeginn
@export var verzug := 0.5
## Kotzen: Abstand zwischen zwei Gästen (s)
@export var takt := 0.8
## Lieferwagen: Tempo in m/s
@export var tempo := 11.0

const VISITOR := preload("res://scenes/visitor.tscn")

var gm: Node
var _t := 0.0
var _aktiv := false
var _ausgeloest := false
var _kotz_liste: Array = []
var _kotz_t := 0.0
var _fahrt: Path3D
var _weg_s := 0.0

func aufstellen() -> void:
	gm = get_tree().current_scene
	_fahrt = get_node_or_null("Fahrt") as Path3D
	if art == "lieferwagen" and _fahrt:
		var start := _fahrt.global_transform * _fahrt.curve.sample_baked(0.0)
		gm._van_show(true, start)
		_wagen_setzen(0.0)
		# Besucher auf die Fahrbahn stellen
		var menge: Node = gm.get_node("Crowd")
		var laenge := _fahrt.curve.get_baked_length()
		var rng := RandomNumberGenerator.new()
		rng.seed = 99
		for i in anzahl:
			var v := VISITOR.instantiate()
			menge.add_child(v)
			v.setup(menge)
			var s := rng.randf_range(0.25, 0.95) * laenge
			var p := _fahrt.global_transform * _fahrt.curve.sample_baked(s)
			(v as Node3D).global_position = p + Vector3(rng.randf_range(-1.6, 1.6), 0.0, rng.randf_range(-1.0, 1.0))

func starten() -> void:
	_t = 0.0
	_aktiv = true
	_ausgeloest = false
	_weg_s = 0.0

func zuruecksetzen() -> void:
	_aktiv = false

func _process(delta: float) -> void:
	if not _aktiv:
		return
	_t += delta
	if not _ausgeloest and _t >= verzug:
		_ausgeloest = true
		_ausloesen()
	if art == "lieferwagen" and _ausgeloest and _fahrt:
		_weg_s += tempo * delta
		_wagen_setzen(_weg_s)
	if art == "kotzen" and not _kotz_liste.is_empty():
		_kotz_t -= delta
		if _kotz_t <= 0.0:
			_kotz_t = takt
			var id: int = _kotz_liste.pop_front()
			gm._net_guest_vomit(id)
			gm._spawn_mess_at(gm._guest_sim[id].pos as Vector3, 0)

func _ausloesen() -> void:
	match art:
		"schlaegerei":
			var ids := _naechste_gaeste(anzahl)
			for id in ids:
				gm._guest_sim[id].mode = 7
			gm._net_schlaegerei_start(PackedInt32Array(ids), Vector3(global_position.x, 0.0, global_position.z))
		"kotzen":
			_kotz_liste = _naechste_gaeste(anzahl)
			_kotz_t = 0.0
		"lieferwagen":
			gm._van_honk()

func _naechste_gaeste(n: int) -> Array:
	var ids: Array = []
	for id in gm._guest_sim.keys():
		var g: Dictionary = gm._guest_sim[id]
		var knoten = gm._guests.get(id)
		if int(g.mode) == 1 and knoten and (knoten as Node3D).visible:
			ids.append(id)
	var hier := global_position
	ids.sort_custom(func(a: int, b: int) -> bool:
		return (gm._guest_sim[a].pos as Vector3).distance_squared_to(hier) < (gm._guest_sim[b].pos as Vector3).distance_squared_to(hier))
	return ids.slice(0, n)

func _wagen_setzen(s: float) -> void:
	var laenge := _fahrt.curve.get_baked_length()
	s = minf(s, laenge)
	var p := _fahrt.global_transform * _fahrt.curve.sample_baked(s)
	var vor := _fahrt.global_transform * _fahrt.curve.sample_baked(minf(s + 1.0, laenge))
	var r := vor - p
	var yaw := atan2(r.x, r.z) if r.length() > 0.05 else PI
	gm._van_show(true, p, yaw)
