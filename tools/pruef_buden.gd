extends Node
## Prüft die Aufstellung aller Buden: misst die Grundfläche jeder Bude aus den
## sichtbaren Meshes und meldet Überschneidungen und zu enge Nachbarn.
##   Godot --path . res://tools/pruef_buden.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
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
		for n in kirmes.find_children("*", "Node3D", true, false):
			var pfad := String(kirmes.get_path_to(n))
			if pfad.begins_with("Altstadt"):
				continue
			var eltern := n.get_parent()
			if eltern == null:
				continue
			var eltern_pfad := String(kirmes.get_path_to(eltern))
			if not (eltern_pfad in ["StaendeNord", "StaendeSued", "StaendeOst", "StaendeWest", "Strassen/Buden", "Strassen/Marktbuden"]):
				continue
			var rechteck := _flaeche(n as Node3D)
			if rechteck.size.x <= 0.0:
				continue
			buden.append({"name": pfad, "r": rechteck, "pos": (n as Node3D).global_position})
		buden.sort_custom(func(a, b): return String(a.name) < String(b.name))
		print("BUDEN: %d" % buden.size())
		for b in buden:
			var r: Rect2 = b.r
			print("  %-34s Mitte %6.1f/%6.1f  Größe %4.1f x %4.1f" % [b.name, b.pos.x, b.pos.z, r.size.x, r.size.y])
		var schlimm := 0
		for i in buden.size():
			for j in range(i + 1, buden.size()):
				var a: Rect2 = buden[i].r
				var b: Rect2 = buden[j].r
				var schnitt := a.intersection(b)
				if schnitt.size.x > 0.05 and schnitt.size.y > 0.05:
					schlimm += 1
					print("  ÜBERLAPPUNG %s ↔ %s: %.1f x %.1f m" % [buden[i].name, buden[j].name, schnitt.size.x, schnitt.size.y])
				else:
					var abstand := _abstand(a, b)
					if abstand < 0.6:
						print("  ENG        %s ↔ %s: %.2f m" % [buden[i].name, buden[j].name, abstand])
		print("PRUEFUNG FERTIG (%d Überlappungen)" % schlimm)
		get_tree().quit()

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

	func _abstand(a: Rect2, b: Rect2) -> float:
		var dx := maxf(maxf(a.position.x - (b.position.x + b.size.x), b.position.x - (a.position.x + a.size.x)), 0.0)
		var dz := maxf(maxf(a.position.y - (b.position.y + b.size.y), b.position.y - (a.position.y + a.size.y)), 0.0)
		return sqrt(dx * dx + dz * dz)
