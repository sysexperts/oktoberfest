extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Misst Z-Fighting an den Emporentreppen: Aus nächster Nähe wird die Kamera um 2 mm
## verwackelt; Z-Fighting lässt Flächen zwischen den Bildern zwischen zwei
## Farben springen, ruhige Flächen ändern sich nicht. Gezählt werden Pixel, deren
## Helligkeit über 12 Bilder um mehr als 0,08 schwankt, auf ebenen Flächen.
## Schreibt tools/zfight_<name>_<blick>.png (rot = springt).
##   godot --path . res://tools/treppen_zfight.tscn -- vorher
const BLICKE := [
	["schacht", Vector3(-10.7, 1.5, 5.7), Vector3(-11.3, -2.0, 1.5), 75.0],
	["schacht2", Vector3(-11.0, 1.6, 4.9), Vector3(-11.2, -1.8, 2.0), 70.0],
	["wange_west", Vector3(-11.3, 1.7, 0.7), Vector3(-11.95, 0.8, 2.2), 70.0],
	["wange_west2", Vector3(-11.3, 2.7, 2.6), Vector3(-11.95, 1.7, 4.0), 70.0],
	["wange_ost", Vector3(11.3, 1.7, -9.3), Vector3(11.95, 0.8, -7.8), 70.0],
	["innen_west", Vector3(-11.6, 1.8, 0.4), Vector3(-10.7, 0.6, 2.0), 70.0],
]
const BILDER := 12
const SPRUNG := 0.08
const RAND := 0.05

func _ready() -> void:
	get_tree().root.add_child.call_deferred(L.new())

class L extends Node:
	func _hell(c: Color) -> float:
		return c.r * 0.3 + c.g * 0.59 + c.b * 0.11

	func _ready() -> void:
		var args := OS.get_cmdline_user_args()
		var name_ := args[0] if args.size() > 0 else "lauf"
		var gm := await Spielstart.starten(self)
		for i in 40:
			await get_tree().process_frame
		if args.size() > 1 and args[1] == "aniso16":
			get_viewport().anisotropic_filtering_level = Viewport.ANISOTROPY_16X
		gm.get_node("HUD").visible = false
		(gm.get_node("Players").get_child(0) as Node3D).visible = false
		var filter := gm.get_node_or_null("Bildfilter") as CanvasLayer
		if filter:
			filter.visible = false   # Körnung würde jedes Pixel zittern lassen
		var cam := Camera3D.new()
		gm.add_child(cam)
		cam.current = true
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		for b: Array in BLICKE:
			cam.fov = b[3]
			var bilder: Array[Image] = []
			for k in BILDER:
				# Blickrichtung um etwa ein halbes Pixel verwackeln (Pixelwinkel = fov / 960),
				# dazu 2 mm Verschiebung: so krabbeln dünne Linien und flackern gleiche Ebenen
				var abstand := ((b[2] as Vector3) - (b[1] as Vector3)).length()
				var pix := deg_to_rad(b[3]) / 960.0
				var ver := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.002
				var dreh := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * abstand * pix * 0.5
				cam.look_at_from_position((b[1] as Vector3) + ver, (b[2] as Vector3) + dreh)
				for i in 3:
					await get_tree().process_frame
				var img := get_viewport().get_texture().get_image()
				img.resize(960, 540, Image.INTERPOLATE_BILINEAR)
				bilder.append(img)
			var w := 960
			var h := 540
			var rot := Image.create(w, h, false, Image.FORMAT_RGB8)
			var zaehl := 0
			var flaeche := 0
			var alle := 0
			var schwankung := 0.0
			for y in range(1, h - 1):
				for x in range(1, w - 1):
					var l0 := _hell(bilder[0].get_pixel(x, y))
					var ebene := absf(_hell(bilder[0].get_pixel(x + 1, y)) - l0) < RAND and absf(_hell(bilder[0].get_pixel(x, y + 1)) - l0) < RAND \
						and absf(_hell(bilder[0].get_pixel(x - 1, y)) - l0) < RAND and absf(_hell(bilder[0].get_pixel(x, y - 1)) - l0) < RAND
					var c := bilder[0].get_pixel(x, y)
					rot.set_pixel(x, y, Color(c.r * 0.5, c.g * 0.5, c.b * 0.5))
					var lo2 := 1.0
					var hi2 := 0.0
					for img: Image in bilder:
						var l2 := _hell(img.get_pixel(x, y))
						lo2 = minf(lo2, l2)
						hi2 = maxf(hi2, l2)
					schwankung += hi2 - lo2
					if hi2 - lo2 > SPRUNG:
						alle += 1
						if not ebene:
							rot.set_pixel(x, y, Color(1, 0.7, 0))
					if not ebene:
						continue
					flaeche += 1
					var lo := 1.0
					var hi := 0.0
					for img: Image in bilder:
						var l := _hell(img.get_pixel(x, y))
						lo = minf(lo, l)
						hi = maxf(hi, l)
					if hi - lo > SPRUNG:
						zaehl += 1
						rot.set_pixel(x, y, Color(1, 0, 0))
			print("K %-14s ebene Flächen: %.2f %% springen · alle Pixel: %.2f %% springen, Schwankung %.4f" % [b[0], 100.0 * zaehl / maxf(1.0, flaeche), 100.0 * alle / float(w * h), schwankung / float(w * h)])
			rot.save_png(ProjectSettings.globalize_path("res://tools/zfight_%s_%s.png" % [name_, b[0]]))
		print("K fertig")
		get_tree().quit()
