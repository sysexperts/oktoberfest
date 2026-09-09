extends SceneTree
## Yardımcı araç: pakette hangi modelin dokusu eksik, hangisinde animasyon var?
## Kullanım: godot --headless --path . --script res://tools/check_kirmes_assets.gd

const ROOT := "res://assets/kirmes/Models"

func _init() -> void:
	var files: Array[String] = []
	_collect(ROOT, files)
	files.sort()
	var no_tex: Array[String] = []
	var anims: Array[String] = []
	for path in files:
		var ps := load(path) as PackedScene
		if ps == null:
			continue
		var root: Node = ps.instantiate()
		var has_tex := false
		var mats := 0
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			for i in m.mesh.get_surface_count():
				var mat := m.mesh.surface_get_material(i) as StandardMaterial3D
				if mat == null:
					continue
				mats += 1
				if mat.albedo_texture != null:
					has_tex = true
		if mats > 0 and not has_tex:
			no_tex.append(path.replace(ROOT + "/", ""))
		for ap in root.find_children("*", "AnimationPlayer", true, false):
			var names := (ap as AnimationPlayer).get_animation_list()
			if names.size() > 0:
				anims.append("%s -> %s" % [path.replace(ROOT + "/", ""), ", ".join(names)])
		root.free()
	print("\n=== OHNE TEXTUR (%d) ===" % no_tex.size())
	for s in no_tex:
		print("  " + s)
	print("\n=== MIT ANIMATION (%d) ===" % anims.size())
	for s in anims:
		print("  " + s)
	quit()

func _collect(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		var p := dir.path_join(n)
		if d.current_is_dir():
			_collect(p, out)
		elif n.ends_with(".fbx"):
			out.append(p)
		n = d.get_next()
	d.list_dir_end()
