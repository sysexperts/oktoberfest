extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Ausbau-App (build/desktop_ausbau.png).
## godot --path . res://tools/shot_rezeptbuch.tscn --resolution 1600x900

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
		story.kapitel_setzen(3)
		hud._zustand["schulden"] = 5000
		hud.open_desktop()
		await _bild("start")
		var d: Control = hud.get("_desktop")
		story.kapitel_setzen(5)
		await get_tree().create_timer(0.5).timeout
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._ausbau = ["vip", "handel"]
		gm._day = 12
		gm._broadcast_meta()
		d = hud.get("_desktop")
		d.app_oeffnen("ausbau")
		await get_tree().create_timer(0.6).timeout
		await _bild("ausbau")
		get_tree().quit()
		return
		gm.konto_verlauf = [
			{"day": 1, "served": 38, "missed": 1, "complaints": 0, "urin": 0, "earn": 840, "rent": 300, "wages": 120, "goods": 260, "interest": 0, "loan": 0, "ziel": 140, "wette": 0, "bank": 0},
			{"day": 2, "served": 22, "missed": 6, "complaints": 1, "urin": 2, "earn": 410, "rent": 300, "wages": 120, "goods": 210, "interest": 0, "loan": 0, "ziel": 0, "wette": -100, "bank": 0},
			{"day": 3, "served": 52, "missed": 0, "complaints": 0, "urin": 0, "earn": 1260, "rent": 300, "wages": 180, "goods": 300, "interest": 0, "loan": 0, "ziel": 180, "wette": 0, "bank": 0},
		]
		d.app_oeffnen("bank")
		await _bild("bank")
		hud.set_popularity(72.0)
		d.app_oeffnen("social")
		await _bild("social")
		d.app_oeffnen("kalender")
		await _bild("kalender")
		d.app_oeffnen("wetter")
		await _bild("wetter")
		d.app_oeffnen("shop")
		await _bild("shop")
		d.app_oeffnen("personal")
		await _bild("personal")
		d.app_oeffnen("bilanz")
		await _bild("bilanz")
		d.app_oeffnen("bierpreis")
		await _bild("bierpreis")
		for f in d.get_node("%Fenster").get_children():
			print("FENSTER ", f.app, " ", f.size, " ", f.scale, " ", f.get_combined_minimum_size(), " inhalt ", f.get_node("%Inhalt").get_child(0).get_combined_minimum_size(), " ", f.get_node("%Inhalt").get_child(0).get_child(1).get_combined_minimum_size() if f.app == "bierpreis" else "")
		print("FERTIG")
		get_tree().quit()
