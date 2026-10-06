extends SceneTree
## Listet Knochen und Animationen: basis.glb (Ziel) und eine Mixamo-FBX (Quelle).
## godot --headless --path . --script res://tools/mixamo_info.gd -- "assets/animationen_mixamo/Idle.fbx"
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for pfad in ["res://assets/character/standard/basis.glb", "res://" + (args[0] if args.size() > 0 else "assets/animationen_mixamo/Idle.fbx")]:
		var ps := load(pfad) as PackedScene
		print("=== ", pfad, " geladen: ", ps != null)
		if ps == null:
			continue
		var w := ps.instantiate()
		for sk in w.find_children("*", "Skeleton3D", true, false):
			var s := sk as Skeleton3D
			var namen := []
			for i in s.get_bone_count():
				namen.append(s.get_bone_name(i))
			print("Skelett ", s.get_path(), " Knochen ", s.get_bone_count(), ": ", ", ".join(namen))
		for ap in w.find_children("*", "AnimationPlayer", true, false):
			var p := ap as AnimationPlayer
			for lib in p.get_animation_library_list():
				for a in p.get_animation_library(lib).get_animation_list():
					print("Anim '", lib, "/", a, "' ", p.get_animation_library(lib).get_animation(a).length, " s, Spuren ", p.get_animation_library(lib).get_animation(a).get_track_count())
		w.free()
	quit()
