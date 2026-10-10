extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft die Lauf-Varianten des Spielers (rückwärts, Rennen rückwärts, Treppe, betrunken): welche Animation läuft?
## godot --headless --path . res://tools/test_lauf_anims.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var sp: CharacterBody3D = gm._players_nodes.get(1)
		sp.rotation.y = 0.0
		await get_tree().create_timer(1.0).timeout
		var faelle := [
			["vorwärts gehen", Vector3(0, 0, -3), 0, "gehen"],
			["rückwärts gehen", Vector3(0, 0, 3), 0, "rueck"],
			["vorwärts rennen", Vector3(0, 0, -7), 0, "rennen"],
			["rückwärts rennen", Vector3(0, 0, 7), 0, "rennen_rueck"],
			["Treppe hoch", Vector3(0, 2.5, -3), 0, "treppe"],
			["betrunken gehen", Vector3(0, 0, -3), 1, "bt_gehen"],
			["betrunken rückwärts", Vector3(0, 0, 3), 1, "bt_rueck"],
			["betrunken rennen", Vector3(0, 0, -7), 1, "bt_rennen"],
			["stehen", Vector3.ZERO, 0, "stehen"],
		]
		var ok := 0
		for f in faelle:
			sp._rausch_stufe = int(f[2])
			sp._steig_glatt = 0.0
			sp._cur_anim = ""
			for i in 30:
				sp.velocity = f[1]
				sp._update_animation(0.016)
			var clip: String = (sp._model as Figur).anim.current_animation
			var gut: bool = sp._cur_anim == f[3]
			ok += 1 if gut else 0
			print("%-22s -> %-14s (%s) %s" % [f[0], sp._cur_anim, clip, "OK" if gut else "FEHLER erwartet " + f[3]])
		print("ERGEBNIS: %s (%d/%d)" % ["BESTANDEN" if ok == faelle.size() else "FEHLGESCHLAGEN", ok, faelle.size()])
		get_tree().quit()
