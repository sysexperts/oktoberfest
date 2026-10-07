extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Horsts Route zur Wohnwagengasse von oben (build/horst_route.png), Weg gelb, Ziel rot.
##   godot --path . res://tools/shot_horst_route.tscn --resolution 1600x1000

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var st := gm.get_node("Kirmes/Rundgang/1_Wohnwagen")
		var pts: Array[Vector3] = [Vector3(37.3, 0, 20.3)]
		for m in st.get_children():
			if m is Marker3D:
				pts.append((m as Marker3D).global_position)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1, 0.9, 0.1)
		for i in pts.size() - 1:
			var a := pts[i] + Vector3(0, 6, 0)
			var b := pts[i + 1] + Vector3(0, 6, 0)
			var seg := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.9, 0.3, a.distance_to(b))
			seg.mesh = box
			seg.material_override = mat
			gm.add_child(seg)
			seg.global_position = (a + b) / 2.0
			seg.look_at(b, Vector3.UP)
		var rot := StandardMaterial3D.new()
		rot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rot.albedo_color = Color(1, 0.1, 0.1)
		for i in pts.size():
			var k := MeshInstance3D.new()
			var s := SphereMesh.new()
			s.radius = 1.4 if i == pts.size() - 1 else 0.8
			s.height = s.radius * 2.0
			k.mesh = s
			k.material_override = rot
			gm.add_child(k)
			k.global_position = pts[i] + Vector3(0, 6, 0)
		var kam := Camera3D.new()
		gm.add_child(kam)
		kam.projection = Camera3D.PROJECTION_ORTHOGONAL
		kam.size = 120.0
		kam.global_position = Vector3(8, 120, -14)
		kam.rotation_degrees = Vector3(-90, 0, 0)
		kam.current = true
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png("res://build/horst_route.png")
		get_tree().quit()
