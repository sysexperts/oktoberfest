extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Nach Feierabend laufen die Besucher zum Ausgang und verschwinden dort (statt einfach zu verschwinden).
##   godot --headless --path . res://tools/test_heimgehen.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._day = 5
		gm._apply_crowd(14.0)
		await _warten(25.0)
		var crowd = gm._crowd
		var da: int = crowd._visitors.size()
		_check("tagsüber sind Besucher da", da >= 20, str(da))
		# Feierabend: Dichte 0
		gm._nachts_geschlossen = true
		gm._apply_crowd(-1.0)
		await _warten(3.0)
		var gehend := get_tree().get_nodes_in_group("visitor").filter(func(v): return v._heim)
		_check("sie laufen heim (nicht gelöscht)", gehend.size() > 0 and crowd._visitors.size() < da, "%d gehen, %d bleiben" % [gehend.size(), crowd._visitors.size()])
		var nr_vor := get_tree().get_nodes_in_group("visitor").size()
		await _warten(60.0)
		var nr_nach := get_tree().get_nodes_in_group("visitor").size()
		_check("nach und nach weniger Besucher", nr_nach < nr_vor, "%d -> %d" % [nr_vor, nr_nach])
		await _warten(120.0)
		_check("später ist die Kirmes leer", get_tree().get_nodes_in_group("visitor").size() == 0, str(get_tree().get_nodes_in_group("visitor").size()))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
