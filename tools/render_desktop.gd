extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Desktop-Bilder: Startseite, E-Mail und Quests, Startmenü, Shop (build/desktop_*.png).
## godot --path . res://tools/render_desktop.tscn --resolution 1600x900

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _bild(name: String) -> void:
		await get_tree().create_timer(0.6).timeout
		get_viewport().get_texture().get_image().save_png("res://build/desktop_%s.png" % name)

	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		gm.set_process(false)
		var story: Node = gm.get_node("Story")
		story.aktiv = true
		story.pruefen({"zelt_stufe": 1}, 1)
		story.ereignis("horst_zusage")
		story.pruefen({"zelt_stufe": 1, "zelt_sauber": true, "tische": 2}, 1)
		story.post_senden("M1-02")
		story.post_senden("M2-01")
		story.post_senden("M1-03")
		var hud: Node = gm.get_node("HUD")
		hud.open_desktop()
		await _bild("start")
		var d: Control = hud.get("_desktop")
		d.get_node("%StartKnopf").button_pressed = true
		await _bild("startmenue")
		d.get_node("%StartKnopf").button_pressed = false
		d.app_oeffnen("mail")
		d.get_node("%Fenster").get_child(0).get_node("%Inhalt").get_child(0).call("_waehlen", 1)
		d.app_oeffnen("quests")
		await _bild("fenster")
		d.app_oeffnen("shop")
		await _bild("shop")
		print("FERTIG")
		get_tree().quit()
