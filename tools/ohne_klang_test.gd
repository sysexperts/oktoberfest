extends Node
## Stellt die alte .exe nach: das Autoload Klang gibt es nicht. Prueft, dass
## Menue und Einstellungen trotzdem laden und ihre Knoepfe verbunden sind —
## genau das ging in v196 kaputt, weil das Skript den Autoload-Namen direkt nutzte.
func _ready() -> void:
	var klang := get_node_or_null("/root/Klang")
	if klang != null:
		klang.name = "KlangWeg"   # Pfad /root/Klang existiert damit nicht mehr
	var menue: Control = load("res://scenes/ui/hauptmenue.tscn").instantiate()
	add_child(menue)
	await _warte(1.0)
	for pfad in ["Mitte/Hauptspalte/Weiterspielen", "Mitte/Hauptspalte/Reihe1/Laden",
			"Ecke/Einstellungen", "Ecke/Beenden"]:
		var k: Button = menue.get_node(pfad)
		print("%-38s verbunden=%d" % [pfad, k.pressed.get_connections().size()])
	var e: CanvasLayer = load("res://scenes/ui/einstellungen.tscn").instantiate()
	add_child(e)
	await _warte(0.6)
	var zu: Button = e.get_node("Rahmen/Spalte/Unten/Schliessen")
	print("Einstellungen geladen, Schliessen verbunden=%d" % zu.pressed.get_connections().size())
	get_tree().quit()

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
