extends Node
## Bilder zur Bierlieferung als Fass: geliefertes Fass am Boden, Ich-Sicht mit
## Fass, Mitspieler mit Fass zwischen den Händen (von vorn und seitlich).
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/render_fass.tscn --resolution 1600x900
## Umgebung: VORSCHAU = Zielpfad mit %s (z. B. C:/tmp/fass_%s.png)

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg", "user://karte.json"]

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".fassbackup"))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(60)
		var gm := get_tree().current_scene
		gm.set_process(false)
		gm.get_node("HUD").visible = false
		var ich: Node3D = gm._players_nodes[1]
		ich.set_physics_process(false)
		var ziel := OS.get_environment("VORSCHAU")
		var basis := ich.global_position

		# 1) Geliefertes Fass und ein Karton am Boden
		gm._add_package(9001, basis + Vector3(0.0, 0.0, -2.2), 1, 10)
		gm._add_package(9002, basis + Vector3(1.1, 0.0, -2.4), 2, 10)
		ich.get_node("Head").rotation.x = deg_to_rad(-25.0)
		await _frames(40)
		get_viewport().get_texture().get_image().save_png(ziel % "1_geliefert")
		gm._remove_package(9001)
		gm._remove_package(9002)

		# 2) Ich-Sicht: Fass tragen
		ich.carry_state = 3
		ich.carry_pkg_kind = 1
		ich.carry_pkg_amount = 10
		ich._update_carry_visual()
		ich.get_node("Head").rotation.x = deg_to_rad(-5.0)
		await _frames(30)
		get_viewport().get_texture().get_image().save_png(ziel % "2_pov")

		# 3) Mitspieler mit Fass — von vorn und schräg
		gm._add_player(2, 1)
		await _frames(10)
		var mit: Node3D = gm._players_nodes[2]
		mit.set_physics_process(false)
		mit.carry_state = 3
		mit.carry_pkg_kind = 1
		mit._update_carry_visual()
		ich.carry_state = 0
		ich._update_carry_visual()
		var vorn := -ich.global_transform.basis.z
		mit.global_position = ich.global_position + vorn * 2.0
		mit.look_at(ich.global_position, Vector3.UP)
		mit.rotation.x = 0.0
		mit.rotation.z = 0.0
		ich.get_node("Head").rotation.x = deg_to_rad(-8.0)
		await _frames(30)
		get_viewport().get_texture().get_image().save_png(ziel % "3_mitspieler_vorn")
		mit.rotate_y(deg_to_rad(80.0))
		await _frames(20)
		get_viewport().get_texture().get_image().save_png(ziel % "4_mitspieler_seite")
		# Beim Gehen: Laufanimation mit Tragehaltung
		var figur := mit.get_node("Model") as Figur
		if figur:
			figur.gehen(1.0)
		# Drei Momente aus dem Gehen — Fass und Hände sollen zusammen wippen
		for k in 3:
			await _frames(9)
			get_viewport().get_texture().get_image().save_png(ziel % ("5_mitspieler_gehen_%d" % (k + 1)))

		# Abgeladene Lieferung: Fässer und Kisten im Raster
		gm._players_nodes.erase(2)
		mit.queue_free()
		gm._van_cargo = [{"kind": 1, "packs": 6}, {"kind": 2, "packs": 3}]
		gm._drop_cargo()
		ich.global_position = gm.DROP_POINT + Vector3(0, 0, -4.0)
		ich.look_at(gm.DROP_POINT, Vector3.UP)
		ich.rotation.x = 0.0
		ich.get_node("Head").rotation.x = deg_to_rad(-28.0)
		await _frames(30)
		get_viewport().get_texture().get_image().save_png(ziel % "6_abgeladen")
		# Regal voller Fässer
		var regal: Node3D = null
		for n in gm.find_children("*", "Node3D", true, false):
			if n.has_method("set_stock"):
				regal = n
				break
		if regal:
			regal.set_stock(60, 60)
			ich.global_position = regal.global_position - regal.global_transform.basis.z * 2.2
			ich.look_at(regal.global_position + Vector3(0, 1.0, 0), Vector3.UP)
			ich.rotation.x = 0.0
			ich.get_node("Head").rotation.x = deg_to_rad(-10.0)
			await _frames(30)
			get_viewport().get_texture().get_image().save_png(ziel % "7_regal")

		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".fassbackup", echt)
				DirAccess.remove_absolute(echt + ".fassbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
