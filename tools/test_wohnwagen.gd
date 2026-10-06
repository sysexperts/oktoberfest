extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Wohnwagen innen: hineingehen, Bett und Ausgang als Ziel, wieder hinaus.
##   godot --headless --path . res://tools/test_wohnwagen.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ok(name: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", name, info])
		if not ok:
			fehler += 1
	var fehler := 0

	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		gm.set_process(false)
		var sp: Node3D = get_tree().get_first_node_in_group("player") as Node3D
		_ok("Spieler da", sp != null)
		if sp == null:
			get_tree().quit(1)
			return
		var vorher := sp.global_position
		sp.wohnwagen_betreten()
		await get_tree().process_frame
		_ok("im Innenraum", sp.global_position.z > 590.0, str(sp.global_position))
		var bett := false
		var ausgang := false
		var laptop := false
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.has_method("wohnwagen_aktion"):
				bett = bett or str(n.get("art")) == "bett"
				ausgang = ausgang or str(n.get("art")) == "ausgang"
			if n is Computer and (n as Node3D).global_position.z > 590.0:
				laptop = true
		_ok("Bett, Ausgang und Laptop sind ansprechbar", bett and ausgang and laptop, "%s %s %s" % [bett, ausgang, laptop])
		sp.wohnwagen_verlassen()
		await get_tree().process_frame
		_ok("wieder draußen", sp.global_position.distance_to(vorher) < 0.1, str(sp.global_position))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN")
		get_tree().quit(fehler)
