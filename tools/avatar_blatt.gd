extends SceneTree
func _init():
	var w := Image.create(256*7, 512, false, Image.FORMAT_RGBA8)
	w.fill(Color(0.1,0.2,0.4))
	for i in 13:
		var a := Image.load_from_file(ProjectSettings.globalize_path("res://assets/ui/avatare/figur_%d.png" % i))
		a.convert(Image.FORMAT_RGBA8)
		w.blend_rect(a, Rect2i(0,0,256,256), Vector2i((i%7)*256,(i/7)*256))
	w.save_png(ProjectSettings.globalize_path("res://build/avatare_blatt.png"))
	quit()
