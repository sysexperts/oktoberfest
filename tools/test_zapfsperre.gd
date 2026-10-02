extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft, dass bei leerem Bierlager gar nicht erst gezapft wird — und mit Bestand schon.
## Startet ein neues Spiel, stellt den Spieler an ein Fass, hält E und liest den Füllstand.
## Sichert Spielstände und Einstellungen vorher und stellt sie danach wieder her.
##   godot --path . res://tools/test_zapfsperre.tscn   (mit Fenster)

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
		var sp: Node3D = gm._players_nodes.get(1)
		var fass: Node3D = null
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is KegStation and (n as KegStation).beer_type != 5:
				fass = n
				break
		if fass == null:
			print("kein Fass gefunden")
			return false
		print("Fass: ", fass.name, " Sorte ", fass.beer_type)
		sp.global_position = fass.global_position + Vector3(0, 0.1, 1.6)
		sp.look_at(fass.global_position + Vector3(0, 1.0, 0))
		sp.rotation.x = 0
		await _frames(30)
		print("Ziel: ", sp._current_target)
		# 1. Lager leer
		gm._stock[1] = 0
		sp.carry_state = 1
		sp.carry_fill = 0.0
		sp.carry_type = 0
		print("Hinweis bei leerem Lager: ", sp._hint_for(sp._current_target))
		var f0 := await _halten(sp)
		print("Füllstand bei leerem Lager: %.2f" % f0)
		# 2. Lager voll
		gm._stock[1] = 5
		sp.carry_state = 1
		sp.carry_fill = 0.0
		print("Hinweis mit Lager: ", sp._hint_for(sp._current_target))
		var f1 := await _halten(sp)
		print("Füllstand mit Lager: %.2f" % f1)
		return f0 == 0.0 and f1 > 0.0

	func _halten(sp: Node) -> float:
		Input.action_press("interact")
		await _frames(25)
		Input.action_release("interact")
		await _frames(3)
		return sp.carry_fill

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
