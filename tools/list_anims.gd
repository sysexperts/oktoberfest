extends SceneTree
## Listet die Animationen im Charaktermodell auf.
## godot --headless --path . --script res://tools/list_anims.gd

func _init() -> void:
	var ps: PackedScene = load("res://assets/character/character/bavarian_bean.glb")
	if ps == null:
		print("GLB nicht ladbar")
		quit()
		return
	var root: Node = ps.instantiate()
	for ap in root.find_children("*", "AnimationPlayer", true, false):
		var p := ap as AnimationPlayer
		print("AnimationPlayer: ", p.name)
		for lib_name in p.get_animation_library_list():
			var lib := p.get_animation_library(lib_name)
			for a in lib.get_animation_list():
				var anim := lib.get_animation(a)
				print("   '", lib_name, "/", a, "'  laenge=", anim.length)
		print("   -> get_animation_list(): ", p.get_animation_list())
	root.free()
	quit()
