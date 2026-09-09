extends SceneTree
## Yardımcı araç: assets/kirmes altındaki tüm .fbx modellerinin gerçek boyutunu
## (AABB) ölçer ve JSON olarak yazar. Katalog sahnesi bu ölçülerle kuruluyor.
## Kullanım: godot --headless --path . --script res://tools/scan_kirmes.gd

const ROOT := "res://assets/kirmes/Models"
const OUT := "res://tools/kirmes_sizes.json"

func _init() -> void:
	var files: Array[String] = []
	_collect(ROOT, files)
	files.sort()
	var data := {}
	for path in files:
		var ps := load(path) as PackedScene
		if ps == null:
			continue
		var root: Node = ps.instantiate()
		var aabb := AABB()
		var first := true
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			var t: Transform3D = m.transform
			var n: Node = m.get_parent()
			while n != null and n != root:
				if n is Node3D:
					t = (n as Node3D).transform * t
				n = n.get_parent()
			var box: AABB = t * m.mesh.get_aabb()
			if first:
				aabb = box
				first = false
			else:
				aabb = aabb.merge(box)
		data[path] = {
			"size": [aabb.size.x, aabb.size.y, aabb.size.z],
			"min": [aabb.position.x, aabb.position.y, aabb.position.z],
		}
		print("%-46s  X=%7.2f Y=%7.2f Z=%7.2f   minY=%7.2f" % [
			path.replace(ROOT + "/", ""), aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y])
		root.free()
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	print("\n%d Modelle -> %s" % [data.size(), OUT])
	quit()

func _collect(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var p := dir.path_join(name)
		if d.current_is_dir():
			_collect(p, out)
		elif name.ends_with(".fbx"):
			out.append(p)
		name = d.get_next()
	d.list_dir_end()
