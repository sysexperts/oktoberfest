extends SceneTree
## Stoffe und Anstriche für die Kirmesbuden — damit nicht alles blau-weiß ist:
## je Farbschema Streifen, Zickzack und Strahlenkranz als Textur + Material.
##   assets/zelt/texturen/<muster>_<schema>.png
##   assets/zelt/materialien/<muster>_<schema>.tres
##   godot --headless --path . --script tools/bake_budenstoff.gd
##   godot --headless --path . --import

const TEX := "res://assets/zelt/texturen/"
const MAT := "res://assets/zelt/materialien/"
const HELL := Color(0.97, 0.95, 0.90)
const SCHEMA := {
	"rot": Color(0.74, 0.13, 0.15),
	"gruen": Color(0.11, 0.44, 0.26),
	"orange": Color(0.90, 0.47, 0.10),
	"violett": Color(0.40, 0.17, 0.48),
	"tuerkis": Color(0.07, 0.50, 0.52),
}

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEX))
	for schema: String in SCHEMA:
		var farbe: Color = SCHEMA[schema]
		_png(_streifen(farbe), "streifen_" + schema)
		_png(_zickzack(farbe), "zickzack_" + schema)
		_png(_strahlen(farbe), "strahlen_" + schema)
		_mat("streifen_" + schema, "streifen_" + schema, Vector3(2.0, 2.0, 2.0), 0.85)
		_mat("streifen_fein_" + schema, "streifen_" + schema, Vector3(0.7, 0.7, 0.7), 0.85)
		_mat("zickzack_" + schema, "zickzack_" + schema, Vector3(1.2, 1.2, 1.2), 0.85)
		_mat("strahlen_" + schema, "strahlen_" + schema, Vector3(1.0, 1.0, 1.0), 0.8)
	print("BUDENSTOFF FERTIG")
	quit()

func _png(img: Image, name: String) -> void:
	img.save_png(TEX + name + ".png")
	print("  Textur ", name)

## Breite Bahnen wie eine Zeltplane, mit dunkler Naht
func _streifen(farbe: Color) -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var c := HELL if y < s / 2 else farbe
			if y % (s / 2) < 2:
				c = c.darkened(0.15)
			img.set_pixel(x, y, c)
	return img

## Zickzack-Band (Wimpelkante, Schürzen)
func _zickzack(farbe: Color) -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var u := float(x) / s * 4.0
			var v := float(y) / s
			var zacke := absf(fposmod(u, 1.0) - 0.5) * 2.0
			var c := farbe if v < 0.25 + zacke * 0.45 else HELL
			img.set_pixel(x, y, c)
	return img

## Strahlenkranz aus der Mitte (Schaustellerfassade)
func _strahlen(farbe: Color) -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var d := Vector2(float(x) / s - 0.5, float(y) / s - 0.5)
			var w := atan2(d.y, d.x) / TAU * 16.0
			var c := farbe if posmod(floori(w), 2) == 0 else HELL
			if d.length() < 0.12:
				c = Color(0.95, 0.78, 0.32)
			img.set_pixel(x, y, c)
	return img

func _mat(name: String, tex: String, skala: Vector3, rau: float) -> void:
	var mt := StandardMaterial3D.new()
	mt.albedo_texture = load(TEX + tex + ".png")
	mt.roughness = rau
	mt.uv1_scale = skala
	mt.uv1_triplanar = true
	mt.uv1_world_triplanar = true
	ResourceSaver.save(mt, MAT + name + ".tres")
