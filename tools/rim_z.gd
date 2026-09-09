extends SceneTree
## Yardımcı araç: dönme dolabı çemberinin gerçek kalınlığını ölçer — sadece
## dış yarıçaptaki köşe noktalarına bakarak. Ampuller buna göre yerleşiyor.
func _init() -> void:
	var n := (load("res://assets/kirmes/Models/Attractions/OtherRides/FerrisWheel.fbx") as PackedScene).instantiate()
	var hub := n.get_node("FerrisWheel_Rotate") as MeshInstance3D
	var arr := hub.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	print("Vertices: %d" % verts.size())
	for band in [[7.0, 8.0], [5.0, 7.0], [2.0, 5.0], [0.0, 2.0]]:
		var zmin := 999.0
		var zmax := -999.0
		var cnt := 0
		for v in verts:
			var r := sqrt(v.x * v.x + v.y * v.y)
			if r >= band[0] and r < band[1]:
				zmin = minf(zmin, v.z)
				zmax = maxf(zmax, v.z)
				cnt += 1
		if cnt > 0:
			print("Radius %4.1f-%4.1f: z von %6.2f bis %6.2f  (%d Punkte)" % [band[0], band[1], zmin, zmax, cnt])
	n.free()
	quit()
