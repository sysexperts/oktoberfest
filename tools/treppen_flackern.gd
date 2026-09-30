extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Misst Flackern (Z-Fighting) an den Treppen: Die Kamera wird um wenige
## Millimeter verwackelt, dann wird gezählt, wie viele Pixel auf ebenen Flächen
## zwischen den Bildern springen. Ruhige Flächen ändern sich dabei nicht,
## überlappende Flächen tun es stark. Schreibt tools/flackern_<name>.png
## (rot = springt) und druckt den Anteil.
##   godot --path . res://tools/treppen_flackern.tscn -- vorher
##   zweites Argument: Kantenglättung zum Vergleich (none, msaa2, msaa4, fxaa, taa)
const BLICKE := [
	["halle", Vector3(-8.8, 1.7, -1.6), Vector3(-11.3, 1.6, 3.2), 60.0],
	["unten", Vector3(-9.6, 1.4, 1.2), Vector3(-11.6, 2.4, 4.6), 60.0],
	["oben", Vector3(-9.2, 4.6, 2.0), Vector3(-11.4, 3.4, 6.0), 60.0],
	
	
	
]
const BILDER := 10
const SPRUNG := 0.10       # Helligkeitsunterschied, ab dem ein Pixel "springt"
const RAND := 0.05         # nur Pixel auf ebenen Flächen zählen (Kanten wackeln immer)

func _ready() -> void:
	get_tree().root.add_child.call_deferred(L.new())

class L extends Node:
	func _hell(c: Color) -> float:
		return c.r * 0.3 + c.g * 0.59 + c.b * 0.11

	func _ready() -> void:
		var name_ := "lauf"
		var args := OS.get_cmdline_user_args()
		if args.size() > 0:
			name_ = args[0]
		var gm := await Spielstart.starten(self)
		for i in 40:
			await get_tree().process_frame
		var aa := args[1] if args.size() > 1 else "none"
		var vp := get_viewport()
		vp.msaa_3d = Viewport.MSAA_2X if aa == "msaa2" else (Viewport.MSAA_4X if aa == "msaa4" else Viewport.MSAA_DISABLED)
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if aa == "fxaa" else Viewport.SCREEN_SPACE_AA_DISABLED
		vp.use_taa = aa == "taa"
		gm.get_node("HUD").visible = false
		(gm.get_node("Players").get_child(0) as Node3D).visible = false
		var cam := Camera3D.new()
		gm.add_child(cam)
		cam.current = true
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for b: Array in BLICKE:
			cam.fov = b[3]
			var bilder: Array[Image] = []
			for k in BILDER:
				var ver := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.004
				cam.look_at_from_position((b[1] as Vector3) + ver, (b[2] as Vector3) + ver * 0.5)
				for i in 3:
					await get_tree().process_frame
				var img := get_viewport().get_texture().get_image()
				img.resize(960, 540, Image.INTERPOLATE_BILINEAR)
				bilder.append(img)
			var w := 960
			var h := 540
			var rot := Image.create(w, h, false, Image.FORMAT_RGB8)
			var mitte := bilder[0]
			var zaehl := 0
			var flaeche := 0
			var alle := 0
			var schwankung := 0.0
			for y in range(1, h - 1):
				for x in range(1, w - 1):
					var lo := 1.0
					var hi := 0.0
					var sum := 0.0
					for img: Image in bilder:
						var l := _hell(img.get_pixel(x, y))
						lo = minf(lo, l)
						hi = maxf(hi, l)
						sum += l
					var mw := sum / BILDER
					# ebene Fläche? Nachbarn im ersten Bild ähnlich hell
					var l0 := _hell(mitte.get_pixel(x, y))
					var ebene := absf(_hell(mitte.get_pixel(x + 1, y)) - l0) < RAND and absf(_hell(mitte.get_pixel(x, y + 1)) - l0) < RAND \
						and absf(_hell(mitte.get_pixel(x - 1, y)) - l0) < RAND and absf(_hell(mitte.get_pixel(x, y - 1)) - l0) < RAND
					schwankung += hi - lo
					if hi - lo > SPRUNG:
						alle += 1
					var c := mitte.get_pixel(x, y)
					rot.set_pixel(x, y, Color(c.r * 0.5, c.g * 0.5, c.b * 0.5))
					if ebene:
						flaeche += 1
						if hi - lo > SPRUNG:
							zaehl += 1
							rot.set_pixel(x, y, Color(1, 0, 0))
			var anteil := 100.0 * zaehl / maxf(1.0, flaeche)
			print("K %-6s %-16s ebene Flächen: %.2f %% springen · alle Pixel: %.2f %% springen, mittlere Schwankung %.4f" % [aa, b[0], anteil, 100.0 * alle / float(w * h), schwankung / float(w * h)])
			rot.save_png(ProjectSettings.globalize_path("res://tools/flackern_%s_%s.png" % [name_, b[0]]))
		print("K fertig")
		get_tree().quit()
