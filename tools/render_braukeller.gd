extends Node
## Bilder vom Braukeller: Treppenschacht im Zelt, Treppe hinunter, verschlossene
## Tür, und der Brauraum mit Bottich, Kessel und den drei Gärfässern.
## Aufruf: godot --path . res://tools/render_braukeller.tscn --resolution 1280x720

const DATEIEN := ["user://oktoberfest_save.json", "user://saves/slot_1.json", "user://saves/slot_2.json",
	"user://saves/slot_3.json", "user://einstellungen.cfg"]

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".renderbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".renderbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".renderbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".renderbackup"))
		Einstellungen.sprache = "de"
		Einstellungen.anwenden()
		Net.start_solo(true)
		for i in 9000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(60)
		var gm := get_tree().current_scene
		gm.net_book_tent.rpc_id(1)
		await _frames(10)
		# Planen und Dreck aus dem Putzschritt wegräumen, sonst hängt eine Plane
		# vor der Kamera
		gm._clear_messes()
		await _frames(6)
		var sp: Node3D = gm.get_node("Players").get_child(0)

		# 1 Der Schacht im Zeltboden, von der Theke aus
		await _blick(sp, Vector3(-7.2, 0, -6.4), Vector3(-10.3, -2.2, -11.6))
		await _bild("keller_schacht")

		# 2 Auf der Treppe, Blick nach unten zur Tür
		await _blick(sp, Vector3(-10.3, -0.6, -9.6), Vector3(-9.6, -2.9, -12.4))
		await _bild("keller_treppe")

		# 3 Tür verschlossen (Zeltstufe 1)
		await _blick(sp, Vector3(-10.6, -3.4, -12.3), Vector3(-8.7, -2.6, -11.5))
		await _bild("keller_tuer_zu")

		# 4 Nach dem Ausbau: Tür offen
		gm._tent_stage = 2
		gm._keller_tuer_aktualisieren(true)
		await _frames(20)
		await _bild("keller_tuer_offen")

		# 5 Im Brauraum: Bottich und Kessel
		await _blick(sp, Vector3(-8.2, -3.4, -10.4), Vector3(-5.4, -2.7, -7.1))
		await _bild("keller_braustation")

		# 6 Die drei Gärfässer
		await _blick(sp, Vector3(-4.2, -3.4, -6.6), Vector3(-6.4, -2.6, -11.8))
		await _bild("keller_gaerfaesser")

		for pfad: String in DATEIEN:
			var sich := ProjectSettings.globalize_path(pfad + ".renderbackup")
			if _gab_es[pfad] and FileAccess.file_exists(pfad + ".renderbackup"):
				DirAccess.copy_absolute(sich, ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(sich)
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad))
		get_tree().quit()

	func _blick(sp: Node3D, wo: Vector3, ziel: Vector3) -> void:
		sp.global_position = wo
		var d: Vector3 = ziel - (wo + Vector3(0, 1.35, 0))
		sp.rotation.y = atan2(-d.x, -d.z)
		var kopf := sp.get_node_or_null("Head") as Node3D
		if kopf:
			kopf.rotation.x = clampf(atan2(d.y, Vector2(d.x, d.z).length()), -1.2, 1.2)
		await _frames(14)

	func _bild(name: String) -> void:
		# Anzeige, Fadenkreuz-Hinweise und Umrandungen stören im Bild
		var gm := get_tree().current_scene
		gm.get_node("HUD").visible = false
		for n in gm.find_children("*", "CanvasLayer", true, false):
			(n as CanvasLayer).visible = false
		get_tree().call_group("interactable", "set_highlight", false)
		await _frames(8)
		get_viewport().get_texture().get_image().save_png("res://build/szenen/%s.png" % name)
		print("  gespeichert: ", name)

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame
