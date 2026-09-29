extends Node3D
## Trailer: Koop-Spieler laufen je einen Weg ab. Jedes Kind ist ein Path3D
## (im Editor ziehbar) mit diesen Metadaten:
##   name    — Name über dem Kopf (Sepp, Resi …)
##   figur   — Figur-Nummer wie im Warteraum (0, 1, 2 …)
##   farbe   — Farbe wie im Warteraum
##   last    — "kruege", "fass" oder "" (leere Hände)
##   dauer   — Sekunden für den ganzen Weg
##   verzug  — Sekunden, bevor er losläuft
## Die Figur rennt/geht von selbst passend zum Tempo (wie ein Mitspieler).

var _spieler: Array = []   # [Spielerknoten, Path3D]
var _t := 0.0
var _aktiv := false
var gm: Node

func aufstellen() -> void:
	gm = get_tree().current_scene
	var nr := 0
	for weg in get_children():
		if not weg is Path3D:
			continue
		var id := 101 + nr
		gm._add_player(id, nr + 1)
		var p: Node3D = gm._players_nodes[id]
		p.set_info(str(weg.get_meta("name", "Spieler")), int(weg.get_meta("farbe", nr)), int(weg.get_meta("figur", nr)))
		match str(weg.get_meta("last", "")):
			"kruege":
				p.carry_state = 1
				p.carry_fill = 1.0
				p.carry_type = 1
				p.extra_kruege.assign([2, 3, 1])
			"fass":
				p.carry_state = 3
				p.carry_pkg_kind = 1
		_spieler.append([p, weg])
		nr += 1
	_setzen(0.0)

func starten() -> void:
	_t = 0.0
	_aktiv = true

func zuruecksetzen() -> void:
	_aktiv = false
	_setzen(0.0)

func _process(delta: float) -> void:
	if _aktiv:
		_t += delta
		_setzen(_t)

func _setzen(t: float) -> void:
	for s in _spieler:
		var p: Node3D = s[0]
		var weg: Path3D = s[1]
		var dauer := float(weg.get_meta("dauer", 5.0))
		var a := clampf((t - float(weg.get_meta("verzug", 0.0))) / dauer, 0.0, 1.0)
		var laenge := weg.curve.get_baked_length()
		var hier := weg.global_transform * weg.curve.sample_baked(a * laenge)
		var vor := weg.global_transform * weg.curve.sample_baked(minf(a * laenge + 0.5, laenge))
		p._net_pos = hier
		if t <= 0.0:
			p.global_position = hier
		var r := vor - hier
		if r.length() > 0.05:
			p._net_yaw = atan2(-r.x, -r.z)
			if t <= 0.0:
				p.rotation.y = p._net_yaw
