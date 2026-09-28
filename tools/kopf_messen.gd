extends SceneTree
## Misst den Kopf einer Figur (Kopf-Vertices in Modellkoordinaten, so wie
## figur.gd Zubehör setzt) — für die Lage von Hut, Bart und Brille.
## Aufruf: godot --headless --path . --script res://tools/kopf_messen.gd -- res://scenes/figuren/alex.tscn

func _init() -> void:
	for pfad in OS.get_cmdline_user_args():
		var f: Node3D = load(pfad).instantiate()
		var sk: Skeleton3D = f.find_children("*", "Skeleton3D", true, false)[0]
		var kopf := -1
		for n in ["Head", "mixamorig_Head"]:
			if sk.find_bone(n) >= 0:
				kopf = sk.find_bone(n)
		for mi: MeshInstance3D in sk.find_children("*", "MeshInstance3D", false, false):
			var arr := mi.mesh.surface_get_arrays(0)
			var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var kn: PackedInt32Array = arr[Mesh.ARRAY_BONES]
			var gw: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
			var je := kn.size() / pos.size()
			var zu_knochen := {}
			for i in mi.skin.get_bind_count():
				var bn := mi.skin.get_bind_name(i)
				zu_knochen[i] = mi.skin.get_bind_bone(i) if bn == "" else sk.find_bone(bn)
			var lo := Vector3(INF, INF, INF)
			var hi := -lo
			var anzahl := 0
			# Scheiben: Radius je Höhe (für Hut und Brille)
			var scheiben := {}
			for v in pos.size():
				var g := 0.0
				for k in je:
					if zu_knochen.get(kn[v * je + k], -1) == kopf:
						g += gw[v * je + k]
				if g < 0.5:
					continue
				var p := mi.transform * pos[v]
				lo = lo.min(p)
				hi = hi.max(p)
				anzahl += 1
				var s := int(p.y * 50.0)
				var alt: Vector3 = scheiben.get(s, Vector3(0, -INF, 0))
				scheiben[s] = Vector3(maxf(alt.x, absf(p.x)), maxf(alt.y, p.z), minf(alt.z, p.z) if alt.y > -INF else p.z)
			_augen(mi, pos, arr[Mesh.ARRAY_TEX_UV], lo.y + (hi.y - lo.y) * 0.25)
			print(pfad, ": ", anzahl, " Kopf-Vertices, min ", lo, " max ", hi)
			var ks := scheiben.keys()
			ks.sort()
			for s in ks:
				print("  y %.2f  halbe Breite %.3f  vorn %.3f  hinten %.3f" % [s / 50.0, scheiben[s].x, scheiben[s].y, scheiben[s].z])
			break
		f.free()
	quit()

## Augen: helle, farblose Stellen der Textur im Gesicht (vorn, über dem Mund).
func _augen(mi: MeshInstance3D, pos: PackedVector3Array, uv: PackedVector2Array, ab_y: float) -> void:
	var mat := mi.get_active_material(0) as BaseMaterial3D
	var bild := mat.albedo_texture.get_image()
	if bild.is_compressed():
		bild.decompress()
	for seite in [-1.0, 1.0]:
		var lo := Vector3(INF, INF, INF)
		var hi := -lo
		for v in pos.size():
			var p := mi.transform * pos[v]
			if p.y < ab_y or p.z < 0.05 or p.x * seite < 0.0:
				continue
			var c := bild.get_pixelv(Vector2i(uv[v] * Vector2(bild.get_size() - Vector2i.ONE)))
			if c.v > 0.8 and c.s < 0.25:
				lo = lo.min(p)
				hi = hi.max(p)
		print("  Auge %s: min %s max %s Mitte %s" % ["links" if seite < 0 else "rechts", lo, hi, (lo + hi) * 0.5])
