extends SceneTree
## Yardımcı araç: assets/kirmes paketindeki tüm modelleri isim etiketleriyle
## bir ızgaraya dizen katalog sahnesini üretir. Sahne gerçek düğümlerden oluşur,
## editörde tek tek seçip kirmes.tscn'e kopyalanabilir.
## Kullanım: godot --headless --path . --script res://tools/make_katalog.gd

const SIZES := "res://tools/kirmes_sizes.json"
const OUT := "res://scenes/katalog_kirmes.tscn"
const GAP := 3.0        # modeller arası boşluk (m)
const ROW_GAP := 8.0    # kategoriler arası boşluk (m)
const PER_ROW := 10     # satır başına model
## Katalogda göstermeyeceklerimiz (ızgarayı bozacak kadar büyük).
const SKIP := ["Terrain.fbx"]

func _init() -> void:
	var f := FileAccess.open(SIZES, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()

	var cats := {}
	for path: String in data.keys():
		if path.get_file() in SKIP:
			continue
		var rel := path.replace("res://assets/kirmes/Models/", "")
		var cat := rel.get_base_dir().split("/")[0]
		if not cats.has(cat):
			cats[cat] = []
		cats[cat].append(path)
	var cat_names := cats.keys()
	cat_names.sort()

	var ext := ""
	var nodes := ""
	var idx := 0
	var z := 0.0

	for cat: String in cat_names:
		var list: Array = cats[cat]
		list.sort()
		nodes += "\n[node name=\"%s\" type=\"Node3D\" parent=\".\"]\n" % cat
		nodes += "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, %.2f)\n" % z
		nodes += "\n[node name=\"_Titel\" type=\"Label3D\" parent=\"%s\"]\n" % cat
		nodes += "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -6, 3, 0)\n"
		nodes += "billboard = 1\npixel_size = 0.02\nfont_size = 64\noutline_size = 16\nmodulate = Color(1, 0.85, 0.3, 1)\ntext = \"%s\"\n" % cat

		# satır yüksekliği: bu kategorideki en geniş modele göre
		var step := GAP
		for p: String in list:
			var s: Array = data[p]["size"]
			step = maxf(step, maxf(s[0], s[2]) + 1.5)

		var row_z := 0.0
		var col := 0
		for p: String in list:
			var id := "m%d" % idx
			idx += 1
			ext += "[ext_resource type=\"PackedScene\" path=\"%s\" id=\"%s\"]\n" % [p, id]
			var nm := p.get_file().get_basename().replace(".", "_")
			var x: float = float(col) * step
			nodes += "\n[node name=\"%s\" parent=\"%s\" instance=ExtResource(\"%s\")]\n" % [nm, cat, id]
			nodes += "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.2f, 0, %.2f)\n" % [x, row_z]
			nodes += "\n[node name=\"%s_Name\" type=\"Label3D\" parent=\"%s\"]\n" % [nm, cat]
			nodes += "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.2f, -0.4, %.2f)\n" % [x, row_z]
			nodes += "billboard = 1\npixel_size = 0.006\nfont_size = 40\noutline_size = 12\ntext = \"%s\"\n" % nm
			col += 1
			if col >= PER_ROW:
				col = 0
				row_z += step
		z += row_z + step + ROW_GAP

	var head := "[gd_scene load_steps=%d format=3]\n\n%s\n[node name=\"KatalogKirmes\" type=\"Node3D\"]\n" % [idx + 1, ext]
	var o := FileAccess.open(OUT, FileAccess.WRITE)
	o.store_string(head + nodes)
	o.close()
	print("%d Modelle -> %s" % [idx, OUT])
	quit()
