extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Wie viel CPU kostet die Verarbeitungsphase eines Bildes (von process_frame bis frame_pre_draw, enthält auch Animationen),
## und wie viel davon sind Animationen? Misst mit und ohne aktive AnimationPlayer/AnimationTree.
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
	func _messen(s: float) -> float:
		summe = 0.0
		n = 0
		await get_tree().create_timer(s).timeout
		return summe / maxf(1.0, float(n))
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
		gm._popularity = 100.0
		gm._start_shift()
		gm._zelt_offen = true
		gm._apply_crowd(40.0)
		get_tree().process_frame.connect(_anfang)
		RenderingServer.frame_pre_draw.connect(_ende)
		for i in 70:
			gm._spawn_guest()
		await get_tree().create_timer(40.0).timeout
		print("GAESTE_SIM %d Sitze %d" % [gm._guest_sim.size(), gm._seats.size()])
		var spieler: Array = gm.find_children("*", "AnimationPlayer", true, false)
		var baeume: Array = gm.find_children("*", "AnimationTree", true, false)
		var skel: Array = gm.find_children("*", "Skeleton3D", true, false)
		print("AnimationPlayer %d, AnimationTree %d, Skeleton3D %d" % [spieler.size(), baeume.size(), skel.size()])
		var basis := await _messen(4.0)
		print("PHASE Basis: %.2f ms" % basis)
		for a in spieler:
			(a as AnimationPlayer).process_mode = Node.PROCESS_MODE_DISABLED
		var ohne_player := await _messen(4.0)
		print("PHASE ohne AnimationPlayer: %.2f ms (%+.2f)" % [ohne_player, ohne_player - basis])
		for a in baeume:
			(a as AnimationTree).process_mode = Node.PROCESS_MODE_DISABLED
		var ohne_alle := await _messen(4.0)
		print("PHASE ohne AnimationPlayer+Tree: %.2f ms (%+.2f)" % [ohne_alle, ohne_alle - basis])
		for a in spieler:
			(a as AnimationPlayer).process_mode = Node.PROCESS_MODE_INHERIT
		for a in baeume:
			(a as AnimationTree).process_mode = Node.PROCESS_MODE_INHERIT
		get_tree().quit()
