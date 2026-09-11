extends Node
## Gibt die Materialwerte der Figuren aus (Vertexfarben, Grundfarbe, Textur-
## Mittelwert, Emission) — um Helligkeitsunterschiede zu verstehen.
## Aufruf: godot --headless --path . res://tools/material_info.tscn

const FIGUREN := ["res://scenes/figuren/bean.tscn", "res://scenes/figuren/charakter2.tscn",
	"res://scenes/figuren/charakter3.tscn"]

func _ready() -> void:
	for pfad: String in FIGUREN:
		var n: Node = (load(pfad) as PackedScene).instantiate()
		add_child(n)
		for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
			for s in mi.mesh.get_surface_count():
				var m := mi.get_active_material(s) as BaseMaterial3D
				if m == null:
					print("%s %s/%d: kein BaseMaterial3D" % [pfad.get_file(), mi.name, s])
					continue
				var mittel := "-"
				if m.albedo_texture:
					var bild := m.albedo_texture.get_image()
					if bild:
						if bild.is_compressed():
							bild.decompress()
						bild.resize(16, 16)
						var summe := Color(0, 0, 0)
						for y in 16:
							for x in 16:
								summe += bild.get_pixel(x, y)
						mittel = str(summe / 256.0)
				var arrays := mi.mesh.surface_get_arrays(s)
				var hat_farben: bool = arrays[Mesh.ARRAY_COLOR] != null and (arrays[Mesh.ARRAY_COLOR] as PackedColorArray).size() > 0
				var farb_mittel := "-"
				if hat_farben:
					var fa: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
					var summe2 := Color(0, 0, 0)
					for c in fa:
						summe2 += c
					farb_mittel = str(summe2 / float(fa.size()))
				print("%s %s/%d: vc_albedo=%s vertexfarben=%s (%s) albedo=%s tex=%s mittel=%s emis=%s op=%d" % [
					pfad.get_file(), mi.name, s, m.vertex_color_use_as_albedo, hat_farben, farb_mittel,
					m.albedo_color, m.albedo_texture != null, mittel, m.emission_enabled, m.emission_operator])
		n.queue_free()
	print("MATERIAL FERTIG")
	get_tree().quit()
