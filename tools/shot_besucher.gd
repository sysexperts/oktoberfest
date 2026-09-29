extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Besucher auf der Kirmes nach einer Weile Laufen: Schrägsicht und Draufsicht
## → SHOT_DIR/besucher_schraeg.png, besucher_oben.png. Druckt Netzgröße.

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	func _ready() -> void:
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		var menge := gm.get_node("Crowd")
		menge.set_density(1.0)
		for i in 900:
			await get_tree().process_frame
		menge.set_density(1.0)
		print("Wegpunkte: ", menge._points.size(), "  Besucher: ", menge._visitors.size())
		var ohne := 0
		for n in menge._nachbarn:
			if n.is_empty():
				ohne += 1
		print("Punkte ohne Nachbarn: ", ohne)
		var innen := 0
		for q: Vector3 in menge._points:
			if absf(q.x) < 22 and q.z > -22 and q.z < 20:
				innen += 1
		var zellen := 0
		for x in range(-22, 22):
			for z in range(-22, 20):
				if menge._gepflastert(Vector2(x, z)):
					zellen += 1
		var leute := 0
		for v in menge._visitors:
			if absf(v.position.x) < 22 and v.position.z > -22 and v.position.z < 20:
				leute += 1
		print("Innen: Punkte ", innen, "  Pflasterzellen ", zellen, "  Besucher ", leute)
		gm.get_node("HUD").visible = false
		var cam := Camera3D.new()
		gm.add_child(cam)
		cam.current = true
		cam.global_position = Vector3(-20, 22, 38)
		cam.look_at(Vector3(-5, 0, 10))
		for i in 5:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/besucher_schraeg.png")
		cam.global_position = Vector3(0, 90, -5)
		cam.rotation = Vector3(-PI / 2, 0, 0)
		cam.fov = 70
		for i in 5:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/besucher_oben.png")
		get_tree().quit()
