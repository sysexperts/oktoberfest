extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kosten der Gast-Sprechblasen: 70 Gäste, Verarbeitungsphase (process_frame bis frame_pre_draw) in ms pro Bild.
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var t0 := 0
	var summe := 0.0
	var n := 0
	func _anfang() -> void:
		t0 = Time.get_ticks_usec()
	func _ende() -> void:
		summe += float(Time.get_ticks_usec() - t0) / 1000.0
		n += 1
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._tent_stage = 4
		gm._active_count = gm._all_tables.size()
		gm._apply_tent()
		gm._start_shift()
		gm._zelt_offen = true
		for i in 70:
			gm._spawn_guest()
		await get_tree().create_timer(40.0).timeout
		var knoten: Array = gm._guests.values()
		for k in knoten:
			k.set_order(1, 1, 1, 0.5)   # wie der Server: Bestellung offen
		await get_tree().process_frame
		var t1 := Time.get_ticks_usec()
		for bild in 20:
			for k in knoten:
				k.set_order(1, 1, 1, 0.5)
				k.set_laune(0)
				k.set_rausch(0)
		var ms := float(Time.get_ticks_usec() - t1) / 1000.0 / 20.0
		print("PHASE set_order fuer %d Gaeste: %.2f ms pro Bild" % [knoten.size(), ms])
		get_tree().quit()
