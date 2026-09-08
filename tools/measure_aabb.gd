extends SceneTree
## Yardımcı araç: verilen .glb modellerinin gerçek boyutunu (AABB) yazar.
## Kullanım: godot --headless --path . --script res://tools/measure_aabb.gd
## Prefab'lardaki çarpışma kutusu ve yerleşim yüksekliği bunun çıktısına göre ayarlanır.

const MODELS := [
	"res://assets/models/drehscheibe.glb",
	"res://assets/models/enten.glb",
	"res://assets/models/schiessstand.glb",
	"res://assets/models/suessigkeiten.glb",
]

func _init() -> void:
	for path in MODELS:
		var ps: PackedScene = load(path)
		if ps == null:
			print("%s -> YÜKLENEMEDİ" % path)
			continue
		var root: Node = ps.instantiate()
		var aabb := AABB()
		var first := true
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			# mesh AABB'sini kök uzayına taşı
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
		var s := aabb.size
		var p := aabb.position
		print("%s\n   boyut  X=%.2f  Y=%.2f  Z=%.2f\n   min    (%.2f, %.2f, %.2f)  merkez=(%.2f, %.2f, %.2f)" % [
			path.get_file(), s.x, s.y, s.z, p.x, p.y, p.z,
			p.x + s.x * 0.5, p.y + s.y * 0.5, p.z + s.z * 0.5])
		root.free()
	quit()
