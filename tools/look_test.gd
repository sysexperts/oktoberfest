extends Node
## Look-Test: dieselben Ansichten in drei Grafik-Varianten nebeneinander (A | B | C).
##   A Aktuell   — wie im Spiel
##   B Natürlich — AgX, weniger Himmelslicht, wärmere Sonne, weiche Schatten, kräftigeres SSAO, Dunst
##   C Stil      — B + Farb-LUT (warme Lichter, kühle Schatten, S-Kurve), SSIL,
##                 Detail-Durchgang auf Kirmes-Materialien, Vignette und Körnung
## Verändert nichts dauerhaft. Aufruf: Godot --path . res://tools/look_test.tscn (SHOT_DIR = Zielordner)

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	const DETAIL := preload("res://tools/look_detail.gdshader")
	const ANSICHTEN := {
		"platz": [14.0, Vector3(-12.0, 8.0, 36.0), Vector3(2.0, 2.5, 13.0)],
		"abend": [20.6, Vector3(-14.0, 5.0, 36.0), Vector3(0.0, 3.5, 10.0)],
		"zelt": [18.8, Vector3(-4.0, 3.2, 9.0), Vector3(3.0, 1.2, -6.0)],
		"kirmes": [16.5, Vector3(10.0, 1.8, 20.0), Vector3(30.0, 3.0, -20.0)],
	}

	var gm: Node
	var env: Environment
	var sonne: DirectionalLight3D
	var kamera: Camera3D
	var basis := {}
	var detail_mats: Array[BaseMaterial3D] = []
	var detail: ShaderMaterial
	var overlay: ColorRect
	var lut: ImageTexture3D

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		Net.start_solo(true)
		for i in 60000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		for i in 40:
			await get_tree().process_frame
		gm = get_tree().current_scene
		_aufbauen()
		for i in 60:
			await get_tree().process_frame
		for name: String in ANSICHTEN:
			var a: Array = ANSICHTEN[name]
			var blatt := Image.create(960 * 3, 540, false, Image.FORMAT_RGB8)
			for v in 3:
				_variante(v, float(a[0]))
				kamera.global_position = a[1]
				kamera.look_at(a[2])
				for i in 20:
					await get_tree().process_frame
				var bild := get_viewport().get_texture().get_image()
				bild.convert(Image.FORMAT_RGB8)
				bild.resize(960, 540, Image.INTERPOLATE_LANCZOS)
				blatt.blit_rect(bild, Rect2i(0, 0, 960, 540), Vector2i(960 * v, 0))
				bild.save_png(OS.get_environment("SHOT_DIR") + "/look_%s_%s.png" % [name, "ABC"[v]])
			blatt.save_png(OS.get_environment("SHOT_DIR") + "/look_%s.png" % name)
		print("LOOK FERTIG")
		get_tree().quit()

	func _aufbauen() -> void:
		gm.set_process(false)
		var eigen: Node3D = gm.get_node("Players").get_child(0)
		eigen.set_physics_process(false)
		eigen.visible = false
		gm.get_node("HUD").visible = false
		for n in gm.find_children("*Zielmarker*", "", true, false):
			if "visible" in n:
				n.visible = false
		kamera = Camera3D.new()
		kamera.fov = 62.0
		gm.add_child(kamera)
		kamera.current = true
		env = (gm.get_node("WorldEnvironment") as WorldEnvironment).environment
		sonne = gm._sun
		for p in ["tonemap_mode", "tonemap_white", "ssao_intensity", "ssao_power", "ssao_light_affect",
				"ssil_enabled", "fog_aerial_perspective", "fog_height_density", "fog_height", "ambient_light_sky_contribution",
				"adjustment_contrast", "adjustment_color_correction", "glow_hdr_threshold"]:
			basis[p] = env.get(p)
		basis["winkel"] = sonne.light_angular_distance
		# Zelt voll: Tische, Gäste, Band
		gm._tent_stage = 4
		gm._active_count = 16
		gm._zelt_name = "Zum Durstigen Hirsch"
		gm._apply_tent()
		gm._zeltname_anzeigen()
		gm._rebuild_seats()
		for k in 60:
			var vorher: int = gm._guest_next
			gm._spawn_guest()
			if gm._guest_next == vorher:
				break
			var g: Dictionary = gm._guest_sim[vorher]
			var ziel: Vector3 = gm._platz_pos_fuer(vorher, int(g.seat))
			g.pos = ziel
			g.mode = 1
			g.weg = []
			g.tgt = ziel
			(gm._guests[vorher] as Node3D).position = ziel
			gm._guests[vorher].set_net(ziel, float(gm._seats[int(g.seat)].yaw))
		gm._artist_tier = 1
		gm._spawn_artists()
		for l in gm.find_children("*", "Label3D", true, false):
			if not (l as Label3D).is_in_group("zeltname"):
				(l as Label3D).visible = false
		# Detail-Durchgang für C
		detail = ShaderMaterial.new()
		detail.shader = DETAIL
		var wurzeln: Array[Node] = [gm.get_node("Kirmes"), gm.get_node("Tent"), gm.get_node("Tables")]
		for w in wurzeln:
			for m in w.find_children("*", "MeshInstance3D", true, false):
				if String(gm.get_node("Kirmes").get_path_to(m)).begins_with("Altstadt"):
					continue
				var mi := m as MeshInstance3D
				if mi.mesh == null:
					continue
				for s in mi.mesh.get_surface_count():
					var mat := mi.get_active_material(s)
					if mat is BaseMaterial3D and mat.next_pass == null and not detail_mats.has(mat):
						detail_mats.append(mat)
		# Vignette und Körnung
		var ebene := CanvasLayer.new()
		ebene.layer = 50
		add_child(ebene)
		overlay = ColorRect.new()
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sm := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = """shader_type canvas_item;
uniform sampler2D bild : hint_screen_texture, filter_linear;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec3 c = texture(bild, SCREEN_UV).rgb;
	vec2 q = SCREEN_UV - 0.5;
	c *= 1.0 - smoothstep(0.25, 0.85, length(q * vec2(1.0, 0.8))) * 0.38;
	c += (hash(SCREEN_UV * 1000.0) - 0.5) * 0.02;
	COLOR = vec4(c, 1.0);
}"""
		sm.shader = sh
		overlay.material = sm
		ebene.add_child(overlay)
		lut = _lut()

	## Farbtabelle: S-Kurve, kühle Schatten, warme Lichter, etwas Sättigung
	func _lut() -> ImageTexture3D:
		const N := 33
		var bilder: Array[Image] = []
		for bi in N:
			var img := Image.create(N, N, false, Image.FORMAT_RGB8)
			for gi in N:
				for ri in N:
					var c := Vector3(ri, gi, bi) / float(N - 1)
					var l := c.dot(Vector3(0.2126, 0.7152, 0.0722))
					var s := Vector3(smoothstep(0.0, 1.0, c.x), smoothstep(0.0, 1.0, c.y), smoothstep(0.0, 1.0, c.z))
					c = c.lerp(s, 0.4)
					var ton := Vector3(0.93, 0.99, 1.06).lerp(Vector3(1.06, 1.0, 0.9), smoothstep(0.15, 0.75, l))
					c *= ton
					var l2 := c.dot(Vector3(0.2126, 0.7152, 0.0722))
					c = Vector3(l2, l2, l2).lerp(c, 1.12)
					img.set_pixel(ri, gi, Color(clampf(c.x, 0, 1), clampf(c.y, 0, 1), clampf(c.z, 0, 1)))
			bilder.append(img)
		var t := ImageTexture3D.new()
		t.create(Image.FORMAT_RGB8, N, N, N, false, bilder)
		return t

	func _variante(v: int, uhr: float) -> void:
		gm._night_t = -1.0
		gm._apply_daylight(uhr)
		gm._apply_crowd(uhr)
		for p: String in basis:
			if p != "winkel":
				env.set(p, basis[p])
		sonne.light_angular_distance = basis["winkel"]
		overlay.visible = v == 2
		for m in detail_mats:
			m.next_pass = detail if v == 2 else null
		if v == 0:
			return
		var nacht: float = gm._night_t
		env.tonemap_mode = Environment.TONE_MAPPER_AGX
		env.tonemap_exposure *= lerpf(1.12, 1.3, nacht)
		env.adjustment_saturation = 1.08 + 0.1 * nacht
		env.ambient_light_energy *= lerpf(0.55, 1.1, nacht)
		env.ambient_light_sky_contribution = 0.7
		sonne.light_energy *= lerpf(1.45, 1.0, nacht)
		sonne.light_color = Color(1.0, 0.9, 0.76).lerp(sonne.light_color, nacht)
		sonne.light_angular_distance = 1.2
		env.ssao_intensity = 2.4
		env.ssao_power = 1.9
		env.ssao_light_affect = 0.25
		env.fog_density = lerpf(0.0009, 0.0016, nacht)
		env.fog_aerial_perspective = 0.12
		env.fog_light_color = Color(0.74, 0.8, 0.9).lerp(env.fog_light_color, nacht)
		env.glow_hdr_threshold = 1.1
		if v == 2:
			env.adjustment_color_correction = lut
			env.ssil_enabled = true
			env.ssil_intensity = 0.8
