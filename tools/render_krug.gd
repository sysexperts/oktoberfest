extends Node
## Zeigt die neue Füllstandsanzeige beim Bierzapfen: halb voll und voll,
## dazu den Hinweis am Gast mit halbem Krug. Für die Abnahme der UI.
## Aufruf: godot --path . res://tools/render_krug.tscn --resolution 1280x720

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
		Net.start_solo(true)
		for i in 6000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(60)
		var gm := get_tree().current_scene
		var hud: HUD = gm.get_node("HUD")
		var spieler: Node3D = gm.get_node("Players").get_child(0)
		# Am Fass stehen und zum Fass schauen, damit der Krug in der Hand ist
		var fass: Node3D = gm.get_node("Stations/Keg1")
		spieler.global_position = fass.global_position + Vector3(0, 0, 1.6)
		var d: Vector3 = fass.global_position - spieler.global_position
		spieler.rotation.y = atan2(-d.x, -d.z)
		spieler.carry_state = 1
		spieler.carry_type = 1
		await _frames(10)
		for schritt: Array in [[0.35, "krug_35"], [0.8, "krug_80"], [1.0, "krug_voll"]]:
			spieler.carry_fill = float(schritt[0])
			spieler._update_carry_visual()
			hud.set_krug(spieler.carry_fill, true)
			hud.set_hint("HINT_TAP" if spieler.carry_fill < 1.0 else "HINT_KRUG_VOLL")
			await _bild(str(schritt[1]))
		# Am Gast mit halbem Krug: Hinweis sagt jetzt, warum es nicht geht
		spieler.carry_fill = 0.5
		spieler._update_carry_visual()
		hud.set_krug(0.5, true)
		hud.set_hint("HINT_KRUG_NICHT_VOLL")
		await _bild("krug_gast_halb")
		spieler.carry_state = 0
		hud.set_krug(0.0, false)
		for pfad: String in DATEIEN:
			var sich := ProjectSettings.globalize_path(pfad + ".renderbackup")
			if _gab_es[pfad] and FileAccess.file_exists(pfad + ".renderbackup"):
				DirAccess.copy_absolute(sich, ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(sich)
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad))
		get_tree().quit()

	func _bild(name: String) -> void:
		await _frames(8)
		get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
		print("  gespeichert: ", name)

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame
