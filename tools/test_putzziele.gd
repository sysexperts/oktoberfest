extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft die Teilziele von „Putze das Zelt" in der Aufgabenkarte: Planen, Dreck und
## Säcke mit Zählern. Startet ein neues Spiel, setzt Schritt 2, legt den Dreck aus und
## fotografiert die Karte (tools/putzziele.png). Sichert Spielstände vorher und
## stellt sie danach wieder her.
##   godot --path . res://tools/test_putzziele.tscn   (mit Fenster)

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".testbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".testbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".testbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".testbackup"))
		var ok := await _pruefen()
		_wiederherstellen()
		print("TEST ", "BESTANDEN" if ok else "FEHLGESCHLAGEN")
		get_tree().quit(0 if ok else 1)

	func _pruefen() -> bool:
		var gm := await Spielstart.starten(self, true, 2)
		if gm == null:
			return false
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._tent_stage = 1
		gm._quest_step = 2
		gm._dreck_verteilen()
		gm._broadcast_meta()
		await _frames(60)
		var hud: Node = gm.get_node("HUD")
		var zeilen := hud.get_node("%Teilziele")
		print("Teilziele sichtbar: ", zeilen.visible)
		for i in 3:
			print("  ", zeilen.get_child(i).get_node("Text").text)
		print("  ", hud.get_node("%MuellOrt").text)
		get_viewport().get_texture().get_image().save_png("res://tools/putzziele.png")
		# Eine Plane weg und einen Sack in die Tonne: Zähler müssen springen
		var erste := true
		for id in gm._mess_kind.keys():
			if int(gm._mess_kind[id]) >= Mess.DECKE and erste:
				erste = false
				gm._mess_kind.erase(id)
		gm._muell_erzeugt = 15
		gm._muell_entsorgt = 3
		await _frames(60)
		print("nach Änderung:")
		for i in 3:
			print("  ", zeilen.get_child(i).get_node("Text").text)
		get_viewport().get_texture().get_image().save_png("res://tools/putzziele2.png")
		return zeilen.visible

	func _frames(k: int) -> void:
		for i in k:
			await get_tree().process_frame

	func _wiederherstellen() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".testbackup", echt)
				DirAccess.remove_absolute(echt + ".testbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
