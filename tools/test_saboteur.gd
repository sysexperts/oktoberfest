extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Saboteur prüfen: losschicken, erwischen (Geld), nochmal losschicken und ankommen lassen (Leck).
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		seed(3)
		gm._saboteur_losschicken()
		await _warten(4.0)
		var s = get_tree().get_first_node_in_group("saboteur")
		_check("Saboteur läuft", s != null and s.ist_saboteur(), str(s.global_position) if s else "")
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = s.global_position + Vector3(0, 0.1, 2)
		sp.look_at(s.global_position + Vector3(0, 0.1, 0), Vector3.UP)
		await _warten(0.3)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/saboteur.png")
		_check("Hinweis", sp._hint_for(s) == "HINT_SABOTEUR", sp._hint_for(s))
		var geld: int = Game.money
		gm.net_saboteur_fangen()
		_check("Erwischt: Geld", Game.money > geld and gm._saboteur.is_empty(), "%d → %d" % [geld, Game.money])
		gm._saboteur = {}
		gm._saboteur_losschicken()
		gm._saboteur.art = "fass"
		for i in 2000:
			gm._saboteur_schicht(0.05)
		_check("Angekommen: Leck", gm._mess_kind.values().has(Mess.SABOTAGE), "")
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
