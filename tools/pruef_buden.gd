extends Node
## Prüft die Aufstellung: misst die Grundfläche jeder Bude und jedes anderen
## Gegenstands auf dem Platz und meldet, was ineinandersteckt.
##   Godot --path . res://tools/pruef_buden.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	## Diese Knoten sind Boden, Wege oder Kulisse — nicht prüfen
	const EGAL := ["Altstadt", "Wege", "Ground", "Ground2", "Grenze", "Mauern", "Terrain",
		"Lichterketten", "Laternen", "Parking", "Strassen/Pflaster", "Strassen/Besucherwege",
		"Strassen/Stadtgrenze"]

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		Net.start_solo(true)
		for i in 60000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		for i in 40:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		var kirmes: Node = gm.get_node("Kirmes")
		var buden := []
		var dinge := []
		for n in kirmes.find_children("*", "Node3D", true, false):
			var pfad := String(kirmes.get_path_to(n))
			var egal := false
			for e: String in EGAL:
				if pfad == e or pfad.begins_with(e + "/"):
					egal = true
			if egal:
				continue
			var eltern_pfad := String(kirmes.get_path_to(n.get_parent())) if n.get_parent() else ""
			var ist_bude: bool = eltern_pfad in ["StaendeNord", "StaendeSued", "StaendeOst", "StaendeWest",
				"Strassen/Buden", "Strassen/Marktbuden"]
			var behaelter := pfad in ["StaendeNord", "StaendeSued", "StaendeOst", "StaendeWest", "Strassen", "Wohnwagenplatz", "Festbuero", "Kirmes"]
			var ist_ding := not behaelter and eltern_pfad == "." or eltern_pfad.begins_with("Strassen/Ausstattung/") \
				or eltern_pfad in ["Wohnwagenplatz", "Festbuero"]
			if not (ist_bude or ist_ding):
				continue
			var rechteck := _flaeche(n as Node3D)
			if rechteck.size.x <= 0.05:
				continue
			var eintrag := {"name": pfad, "r": rechteck}
			if ist_bude:
				buden.append(eintrag)
			else:
				dinge.append(eintrag)
		print("BUDEN: %d, andere Gegenstände: %d" % [buden.size(), dinge.size()])
		var schlimm := 0
		for i in buden.size():
			for j in range(i + 1, buden.size()):
				schlimm += _melde(buden[i], buden[j], 0.3)
		for b in buden:
			for d in dinge:
				schlimm += _melde(b, d, 0.3)
		print("PRUEFUNG FERTIG (%d Überschneidungen)" % schlimm)
		get_tree().quit()

	func _melde(a: Dictionary, b: Dictionary, mindest: float) -> int:
		var schnitt: Rect2 = (a.r as Rect2).intersection(b.r)
		if schnitt.size.x > mindest and schnitt.size.y > mindest:
			print("  ÜBERSCHNEIDUNG %-30s (%5.1f/%5.1f) ↔ %-28s (%5.1f/%5.1f)  %.1f x %.1f m" % [a.name, (a.r as Rect2).get_center().x, (a.r as Rect2).get_center().y, b.name, (b.r as Rect2).get_center().x, (b.r as Rect2).get_center().y, schnitt.size.x, schnitt.size.y])
			return 1
		return 0

	## Grundfläche (XZ) aus allen sichtbaren Meshes
	func _flaeche(n: Node3D) -> Rect2:
		var min_p := Vector2(1e9, 1e9)
		var max_p := Vector2(-1e9, -1e9)
		for m in n.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi.mesh == null or not mi.is_visible_in_tree():
				continue
			var ab := mi.global_transform * mi.get_aabb()
			min_p.x = minf(min_p.x, ab.position.x)
			min_p.y = minf(min_p.y, ab.position.z)
			max_p.x = maxf(max_p.x, ab.position.x + ab.size.x)
			max_p.y = maxf(max_p.y, ab.position.z + ab.size.z)
		if min_p.x > 1e8:
			return Rect2()
		return Rect2(min_p, max_p - min_p)
