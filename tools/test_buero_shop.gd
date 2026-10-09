extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Die Shop-App am Computer im Büro hat alle Reiter, die man zum Einkaufen braucht (Zelt, Lizenzen, Künstler,
## Ware = Bier, Deko); im Tutorial-Schritt „Bier bestellen“ öffnet sie direkt auf „Ware“.
##   godot --path . res://tools/test_buero_shop.tscn   (mit Fenster)
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		await _warten(2.0)
		var hud := gm.get_node("HUD")
		var buero: Control = hud.get("_buero")
		# Tutorial-Schritt 4: Bier bestellen
		buero.tutorial_schritt(4)
		hud.open_desktop()
		await _warten(1.0)
		var d: Control = hud.get("_desktop")
		d.app_oeffnen("shop")
		await _warten(1.0)
		var reiter: TabContainer = buero.get_node("%Reiter")
		var nav: Array = buero._nav_knoepfe()
		var sichtbar := []
		for i in nav.size():
			if (nav[i] as Control).visible:
				sichtbar.append(i)
		_check("Shop zeigt Zelt, Lizenzen, Künstler, Ware, Deko", sichtbar == [0, 1, 3, 4, 7], str(sichtbar))
		_check("Tutorial 'Bier bestellen': Fenster steht auf Ware", reiter.current_tab == 4, "Reiter %d" % reiter.current_tab)
		var bier := buero.find_child("Bier", true, false)
		_check("Bier-Zeile ist im Fenster", bier != null, "")
		# ohne Tutorial: Shop beginnt beim Zelt
		buero.tutorial_schritt(-1)
		gm.get_node("Story").kapitel_setzen(2)   # Personal gibt es erst ab Kapitel 2
		await _warten(0.5)
		d.app_oeffnen("personal")
		await _warten(0.5)
		var nav2: Array = buero._nav_knoepfe()
		var s2 := []
		for i in nav2.size():
			if (nav2[i] as Control).visible:
				s2.append(i)
		_check("Personal-App zeigt nur Personal", s2 == [2], str(s2))
		d.app_oeffnen("shop")
		await _warten(0.5)
		_check("Shop ohne Tutorial beginnt beim Zelt", reiter.current_tab == 0, "Reiter %d" % reiter.current_tab)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
