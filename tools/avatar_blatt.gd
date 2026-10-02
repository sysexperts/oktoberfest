extends SceneTree
## Versuchsbilder nebeneinander: build/avtest/<pose>_<nr>.png -> build/avatare_blatt.png
func _init():
	var posen := ["winken", "jubeln", "posen"]
	var ids := [1, 2, 3, 4, 10, 0]
	var w := Image.create(256 * ids.size(), 256 * posen.size(), false, Image.FORMAT_RGBA8)
	w.fill(Color(0.3, 0.17, 0.09))
	for r in posen.size():
		for k in ids.size():
			var a := Image.load_from_file(ProjectSettings.globalize_path("res://build/avtest/%s_%d.png" % [posen[r], ids[k]]))
			a.convert(Image.FORMAT_RGBA8)
			w.blend_rect(a, Rect2i(0, 0, 256, 256), Vector2i(k * 256, r * 256))
	w.save_png(ProjectSettings.globalize_path("res://build/avatare_blatt.png"))
	quit()
