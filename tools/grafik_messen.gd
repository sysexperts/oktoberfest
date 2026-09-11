extends Node
## Misst die Bildrate je Grafikstufe bei voller Kirmes (Nacht, maximale Besucher)
## und sucht den Engpass: pro Variante auch Skriptzeit (process), Physikzeit,
## Draw Calls und sichtbare Objekte. Liegt die Skriptzeit nahe an der ganzen
## Bildzeit, bremst die CPU — dann helfen weniger Lichter nichts.
## Startet ein Solo-Spiel, hält den GameManager an (sonst leert er die Kirmes,
## weil das Zelt zu ist), schaltet VSync aus.
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/grafik_messen.tscn --resolution 1920x1080

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]
const MESS_FRAMES := 180

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}
	var _gm: Node
	var _menge: Node
	var _grafik: Node

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		# Sicherung eines abgebrochenen Laufs ist der echte Stand — zuerst zurück.
		# (So ist einmal ein Teststand in Platz 1 liegen geblieben.)
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".messbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".messbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".messbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".messbackup"))
		Net.start_solo(true)
		for i in 3000:   # Ladebildschirm abwarten
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(60)
		_gm = get_tree().current_scene
		_gm.set_process(false)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		# Blick vom Eingang über den Platz
		var spieler: Node3D = _gm.get_node("Players").get_child(0)
		spieler.rotation.y = PI
		_grafik = _gm.get_node("Grafikstufe")
		_menge = _gm.get_node("Crowd")
		print("Auflösung %s · Lichter Kirmes gesamt: %d · Prozessoren: %d" % [
			str(get_viewport().get_visible_rect().size), _grafik.lichter_gesamt(), OS.get_processor_count()])
		print("  %-34s %7s %8s %8s %6s %7s %5s" % ["Variante", "fps", "ms/Bild", "Skript", "Physik", "Draws", "Obj."])

		for stufe in [2, 1, 0]:
			Einstellungen.grafik = stufe
			Einstellungen.anwenden()
			await _messen("Stufe %d" % stufe, true)
			if DisplayServer.get_name() != "headless":
				get_viewport().get_texture().get_image().save_png("res://tools/grafik_stufe_%d.png" % stufe)

		# Engpass suchen, jeweils ausgehend von Stufe 0
		Einstellungen.aufloesung = 0.5
		Einstellungen.anwenden()
		await _messen("Stufe 0 · Auflösung 50 %", true)
		Einstellungen.aufloesung = 1.0
		Einstellungen.anwenden()

		_menge.set_density(0.0)
		await _messen("Stufe 0 · ohne Besucher", false)

		_gm.get_node("Kirmes").visible = false
		await _messen("… und ohne Kirmes", false)

		_gm.get_node("Tent").visible = false
		await _messen("… und ohne Zelt", false)

		var umgebung: Environment = _gm.get_node("WorldEnvironment").environment
		umgebung.fog_enabled = false
		umgebung.glow_enabled = false
		umgebung.ssao_enabled = false
		umgebung.adjustment_enabled = false
		await _messen("… und ohne Umgebungseffekte", false)

		spieler.get_node("Head").rotation.x = deg_to_rad(80.0)
		await _messen("… Blick in den Himmel", false)

		# Welche Skripte laufen jeden Frame? Zählen, dann alle außer dem Spieler anhalten.
		var laufend := {}
		for n in _gm.find_children("*", "", true, false):
			var s: Script = n.get_script()
			if s and (n.is_processing() or n.is_physics_processing()):
				laufend[s.resource_path] = int(laufend.get(s.resource_path, 0)) + 1
		print("  Laufende Skripte: ", laufend)
		for n in _gm.find_children("*", "", true, false):
			if n.get_script() and n != spieler:
				n.set_process(false)
				n.set_physics_process(false)
		await _messen("… alle Skripte außer Spieler aus", false)
		spieler.set_physics_process(false)
		await _messen("… auch Spieler aus", false)

		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".messbackup", echt)
				DirAccess.remove_absolute(echt + ".messbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("MESSUNG FERTIG")
		get_tree().quit()

	## volle_menge: vorher auf maximale Besucherzahl auffüllen
	func _messen(name: String, volle_menge: bool) -> void:
		if volle_menge:
			_menge.set_density(1.0)
			var warten := 0
			while _menge.get_child_count() != _menge.max_visitors and warten < 400:
				await get_tree().process_frame
				warten += 1
		await _frames(40)
		var skript := 0.0
		var physik := 0.0
		var draws := 0.0
		var objekte := 0.0
		var start := Time.get_ticks_usec()
		for i in MESS_FRAMES:
			await get_tree().process_frame
			skript += Performance.get_monitor(Performance.TIME_PROCESS)
			physik += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
			draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			objekte += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		var sek := float(Time.get_ticks_usec() - start) / 1000000.0
		var n := float(MESS_FRAMES)
		print("  %-34s %7.1f %8.1f %8.1f %6.1f %7d %5d" % [
			name, n / sek, sek / n * 1000.0, skript / n * 1000.0, physik / n * 1000.0,
			roundi(draws / n), roundi(objekte / n)])

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame
