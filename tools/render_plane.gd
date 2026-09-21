extends Node
## Fotografiert drei Stellen aus dem Putzschritt: den Blick auf das zugedeckte
## Lagerregal (dort stand früher „Regal bewegen" statt „Plane abziehen"), den
## Wegweiser über liegengebliebenem Dreck und die Mülltonne vor dem Zelt.
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/render_plane.tscn --resolution 1280x720
## Bilder: tools/plane_regal.png, tools/dreck_pfeil.png, tools/muelltonne.png (nicht im Git)

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".planebackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".planebackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".planebackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".planebackup"))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(40)
		var gm := get_tree().current_scene
		# Zelt übernehmen wie im Tutorial, dann liegen Dreck und Planen drin
		gm.net_book_tent.rpc_id(1)
		await _frames(20)
		gm._spawn_mess_at(gm.DECKEN_PLAETZE[14], 14)
		await _frames(10)
		# Vor das zugedeckte Regal stellen, Blick zur Wand
		var regal: Node3D = null
		for n in gm.get_children():
			if n is Lager:
				regal = n
				break
		var spieler: Node3D = gm.get_node("Players").get_child(0)
		spieler.global_position = regal.global_position + Vector3(1.9, 0, 0)
		spieler.rotation.y = PI * 0.5
		spieler._head.rotation.x = -0.12
		await _frames(30)
		get_viewport().get_texture().get_image().save_png("res://tools/plane_regal.png")
		print("  gespeichert: plane_regal — Ziel: ", spieler._hint_for(spieler._current_target))
		# Zweites Bild: Wegweiser über liegengebliebenem Dreck
		for m in get_tree().get_nodes_in_group("mess"):
			m._liegt = m.MAHN_ZEIT + 5.0
		spieler.global_position = Vector3(0.5, 0, 1.5)
		spieler.rotation.y = 0.0
		# Der Pfeil prüft nur alle PRUEF_TAKT Sekunden, wer der nächste ist
		await _frames(60)
		# Genau ein Stück trägt den Pfeil — davor stellen und hinschauen
		var mit_pfeil: Node3D = null
		for m in get_tree().get_nodes_in_group("mess"):
			if m._pfeil.visible:
				mit_pfeil = m
		# Nur hinschauen, nicht hingehen: beim Umstellen wäre ein anderes Stück das
		# nächste und der Pfeil würde weiterwandern.
		if mit_pfeil:
			var weg := (mit_pfeil.global_position - spieler.global_position)
			spieler.rotation.y = atan2(-weg.x, -weg.z)
			spieler._head.rotation.x = atan2(weg.y + 1.0 - 1.35, Vector2(weg.x, weg.z).length())
		await _frames(20)
		get_viewport().get_texture().get_image().save_png("res://tools/dreck_pfeil.png")
		print("  gespeichert: dreck_pfeil")
		# Drittes Bild: vor der Mülltonne
		var tonne: Node3D = gm.get_node_or_null("Muellplatz")
		tonne.anzahl_setzen(2)
		# Vor der Tonne stehen, wie sie in der Ecke steht (sie ist eingedreht)
		var blick := tonne.global_transform.basis.z.normalized()
		spieler.global_position = tonne.global_position + blick * 4.2
		spieler.rotation.y = atan2(blick.x, blick.z)
		spieler._head.rotation.x = -0.05
		await _frames(20)
		tonne.einwerfen()
		# Erst wenn der Wurf durch ist: Deckel in Ruhe, Spalt zeigt den Füllstand
		await _frames(70)
		get_viewport().get_texture().get_image().save_png("res://tools/muelltonne.png")
		print("  gespeichert: muelltonne — Ziel: ", spieler._hint_for(spieler._current_target))
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".planebackup", echt)
				DirAccess.remove_absolute(echt + ".planebackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
