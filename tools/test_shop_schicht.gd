extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Shop während der Schicht: Käufe gehen, die Shop-App am Desktop ist nicht gesperrt (Personal schon)
## godot --headless --path . res://tools/test_shop_schicht.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		await get_tree().create_timer(1.0).timeout
		gm._phase = gm.Phase.SHIFT
		gm._zelt_offen = true
		var ok := true
		var geld: int = 50000
		Game.add_money(geld - Game.money)
		print("buero_offen=%s shop_offen=%s" % [gm.buero_offen(), gm.shop_offen()])
		ok = ok and not gm.buero_offen() and gm.shop_offen()
		# Zelt mieten, Tisch, Künstler mitten in der Schicht
		gm.net_book_tent("Test")
		print("Zelt: Stufe %d" % gm._tent_stage)
		ok = ok and gm._tent_stage > 0
		var tische: int = gm._active_count
		gm.net_buy_table()
		print("Tische: %d -> %d" % [tische, gm._active_count])
		ok = ok and gm._active_count > tische
		gm.net_book_artist(1)
		print("Künstler: Stufe %d, Tage %d" % [gm._artist_tier, gm._artist_tage])
		ok = ok and gm._artist_tier == 1
		gm.net_cancel_artist()
		ok = ok and gm._artist_tier == 0
		var desk: Node = gm.get_node_or_null("HUD").get("_desktop") if gm.get_node_or_null("HUD") else null
		if desk:
			desk._aktualisieren()
			var shop_aus: bool = (desk.get_node("%IconShop") as Button).disabled
			var pers_aus: bool = (desk.get_node("%IconPersonal") as Button).disabled
			print("Desktop: Shop gesperrt=%s, Personal gesperrt=%s" % [shop_aus, pers_aus])
			ok = ok and not shop_aus and pers_aus
		else:
			print("Desktop nicht gefunden")
		print("ERGEBNIS: %s" % ("BESTANDEN" if ok else "FEHLGESCHLAGEN"))
		get_tree().quit()
