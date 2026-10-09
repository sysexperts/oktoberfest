extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Wie viele Lichter gibt es, wie viele davon im Umkreis, und was bringt die Entfernungsausblendung auf Hoch?
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _ms(vp: RID) -> String:
		await _warten(1.0)
		var f := 0
		var t := 0.0
		var cpu := 0.0
		var gpu := 0.0
		while t < 4.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			f += 1
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
		return "%.1f ms/Bild  Render-CPU %.1f  GPU %.1f" % [t / f * 1000.0, cpu / f, gpu / f]
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0, 0.1, 25)
		sp.rotation.y = 0.0
		Einstellungen.grafik = 2
		Einstellungen.geaendert.emit()
		var vp := get_viewport().get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(vp, true)
		var lichter := gm.find_children("*", "Light3D", true, false).filter(func(l): return not (l is DirectionalLight3D))
		var sichtbar := lichter.filter(func(l): return (l as Light3D).is_visible_in_tree())
		var kam := get_viewport().get_camera_3d().global_position
		var nah := sichtbar.filter(func(l): return (l as Node3D).global_position.distance_to(kam) < 60.0)
		var mitfade := sichtbar.filter(func(l): return (l as Light3D).distance_fade_enabled)
		print("LICHT gesamt %d, sichtbar %d, davon <60 m %d, mit Entfernungsausblendung %d" % [lichter.size(), sichtbar.size(), nah.size(), mitfade.size()])
		await _warten(70.0)
		print("LICHT Hoch wie jetzt:        ", await _ms(vp))
		for l in sichtbar:
			(l as Light3D).distance_fade_enabled = true
			(l as Light3D).distance_fade_begin = 40.0
			(l as Light3D).distance_fade_length = 10.0
		print("LICHT Hoch Ausblendung 40 m: ", await _ms(vp))
		for l in sichtbar:
			(l as Light3D).distance_fade_enabled = false
		print("LICHT Hoch wie jetzt (2):    ", await _ms(vp))
		get_tree().quit()
