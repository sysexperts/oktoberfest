extends Node
## Einzelspieler: ist ein gespeicherter Look beim Spielstart am eigenen Spieler?
const Look := preload("res://scripts/charakter_look.gd")

func _ready() -> void:
	var gesichert := ""
	if FileAccess.file_exists(Look.DATEI):
		gesichert = FileAccess.get_file_as_string(Look.DATEI)
	var l := Look.standard()
	l["hut"] = "zylinder"
	l["bart"] = "vollbart"
	Look.speichern(l)
	Net.solo = true
	var spieler: Node3D = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	spieler.name = "1"
	add_child(spieler)
	for i in 6:
		await get_tree().process_frame
	var fehler := 0
	if spieler.look_code == "":
		fehler += 1
		print("FEHLER: look_code leer")
	var modell := spieler.get_node("Model")
	if not modell is Figur or (modell as Figur).skelett.get_node_or_null("Zubehoer") == null:
		fehler += 1
		print("FEHLER: Modell ist nicht der Creator-Charakter")
	Net.solo = false
	DirAccess.remove_absolute(Look.DATEI)
	if gesichert != "":
		var f := FileAccess.open(Look.DATEI, FileAccess.WRITE)
		f.store_string(gesichert)
	print("ERGEBNIS: ", "BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
	get_tree().quit()
