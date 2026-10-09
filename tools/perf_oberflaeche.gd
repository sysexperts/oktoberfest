extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Was kostet die Oberfläche? Bildzeit mit HUD, ohne HUD, ohne Bildfilter, ohne beides (Stufe Hoch).
##   godot --path . res://tools/perf_oberflaeche.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _ms() -> String:
		await _warten(1.5)
		var t := 0.0
		var f := 0
		while t < 4.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			f += 1
		return "%.1f ms/Bild" % (t / f * 1000.0)
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await _warten(3.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		Einstellungen.grafik = 2
		Einstellungen.geaendert.emit()
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0, 0.1, 25)
		print("FENSTER ", DisplayServer.window_get_size(), " 3D ", get_viewport().scaling_3d_scale)
		var hud := gm.get_node("HUD") if gm.has_node("HUD") else null
		var filter := gm.get_node("Bildfilter")
		var canvas := []
		for c in gm.get_children():
			if c is CanvasLayer:
				canvas.append(c)
		print("CANVAS-EBENEN: ", canvas.map(func(c): return c.name))
		await _warten(70.0)   # die ersten ~60 s nach dem Laden sind langsamer (Shader, Streaming)
		var hudl := gm.get_node("HUD") as CanvasLayer
		for k in 3:
			print("AB HUD+Filter an:  ", await _ms())
			hudl.visible = false
			filter.visible = false
			print("AB HUD+Filter aus: ", await _ms())
			hudl.visible = true
			filter.visible = true
		get_tree().quit()
