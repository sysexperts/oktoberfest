extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Figuren := preload("res://scripts/figuren.gd")
## Verkleidung an eigenen Figuren (rothaarige Frau, rothaariger Mann, Blonder) ohne, mit Mantel, mit Komplettset,
## daneben Gustav; dazu der Kleiderschrank im Wohnwagen → SHOT_DIR/tarnung_*.png
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1
	func _bild(name: String, von: Vector3, nach: Vector3) -> void:
		var k := Camera3D.new()
		get_tree().current_scene.add_child(k)
		k.fov = 50.0
		k.global_position = von
		k.look_at(nach)
		k.current = true
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/tarnung_%s.png" % name)
		k.queue_free()
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		await get_tree().create_timer(2.0).timeout
		var wurzel := Node3D.new()
		gm.add_child(wurzel)
		var basisort := Vector3(0, 0.1, 22)
		var Look = Figuren.Look
		var x := -4.2
		var figuren := []
		for g in ["w", "m"]:
			var l: Dictionary = Look.standard(g)
			l["haar"] = Color(0.78, 0.26, 0.1).to_html(false)
			l["haut"] = Look.HAUTFARBEN[2].to_html(false)
			l = Look.pruefen(l)
			for stufe in [0, 1, 2]:
				var t: Dictionary = Figuren.tarnung(l, stufe)
				var f: Node3D = Look.bauen(t)
				wurzel.add_child(f)
				Look.faerben(f, t)
				f.global_position = basisort + Vector3(x, 0, 0)
				f.rotation.y = 0.0
				figuren.append(f)
				x += 1.4
		var gl: Dictionary = Figuren.look_gustav()
		var gf: Node3D = Look.bauen(gl)
		wurzel.add_child(gf)
		Look.faerben(gf, gl)
		gf.global_position = basisort + Vector3(x + 0.8, 0, 0)
		gf.rotation.y = 0.0
		await get_tree().create_timer(1.0).timeout
		await _bild("reihe", basisort + Vector3(0.4, 1.4, 6.5), basisort + Vector3(0.4, 1.0, 0))
		await _bild("frau", basisort + Vector3(-2.8, 1.35, 4.2), basisort + Vector3(-2.8, 1.0, 0))
		await _bild("mann", basisort + Vector3(1.4, 1.35, 4.2), basisort + Vector3(1.4, 1.0, 0))
		await _bild("nah_mann", basisort + Vector3(2.8, 1.38, 1.1), basisort + Vector3(2.8, 1.3, 0))
		await _bild("nah_frau", basisort + Vector3(-1.4, 1.38, 1.1), basisort + Vector3(-1.4, 1.3, 0))
		await _bild("nah_seite", basisort + Vector3(2.8 + 0.9, 1.34, 0.8), basisort + Vector3(2.8, 1.3, 0))
		# Kleiderschrank im Wohnwagen
		var sp: Node3D = gm._players_nodes.get(1)
		var wagen: Node3D = null
		for c in get_tree().get_nodes_in_group("interactable"):
			if c is Caravan:
				wagen = c
				break
		sp.wohnwagen_betreten(wagen)
		await get_tree().create_timer(1.5).timeout
		var schrank: Node3D = null
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.get_script() != null and n.get_script().resource_path.ends_with("wohnwagen_ding.gd") and n.art == "kleiderschrank":
				schrank = n
		_check("Kleiderschrank im Wohnwagen ist ansprechbar", schrank != null, "")
		if schrank:
			await _bild("schrank", schrank.global_position + Vector3(-1.4, 1.5, -1.6), schrank.global_position + Vector3(0, 1.0, 0))
			_check("ohne Verkleidung: Hinweis 'noch keine Verkleidung'", schrank.hinweis_text(true) == "HINT_WAGEN_SCHRANK_LEER", schrank.hinweis_text(true))
			Game.money = 2000
			var story: Node = gm.get_node("Story")
			story.kapitel_setzen(3)
			gm.net_sab_kauf("komplett")
			await get_tree().create_timer(1.0).timeout
			_check("gekauft: Tarnung an, Hinweis 'ausziehen'", gm._tarnung_an and schrank.hinweis_text(true) == "HINT_WAGEN_UMZIEHEN_AUS", schrank.hinweis_text(true))
			schrank.wohnwagen_aktion(sp)
			await get_tree().create_timer(1.0).timeout
			_check("Schrank: Verkleidung ausgezogen", not gm._tarnung_an and schrank.hinweis_text(true) == "HINT_WAGEN_UMZIEHEN_AN", "an=%s" % str(gm._tarnung_an))
			schrank.wohnwagen_aktion(sp)
			await get_tree().create_timer(1.0).timeout
			_check("Schrank: wieder angezogen", gm._tarnung_an, "")
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
