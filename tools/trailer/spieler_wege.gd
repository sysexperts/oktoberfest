extends Node3D
## Trailer: Koop-Spieler laufen je einen Weg ab. Jedes Kind ist ein Path3D
## (im Editor ziehbar) mit diesen Metadaten:
##   name    — Name über dem Kopf (Sepp, Resi …)
##   figur   — Figur-Nummer wie im Warteraum (0, 1, 2 …)
##   farbe   — Farbe wie im Warteraum
##   last    — "fass", "tablett" oder "" (leere Hände)
##             "tablett": statt eines Spielers läuft ein Kellner mit Tablett
##             voller Krüge (Spieler halten Krüge nur für die Ich-Sicht)
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
		var p: Node3D
		if str(weg.get_meta("last", "")) == "tablett":
			var sid := 900 + nr
			var start: Vector3 = (weg as Path3D).global_transform * (weg as Path3D).curve.sample_baked(0.0)
			gm._add_staff(sid, start, gm.ROLE_KELLNER, 3)
			var behaelter: Node = gm._staff_container
			p = behaelter.get_child(behaelter.get_child_count() - 1)
			p.set_carrying(4)
			for l in p.find_children("*", "Label3D", true, false):
				(l as Label3D).visible = false
		else:
			var id := 101 + nr
			gm._add_player(id, nr + 1)
			p = gm._players_nodes[id]
			p.set_info(str(weg.get_meta("name", "Spieler")), int(weg.get_meta("farbe", nr)), int(weg.get_meta("figur", nr)))
			if str(weg.get_meta("last", "")) == "fass":
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
		var r := vor - hier
		var yaw := atan2(-r.x, -r.z) if r.length() > 0.05 else p.rotation.y
		if p.has_method("set_carrying"):
			# Kellner: set_net wie im Spiel
			p.set_net(hier, yaw)
		else:
			p._net_pos = hier
			p._net_yaw = yaw
		if t <= 0.0:
			p.global_position = hier
			p.rotation.y = yaw
