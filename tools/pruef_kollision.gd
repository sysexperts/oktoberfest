extends SceneTree
## Zählt durch, was in der Karte Meshes hat, aber keine Kollision — damit man
## sieht, wo man noch hindurchlaufen kann.
## Aufruf: godot --headless --path . --script res://tools/pruef_kollision.gd

const KARTE := "res://scenes/main.tscn"
## Kleinkram ohne Kollision ist in Ordnung
const MIN_GROESSE := 0.35

func _init() -> void:
	var wurzel: Node = (load(KARTE) as PackedScene).instantiate()
	var ohne := {}
	var mit := {}
	for kind: Node in wurzel.get_children():
		_pruefen(kind, ohne, mit)
	print("--- mit Kollision")
	for name in mit:
		print("  %s (%d)" % [name, mit[name]])
	print("--- OHNE Kollision")
	for name in ohne:
		print("  %s (%d) %s" % [name, ohne[name]["n"], ohne[name]["groesse"]])
	wurzel.free()
	quit()

func _pruefen(knoten: Node, ohne: Dictionary, mit: Dictionary) -> void:
	if knoten is Node3D:
		var meshes: Array = knoten.find_children("*", "MeshInstance3D", true, false)
		if not meshes.is_empty():
			var formen: Array = knoten.find_children("*", "CollisionShape3D", true, false)
			var name := _art(knoten)
			if formen.is_empty():
				var kasten := _masse(knoten as Node3D, meshes)
				if maxf(kasten.size.x, kasten.size.z) >= MIN_GROESSE and kasten.size.y >= MIN_GROESSE:
					if not ohne.has(name):
						ohne[name] = {"n": 0, "groesse": "%.1f×%.1f×%.1f m" % [kasten.size.x, kasten.size.y, kasten.size.z]}
					ohne[name]["n"] += 1
			else:
				mit[name] = int(mit.get(name, 0)) + 1
			return   # nicht weiter hinein — der Knoten ist die Einheit
	for kind: Node in knoten.get_children():
		_pruefen(kind, ohne, mit)

func _art(knoten: Node) -> String:
	var pfad := knoten.scene_file_path
	return pfad.get_file() if pfad != "" else knoten.name

func _masse(wurzel: Node3D, meshes: Array) -> AABB:
	var gesamt := AABB()
	var erstes := true
	for mi: MeshInstance3D in meshes:
		if mi.mesh == null or not mi.visible:
			continue
		var t := Transform3D.IDENTITY
		var n: Node = mi
		while n != null and n != wurzel:
			if n is Node3D:
				t = (n as Node3D).transform * t
			n = n.get_parent()
		var kasten := t * mi.get_aabb()
		if erstes:
			gesamt = kasten
			erstes = false
		else:
			gesamt = gesamt.merge(kasten)
	return gesamt
