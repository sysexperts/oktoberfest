extends Node
## Bilder vom Lagerraum im Zelt (scenes/lagerraum.tscn): von außen neben dem
## Büro und von innen mit den beiden Regalen.
## Aufruf: godot --path . res://tools/render_lagerraum.tscn --resolution 1280x720

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
		for i in 6000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(60)
		var gm := get_tree().current_scene
		gm.net_book_tent.rpc_id(1)
		await _frames(10)
		var spieler: Node3D = gm.get_node("Players").get_child(0)

		# 1 Von der Zeltmitte aus: Büro links, Lagerraum rechts daneben
		await _blick(spieler, Vector3(-2.0, 0, 2.0), Vector3(-6.0, 1.3, 9.4))
		await _bild("lagerraum_aussen")

		# 2 In der Tür
		await _blick(spieler, Vector3(-5.4, 0, 5.6), Vector3(-6.0, 1.3, 10.0))
		await _bild("lagerraum_tuer")

		# 3 Drinnen, beide Regale im Bild
		await _blick(spieler, Vector3(-4.9, 0, 7.9), Vector3(-7.4, 1.2, 10.2))
		await _bild("lagerraum_innen")

		for pfad: String in DATEIEN:
			var sich := ProjectSettings.globalize_path(pfad + ".renderbackup")
			if _gab_es[pfad] and FileAccess.file_exists(pfad + ".renderbackup"):
				DirAccess.copy_absolute(sich, ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(sich)
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad))
		get_tree().quit()

	## Spieler hinstellen und zu einem Punkt schauen lassen
	func _blick(spieler: Node3D, wo: Vector3, ziel: Vector3) -> void:
		spieler.global_position = wo
		var d: Vector3 = ziel - (wo + Vector3(0, 1.35, 0))
		spieler.rotation.y = atan2(-d.x, -d.z)
		var kopf := spieler.get_node_or_null("Head") as Node3D
		if kopf:
			kopf.rotation.x = atan2(d.y, Vector2(d.x, d.z).length())
		await _frames(12)

	func _bild(name: String) -> void:
		await _frames(8)
		get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
		print("  gespeichert: ", name)

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame
