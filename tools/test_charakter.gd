extends Node
## Test des Charakter-Creators: Look-Code (auch kaputte Eingaben), Bau der Figur und Einsetzen am
## Spieler. godot --headless --path . res://tools/test_charakter.tscn
const Look := preload("res://scripts/charakter_look.gd")

var _fehler := 0

func _pruefe(bedingung: bool, text: String) -> void:
	if not bedingung:
		_fehler += 1
		print("FEHLER: ", text)

func _ready() -> void:
	# Code hin und zurück
	var l := Look.zufall()
	var l2 := Look.aus_code(Look.zu_code(l))
	_pruefe(l == l2, "Look-Code hin und zurück gleich")
	# Kaputte und feindliche Eingaben ergeben den Standard-Look
	for schlecht: String in ["", "kein json", "[1,2]", "{\"hut\":\"gibtsnicht\",\"haut\":\"zzzzzzzzzzzzzzzz\"}", "x".repeat(1000)]:
		var d := Look.aus_code(schlecht)
		_pruefe(d["hut"] == "ohne" and Look.liste("hut").any(func(e: Dictionary) -> bool: return e["id"] == d["hut"]), "Fallback bei: " + schlecht.left(20))
		_pruefe(Color.html_is_valid(d["haut"]), "Hautfarbe gültig bei: " + schlecht.left(20))
	# Figur bauen: jede Kombination aus je einem Baustein muss laden
	var gebaut := 0
	for art: String in Look.ARTEN + Look.KLEIDER:
		for e: Dictionary in Look.liste(art):
			var k := Look.standard()
			k[art] = e["id"]
			var f := Look.bauen(k)
			add_child(f)
			Look.faerben(f, k)
			await get_tree().process_frame
			_pruefe(f.skelett != null, "Skelett da: %s/%s" % [art, e["id"]])
			if art in Look.KLEIDER:
				var n := f.skelett.get_node_or_null(art + "_farbe")
				_pruefe((n != null) == (e["szene"] != null), "Kleidung am Skelett %s/%s" % [art, e["id"]])
			var erwartet := 0
			for a2: String in Look.ARTEN:
				if Look.liste(a2).filter(func(x: Dictionary) -> bool: return x["id"] == k[a2])[0]["szene"] != null:
					erwartet += 1
			var halter := f.skelett.get_node_or_null("Zubehoer")
			var anzahl := halter.get_child_count() if halter else 0
			_pruefe(anzahl == erwartet, "Teile am Kopf %s/%s: %d statt %d" % [art, e["id"], anzahl, erwartet])
			f.queue_free()
			gebaut += 1
	print("Figuren gebaut: ", gebaut)
	# Am Spieler einsetzen
	var spieler: Node3D = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	spieler.name = "1"
	add_child(spieler)
	await get_tree().process_frame
	var vorher: Node = spieler.get_node("Model")
	spieler.look_setzen(Look.zu_code(l))
	await get_tree().process_frame
	var nachher: Node = spieler.get_node("Model")
	_pruefe(nachher != vorher and nachher is Figur, "Spieler hat neue Figur")
	_pruefe(spieler.look_code != "", "look_code gesetzt")
	# set_info darf den Look nicht überschreiben
	spieler.set_info("Test", 1, 3)
	await get_tree().process_frame
	_pruefe(spieler.get_node("Model") == nachher, "set_info lässt den Look in Ruhe")
	print("ERGEBNIS: ", "BESTANDEN" if _fehler == 0 else "FEHLER %d" % _fehler)
	get_tree().quit()
