extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Sabotage mit Animation: E halten (Balken, Figur kniet), Effekt (Nebel, Bierstrahl, Funken, Staub) und Gäste, die rennen
## godot --path . res://tools/test_sab_anim.tscn --resolution 1280x720      (SHOT_DIR=build/sab für Bilder)
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var ok := true
	func _check(n: String, b: bool, info := "") -> void:
		print(("OK     " if b else "FEHLER ") + n + "  " + info)
		ok = ok and b
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _bild(name: String) -> void:
		var d := OS.get_environment("SHOT_DIR")
		if d != "":
			get_viewport().get_texture().get_image().save_png(d + "/sab_%s.png" % name)
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._story.kapitel = 3
		gm._phase = gm.Phase.SHIFT
		gm._zelt_offen = true
		gm._tarnung_stufe = 2
		gm._tarnung_an = true
		for w in ["fassbohrer", "zange", "stinkbombe", "juckpulver"]:
			gm._sab_inv[w] = 1
		gm._broadcast_meta()
		var sp: CharacterBody3D = gm._players_nodes.get(1)
		var zelt: Node3D = get_tree().get_first_node_in_group("huber_zelt")
		await _warten(1.0)
		# Für das Bild: Konrad und die Kameras weg, damit niemand erwischt
		for g in ["huber", "konrad_kamera"]:
			for n in get_tree().get_nodes_in_group(g):
				n.set_process(false)
				if n.has_method("sieht"):
					n.set_meta("sieht_aus", true)
		var kam := Camera3D.new()
		add_child(kam)
		var ziele := {}
		for z in get_tree().get_nodes_in_group("sab_ziel"):
			ziele[str(z.art)] = z
		_check("vier Sabotage-Stellen", ziele.size() == 4)
		for art in ["stink", "fass", "strom", "juck"]:
			var z: Node3D = ziele[art]
			# vor die Stelle stellen und hinschauen
			var vor := z.global_position + Vector3(0, 0, 1.6)
			sp.global_position = Vector3(vor.x, 0.1, vor.z)
			sp.look_at(Vector3(z.global_position.x, 1.2, z.global_position.z), Vector3.UP)
			sp._head.rotation.x = 0.0
			sp._schulterkamera = false
			await _warten(1.0)
			kam.current = false
			Input.action_press("interact")
			await _warten(0.4)
			_check("%s: Sabotage beginnt (Spieler kniet/steht still)" % art, sp.sab_aktiv and z._balken.visible, "Ziel=%s" % str(sp._current_target))
			kam.global_position = sp.global_position + Vector3(1.9, 1.6, 2.6)
			kam.look_at(sp.global_position.lerp(z.global_position, 0.5) + Vector3(0, 0.8, 0))
			kam.current = true
			await _warten(1.0)
			await _bild("%s_balken" % art)
			var fuell: float = z._balken_vorn.scale.x
			_check("%s: Balken füllt sich (%.2f)" % [art, fuell], fuell > 0.1 and fuell < 1.0)
			await _warten(4.0)
			Input.action_release("interact")
			await _warten(0.6)
			var teilchen: GPUParticles3D = z.get_node({"fass": "EffektFass", "strom": "EffektStrom", "stink": "EffektStink", "juck": "EffektJuck"}[art])
			_check("%s: Effekt läuft (oder lief)" % art, teilchen.emitting or art == "strom", "sab_tag=%s" % str(gm._sab_tag))
			_check("%s: Werkzeug verbraucht" % art, int(gm._sab_inv[gm.SAB_WERKZEUG[art]]) == 0)
			await _warten(1.2)
			await _bild("%s_effekt" % art)
			await _warten(3.0)
			await _bild("%s_spaeter" % art)
		# Gäste rennen: nach dem Erfolg sind einige im Zustand 1 oder 2
		var rennt := 0
		var draussen := 0
		for f in get_tree().get_nodes_in_group("huber_figuren") if false else zelt.find_children("*", "Node3D", true, false):
			if f.get("_flucht") != null and str(f.get("beruf")) == "":
				if int(f._flucht) == 1: rennt += 1
				if int(f._flucht) == 2: draussen += 1
		await _warten(6.0)
		var rennt2 := 0
		var draussen2 := 0
		for f in zelt.find_children("*", "Node3D", true, false):
			if f.get("_flucht") != null and str(f.get("beruf")) == "":
				if int(f._flucht) == 1: rennt2 += 1
				if int(f._flucht) == 2: draussen2 += 1
		_check("Gäste verlassen das Zelt (rennend %d, draußen %d)" % [rennt2, draussen2], rennt + draussen + rennt2 + draussen2 > 0)
		print("ERGEBNIS: %s" % ("BESTANDEN" if ok else "FEHLGESCHLAGEN"))
		get_tree().quit()
