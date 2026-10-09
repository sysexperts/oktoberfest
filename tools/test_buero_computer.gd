extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Punkt 5 der Testliste: Festbüro-Schreibtisch ist nur Einrichtung, bestellt wird am Computer,
## der Desktop-Zeiger bleibt sichtbar (auch bei einem Klick ins Leere).
##   godot --path . res://tools/test_buero_computer.tscn   (mit Fenster, wegen des Mauszeigers)
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
		var schreibtische := get_tree().get_nodes_in_group("interactable").filter(func(n): return n is OfficeDesk or n is BookingKiosk)
		_check("kein Schreibtisch/Kiosk ist ansprechbar", schreibtische.is_empty(), str(schreibtische.map(func(n): return n.get_path())))
		var computer := get_tree().get_nodes_in_group("interactable").filter(func(n): return n is Computer)
		_check("Computer im Büroraum ist ansprechbar", computer.size() >= 1, "%d" % computer.size())
		var hud := gm.get_node("HUD")
		hud.open_desktop()
		await _warten(1.0)
		_check("Desktop ist offen", hud.is_desktop_open(), "")
		_check("Zeiger sichtbar nach dem Öffnen", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, str(Input.mouse_mode))
		# Klick ins Leere (oben links, dort liegt nichts)
		for ev_pressed in [true, false]:
			var ev := InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = ev_pressed
			ev.position = Vector2(4, 4)
			ev.global_position = ev.position
			Input.parse_input_event(ev)
			await _warten(0.2)
		await _warten(0.5)
		_check("Desktop noch offen nach Klick ins Leere", hud.is_desktop_open(), "")
		_check("Zeiger sichtbar nach Klick ins Leere", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, str(Input.mouse_mode))
		var shop := hud.find_child("*Shop*", true, false)
		_check("Shop (Bestellung) liegt im Desktop", shop != null or hud.find_children("*", "", true, false).any(func(n): return String(n.name).to_lower().contains("shop")), "")
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
