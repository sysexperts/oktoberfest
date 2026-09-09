extends SceneTree
const ROOT := "res://assets/kirmes/Models"
func _init() -> void:
	var files: Array[String] = []
	_collect(ROOT, files); files.sort()
	var per_dir := {}
	for path in files:
		var ps := load(path) as PackedScene
		if ps == null: continue
		var root: Node = ps.instantiate()
		var used := {}
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null: continue
			for i in m.mesh.get_surface_count():
				var mat := m.mesh.surface_get_material(i) as StandardMaterial3D
				if mat and mat.albedo_texture:
					used[mat.albedo_texture.resource_path.get_file()] = true
		var d := path.get_base_dir().replace(ROOT + "/", "")
		if not per_dir.has(d): per_dir[d] = {}
		for k in used: per_dir[d][k] = true
		root.free()
	for d in per_dir:
		print("%-28s %s" % [d, ", ".join(per_dir[d].keys())])
	quit()
func _collect(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null: return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		var p := dir.path_join(n)
		if d.current_is_dir(): _collect(p, out)
		elif n.ends_with(".fbx"): out.append(p)
		n = d.get_next()
	d.list_dir_end()
