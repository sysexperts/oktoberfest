extends Node
## Hauptmenü → Knopf „Charakter“ → Creator → Fertig: speichert der Creator, schließt er sich?
## Läuft als Szene, damit die Autoloads da sind.
const Look := preload("res://scripts/charakter_look.gd")

func _ready() -> void:
	var gesichert := ""
	if FileAccess.file_exists(Look.DATEI):
		gesichert = FileAccess.get_file_as_string(Look.DATEI)
		DirAccess.remove_absolute(Look.DATEI)
	var fehler := 0
	var menue: Control = load("res://scenes/ui/hauptmenue.tscn").instantiate()
	add_child(menue)
	for i in 5:
		await get_tree().process_frame
	var knopf := menue.get_node_or_null("%Charakter") as Button
	if knopf == null:
		fehler += 1
		print("FEHLER: Knopf Charakter fehlt")
	else:
		knopf.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		var cc := menue.get_node_or_null("CharakterCreator")
		if cc == null or not cc.visible:
			fehler += 1
			print("FEHLER: Creator öffnet sich nicht")
		else:
			cc.get_node("%Hut").select(3)
			cc.get_node("%Hut").item_selected.emit(3)
			await get_tree().process_frame
			cc.get_node("%Fertig").pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
			if not Look.gespeichert():
				fehler += 1
				print("FEHLER: nichts gespeichert")
			elif Look.laden()["hut"] != Look.liste("hut")[3]["id"]:
				fehler += 1
				print("FEHLER: falscher Hut gespeichert: ", Look.laden()["hut"])
			if is_instance_valid(cc) and not cc.is_queued_for_deletion():
				fehler += 1
				print("FEHLER: Creator bleibt offen")
	DirAccess.remove_absolute(Look.DATEI)
	if gesichert != "":
		var f := FileAccess.open(Look.DATEI, FileAccess.WRITE)
		f.store_string(gesichert)
	print("ERGEBNIS: ", "BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
	get_tree().quit()
