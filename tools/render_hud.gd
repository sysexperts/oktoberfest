extends Node
## Startet ein Solo-Spiel und rendert das HUD in allen drei Sprachen, dazu
## das Hinweisfenster. Sichert Spielstand und Einstellungen vorher und stellt
## beide am Ende wieder her.
## Aufruf: godot --path . res://tools/render_hud.tscn --resolution 1280x720

const DATEIEN := ["user://oktoberfest_save.json", "user://einstellungen.cfg"]

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
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".renderbackup"))
		Net.start_solo(true)
		await _frames(60)
		var gm := get_tree().current_scene
		var hud: HUD = gm.get_node("HUD")
		# Spieler zum Zielmarker (Wiesenbüro) drehen, damit er im Bild ist
		var spieler: Node3D = gm.get_node("Players").get_child(0)
		var ziel: Node3D = gm.get_node("Zielmarker").ziel_suchen()
		if ziel:
			var d := ziel.global_position - spieler.global_position
			spieler.rotation.y = atan2(-d.x, -d.z)
			print("  Ziel: ", ziel.name, " in ", roundi(d.length()), " m")
		await _frames(20)
		await _bild("hud_marker")
		# Meldungsstapel und schwebender Betrag vor dem Spieler
		hud.melde("MSG_GOODS_ORDERED", [1, "GOODS_BEER", {"euro": 40}], 2)
		hud.melde("MSG_NO_MONEY", ["OFFER_TOILET", {"euro": 1800}], 1)
		hud.melde("MSG_EVENING")
		await _frames(25)
		# Betrag erst kurz vor dem Bild — die Szene rendert langsam, sonst ist er schon weg
		gm._net_betrag(spieler.global_position - spieler.global_transform.basis.z * 3.0, 23)
		await _bild("hud_meldungen")
		hud.set_money(-350)
		hud.set_popularity(62.0)
		hud.set_hygiene(34.0)
		hud.set_stock(12, 0)
		hud.set_day(3)
		hud.set_time(19.5, true)
		for lang in ["de", "en", "tr"]:
			Einstellungen.sprache = lang
			Einstellungen.anwenden()
			hud.set_quest(5, 11)
			hud.set_hint("HINT_TAP")
			await _bild("hud_%s" % lang)
		hud.set_time(-1.0)
		hud.show_popup("📦 Erst Ware einkaufen!\n\nDu hast kein Bier im Lager.")
		await _bild("hud_popup")
		hud.close_popup()

		# Wiesenbüro: Zelt gemietet, damit nicht alles gesperrt ist; Beispielbilanz
		gm.net_book_tent.rpc_id(1)
		gm.net_buy_table.rpc_id(1)
		await _frames(5)
		hud.set_money(Game.money)
		hud.set_report({"reason": 0, "day": 2, "earn": 1840, "tips": 60, "rent": 150, "wages": 100,
			"goods": 120, "interest": 0, "net": 1470, "served": 46, "missed": 3, "urin": 2, "complaints": 1, "left": 0})
		for lang in ["de", "tr"]:
			Einstellungen.sprache = lang
			Einstellungen.anwenden()
			hud.open_booking()
			var reiter: TabContainer = hud.get_node("%Wiesenbuero").get_node("%Reiter")
			for i in reiter.get_tab_count():
				reiter.current_tab = i
				await _bild("buero_%s_%d" % [lang, i])
			hud.close_booking()
		Einstellungen.sprache = "de"
		Einstellungen.anwenden()
		hud.open_computer()
		await _bild("computer_de")
		hud.close_computer()
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".renderbackup", echt)
				DirAccess.remove_absolute(echt + ".renderbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame

	func _bild(name: String) -> void:
		await _frames(6)
		get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
		print("  gespeichert: ", name)
