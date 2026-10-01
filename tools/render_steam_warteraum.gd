extends Node
## Sichtprobe des Steam-Warteraums (scenes/ui/steam_warteraum.tscn) mit erfundenen
## Mitspielern und Freunden, ohne Steam. Bilder: tools/steam_warteraum.png und
## tools/steam_warteraum_wahl.png (nicht im Git).
##   godot --path . res://tools/render_steam_warteraum.tscn --resolution 1280x720

class Ersatz extends RefCounted:
	var lobby_id := 4711
	var lobby_code := "BREZN-57"
	var figuren := {1: 1, 2: 2}
	var welt := ""
	func lobby_wert(schluessel: String) -> String:
		return {"code_text": "BREZN-57", "welt": welt}.get(schluessel, "")
	func lobby_mitglieder() -> Array:
		return [
			{"id": 1, "name": "Serdar", "ich": true, "host": true, "figur": figuren.get(1, -1), "bereit": true},
			{"id": 2, "name": "Mehmet", "ich": false, "host": false, "figur": 2, "bereit": false},
			{"id": 3, "name": "Jana", "ich": false, "host": false, "figur": 7, "bereit": true},
		]
	func avatar_textur(id: int) -> Texture2D:
		if id == 3:
			return null
		var farben := {1: Color(0.35, 0.5, 0.7), 2: Color(0.62, 0.35, 0.48), 10: Color(0.7, 0.5, 0.35), 11: Color(0.35, 0.55, 0.7)}
		var bild := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		bild.fill(farben.get(id, Color(0.4, 0.4, 0.4)))
		return ImageTexture.create_from_image(bild)
	func freunde() -> Array:
		return [
			{"id": 11, "name": "Tom", "status": "spielt"},
			{"id": 10, "name": "Ayse", "status": "online"},
			{"id": 12, "name": "Luca", "status": "abwesend"},
		]
	func mitglied_setzen(schluessel: String, wert: String) -> void:
		if schluessel == "figur":
			figuren[1] = int(wert)
	func lobby_setzen(schluessel: String, wert: String) -> void:
		if schluessel == "welt":
			welt = wert
	func bin_lobby_host() -> bool:
		return true
	func lobby_verlassen() -> void:
		pass
	func freunde_einladen() -> void:
		pass
	func freund_einladen(_id: int) -> void:
		pass

func _ready() -> void:
	var raum := (load("res://scenes/ui/steam_warteraum.tscn") as PackedScene).instantiate()
	raum.quelle = Ersatz.new()
	add_child(raum)
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tools/steam_warteraum.png")
	raum.get_node("%Wahl").zeigen(0, {1: true, 2: true, 7: true})
	for i in 20:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tools/steam_warteraum_wahl.png")
	raum.get_node("%Wahl").schliessen()
	raum.get_node("%Welt").zeigen(2, 1)
	for i in 20:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tools/steam_warteraum_welt.png")
	print("RENDER FERTIG")
	get_tree().quit()
