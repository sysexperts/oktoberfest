extends Node
## Prüft: vom Zelt aus lässt sich nichts im Braukeller darunter bedienen,
## im Keller nichts im Zelt darüber. Aufruf: godot --headless --path . res://tools/test_keller_trennung.tscn
const Spielstart := preload("res://tools/spielstart.gd")
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var _fehler := 0
	func _ready() -> void:
		var gm = await Spielstart.starten(self)
		if gm == null:
			return
		for i in 30: await get_tree().process_frame
		var ich: Node3D = gm._players_nodes[1]
		ich.set_physics_process(false)
		var geraete: Array = []
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is Node3D and (n as Node3D).global_position.y < -1.5:
				geraete.append(n)
		_pruefe("Kellergeräte gefunden", geraete.size() > 0, str(geraete.size()))
		for g: Node3D in geraete:
			# genau darüber im Zelt stehen und auf das Gerät schauen
			ich.global_position = Vector3(g.global_position.x, 0.1, g.global_position.z + 0.8)
			ich.look_at(Vector3(g.global_position.x, 0.1, g.global_position.z), Vector3.UP)
			ich._update_target()
			_pruefe("oben nicht erreichbar: " + str(g.name), ich._current_target != g, "")
			# unten davor stehen: erreichbar
			ich.global_position = Vector3(g.global_position.x, g.global_position.y, g.global_position.z + 0.8)
			ich._update_target()
			var oben_ziel: Node = ich._current_target
			_pruefe("unten kein Zeltgerät: " + str(g.name), oben_ziel == null or (oben_ziel as Node3D).global_position.y < -1.2, str(oben_ziel))
		print("ERGEBNIS: %s (%d Fehler)" % ["BESTANDEN" if _fehler == 0 else "FEHLGESCHLAGEN", _fehler])
		get_tree().quit()
	func _pruefe(was: String, ok: bool, info: String) -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", was, info])
		if not ok:
			_fehler += 1
