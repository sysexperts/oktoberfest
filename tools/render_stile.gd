extends Node
## Stil-Vorschau: dieselbe Zeltszene (Gäste, Tänzer, Bühne) mit sechs Looks aus
## Licht, Nachbearbeitung und Shadern — nur zum Vergleichen, nichts davon ist im Spiel.
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/render_stile.tscn --resolution 1280x720
## Bilder: tools/stil_*.png und tools/stile_vergleich.png (nicht im Git)

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]
const FRAKTUR := preload("res://assets/fonts/UnifrakturCook-Bold.ttf")

## Nachbearbeitung über das fertige Bild: Farbton, Sättigung, Randabdunklung, Korn,
## Farbsaum und Farbstufen (Posterize). Werte je Stil über Uniforms.
const BILD_SHADER := """
shader_type canvas_item;
uniform sampler2D bild : hint_screen_texture, filter_linear_mipmap;
uniform vec3 toenung = vec3(1.0);
uniform float saettigung = 1.0;
uniform float kontrast = 1.0;
uniform float vignette = 0.0;
uniform float korn = 0.0;
uniform float farbsaum = 0.0;
uniform float stufen = 0.0;
uniform vec3 schatten_farbe = vec3(0.0);
uniform float schatten_mix = 0.0;
float zufall(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 mitte = uv - 0.5;
	vec3 c;
	if (farbsaum > 0.0) {
		vec2 versatz = mitte * farbsaum;
		c = vec3(texture(bild, uv + versatz).r, texture(bild, uv).g, texture(bild, uv - versatz).b);
	} else {
		c = texture(bild, uv).rgb;
	}
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saettigung);
	c = (c - 0.5) * kontrast + 0.5;
	c *= toenung;
	c = mix(c, c * schatten_farbe * 2.0, schatten_mix * (1.0 - smoothstep(0.0, 0.6, l)));
	if (stufen > 0.0) {
		c = floor(c * stufen + 0.5) / stufen;
	}
	c *= 1.0 - vignette * smoothstep(0.35, 0.85, length(mitte * vec2(1.25, 1.0)));
	c += (zufall(uv * 1000.0 + TIME) - 0.5) * korn;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""

## Comic-Umrisse aus Tiefe und Normalen — ein bildschirmfüllendes Quad vor der Kamera.
const UMRISS_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;
uniform sampler2D tiefe : hint_depth_texture, filter_nearest;
uniform sampler2D normalen : hint_normal_roughness_texture, filter_nearest;
uniform float staerke = 1.0;
void vertex() { POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0); }
float lin(vec2 uv, mat4 inv) {
	float d = texture(tiefe, uv).r;
	vec4 p = inv * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -p.z / p.w;
}
void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	float d0 = lin(SCREEN_UV, INV_PROJECTION_MATRIX);
	float kante = 0.0;
	vec3 n0 = texture(normalen, SCREEN_UV).xyz;
	for (int i = 0; i < 4; i++) {
		vec2 o = vec2(float(i == 0) - float(i == 1), float(i == 2) - float(i == 3)) * px * 1.5;
		float d = lin(SCREEN_UV + o, INV_PROJECTION_MATRIX);
		kante = max(kante, step(0.05 * d0, abs(d - d0)));
		vec3 n = texture(normalen, SCREEN_UV + o).xyz;
		kante = max(kante, step(0.35, distance(n, n0)));
	}
	ALBEDO = vec3(0.05, 0.035, 0.02);
	ALPHA = kante * staerke * (1.0 - smoothstep(25.0, 60.0, d0));
}
"""

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}
	var gm: Node
	var env: Environment
	var env_basis: Environment
	var sonne: DirectionalLight3D
	var sonne_energie := 1.0
	var sonne_farbe := Color.WHITE
	var kamera: Camera3D
	var bild_rect: ColorRect
	var umriss: MeshInstance3D
	var titel: Label

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".stilbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".stilbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".stilbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".stilbackup"))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(30)
		gm = get_tree().current_scene
		await _szene_aufbauen()
		await _frames(90)
		_vorbereiten()

		var bilder: Array[Image] = []
		for stil in ["Aktuell", "Warm & gemütlich", "Miniatur / Tilt-Shift", "Comic / Cel-Shading", "Filmisch", "Lichterfest-Abend"]:
			await _stil_anwenden(stil)
			await _frames(45)
			var img := get_viewport().get_texture().get_image()
			var datei := "stil_%d" % bilder.size()
			img.save_png("res://tools/%s.png" % datei)
			print("  gespeichert: ", datei, " (", stil, ")")
			bilder.append(img)
		_vergleich_speichern(bilder)

		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".stilbackup", echt)
				DirAccess.remove_absolute(echt + ".stilbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	## Volles Zelt: 24 Tische, Gäste auf den Plätzen, einige tanzen, Künstler auf der Bühne.
	func _szene_aufbauen() -> void:
		Game.add_money(50000)
		gm.net_book_tent.rpc_id(1, "Zum Durstigen Hirsch")
		await _frames(3)
		gm._tent_stage = 4
		gm._active_count = 24
		gm._zelt_name = "Zum Durstigen Hirsch"
		gm._apply_tent()
		gm._popularity = 90.0
		gm._hygiene = 100.0
		gm._rebuild_seats()
		for k in mini(90, gm._seats.size()):
			gm._spawn_guest()
		for id in gm._guest_sim.keys():
			var g: Dictionary = gm._guest_sim[id]
			g.mode = 1
			g.ostate = 0
			g.drinks = 2
			g.pos = gm._seats[int(g.seat)].pos
			g.yaw = gm._seats[int(g.seat)].yaw
			gm._guest_sim[id] = g
		gm._artist_tier = 3
		gm._spawn_artists()
		for k in 12:
			gm._tanz_timer = 0.0
			gm._update_tanz(0.1)
		for id in gm._guest_sim.keys():
			var g: Dictionary = gm._guest_sim[id]
			if int(g.mode) == 5 or int(g.mode) == 6:
				g.pos = g.tgt
				gm._guest_sim[id] = g
		gm._update_guests(0.01)
		gm.set_process(false)

	func _vorbereiten() -> void:
		var spieler: Node3D = gm.get_node("Players").get_child(0)
		spieler.set_physics_process(false)
		# Vom Eingang über die Tische: Theke hinten, Bühne rechts (nicht im Büroraum links vorn)
		spieler.global_position = Vector3(-3.0, 0.0, 10.2)
		spieler.rotation.y = deg_to_rad(-24.0)
		spieler.get_node("Head").position.y = 2.6
		spieler.get_node("Head").rotation.x = deg_to_rad(-14.0)
		kamera = spieler.get_node("Head/Camera3D")
		gm.get_node("HUD").visible = false
		var we := gm.get_node("WorldEnvironment") as WorldEnvironment
		env = we.environment
		env_basis = env.duplicate()
		sonne = gm.get_node("Sun")
		sonne_energie = sonne.light_energy
		sonne_farbe = sonne.light_color
		# Nachbearbeitung über das ganze Bild
		var ebene := CanvasLayer.new()
		ebene.layer = 50
		add_child(ebene)
		bild_rect = ColorRect.new()
		bild_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		bild_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sm := ShaderMaterial.new()
		sm.shader = Shader.new()
		sm.shader.code = BILD_SHADER
		bild_rect.material = sm
		ebene.add_child(bild_rect)
		titel = Label.new()
		titel.position = Vector2(26, 18)
		titel.add_theme_font_override("font", FRAKTUR)
		titel.add_theme_font_size_override("font_size", 46)
		titel.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
		titel.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02))
		titel.add_theme_constant_override("outline_size", 14)
		ebene.add_child(titel)
		# Comic-Umrisse
		umriss = MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1, 1)
		umriss.mesh = quad
		umriss.extra_cull_margin = 16384.0
		var um := ShaderMaterial.new()
		um.shader = Shader.new()
		um.shader.code = UMRISS_SHADER
		umriss.material_override = um
		umriss.position = Vector3(0, 0, -0.5)
		umriss.visible = false
		kamera.add_child(umriss)

	func _zuruecksetzen() -> void:
		for p in env_basis.get_property_list():
			if p.usage & PROPERTY_USAGE_STORAGE:
				env.set(p.name, env_basis.get(p.name))
		sonne.light_energy = sonne_energie
		sonne.light_color = sonne_farbe
		kamera.attributes = null
		umriss.visible = false
		var sm := bild_rect.material as ShaderMaterial
		for u in ["toenung", "schatten_farbe"]:
			sm.set_shader_parameter(u, Vector3.ONE if u == "toenung" else Vector3.ZERO)
		for u in ["vignette", "korn", "farbsaum", "stufen", "schatten_mix"]:
			sm.set_shader_parameter(u, 0.0)
		sm.set_shader_parameter("saettigung", 1.0)
		sm.set_shader_parameter("kontrast", 1.0)
		gm._night_t = -1.0
		gm._apply_daylight(-1.0)

	func _stil_anwenden(stil: String) -> void:
		_zuruecksetzen()
		titel.text = stil
		var sm := bild_rect.material as ShaderMaterial
		match stil:
			"Warm & gemütlich":
				env.tonemap_mode = Environment.TONE_MAPPER_ACES
				env.glow_enabled = true
				env.glow_intensity = 1.1
				env.glow_bloom = 0.18
				env.ssil_enabled = true
				env.ssil_intensity = 1.2
				env.volumetric_fog_enabled = true
				env.volumetric_fog_density = 0.012
				env.volumetric_fog_albedo = Color(1.0, 0.85, 0.65)
				sonne.light_color = Color(1.0, 0.82, 0.6)
				sonne.light_energy = sonne_energie * 1.15
				sm.set_shader_parameter("toenung", Vector3(1.08, 0.98, 0.84))
				sm.set_shader_parameter("saettigung", 1.12)
				sm.set_shader_parameter("vignette", 0.45)
			"Miniatur / Tilt-Shift":
				var ca := CameraAttributesPractical.new()
				ca.dof_blur_far_enabled = true
				ca.dof_blur_far_distance = 16.0
				ca.dof_blur_far_transition = 8.0
				ca.dof_blur_near_enabled = true
				ca.dof_blur_near_distance = 4.0
				ca.dof_blur_near_transition = 2.5
				ca.dof_blur_amount = 0.16
				kamera.attributes = ca
				sm.set_shader_parameter("saettigung", 1.4)
				sm.set_shader_parameter("kontrast", 1.12)
				sm.set_shader_parameter("vignette", 0.25)
			"Comic / Cel-Shading":
				umriss.visible = true
				# Rauschende Effekte aus, sonst werden die Farbstufen fleckig
				env.ssao_enabled = false
				env.ssil_enabled = false
				env.fog_enabled = false
				env.volumetric_fog_enabled = false
				sm.set_shader_parameter("stufen", 9.0)
				sm.set_shader_parameter("saettigung", 1.3)
				sm.set_shader_parameter("kontrast", 1.08)
			"Filmisch":
				env.tonemap_mode = Environment.TONE_MAPPER_AGX
				env.glow_enabled = true
				env.glow_intensity = 0.8
				env.glow_bloom = 0.1
				sm.set_shader_parameter("saettigung", 0.88)
				sm.set_shader_parameter("kontrast", 1.14)
				sm.set_shader_parameter("toenung", Vector3(1.05, 1.0, 0.94))
				sm.set_shader_parameter("schatten_farbe", Vector3(0.35, 0.5, 0.6))
				sm.set_shader_parameter("schatten_mix", 0.55)
				sm.set_shader_parameter("vignette", 0.6)
				sm.set_shader_parameter("korn", 0.05)
				sm.set_shader_parameter("farbsaum", 0.006)
			"Lichterfest-Abend":
				gm._night_t = -1.0
				gm._apply_daylight(19.4)
				env.fog_enabled = false
				env.glow_enabled = true
				env.glow_intensity = 1.5
				env.glow_bloom = 0.22
				env.volumetric_fog_enabled = true
				env.volumetric_fog_density = 0.006
				env.volumetric_fog_albedo = Color(1.0, 0.82, 0.62)
				env.tonemap_exposure = 1.25
				sm.set_shader_parameter("saettigung", 1.15)
				sm.set_shader_parameter("toenung", Vector3(1.06, 1.0, 0.95))
				sm.set_shader_parameter("vignette", 0.4)
		await _frames(2)

	## Alle Bilder als 2 × 3-Raster in einer Datei.
	func _vergleich_speichern(bilder: Array[Image]) -> void:
		var w := 640
		var h := 360
		var raster := Image.create(w * 2, h * 3, false, Image.FORMAT_RGBA8)
		for i in bilder.size():
			var klein := bilder[i].duplicate() as Image
			klein.convert(Image.FORMAT_RGBA8)
			klein.resize(w, h, Image.INTERPOLATE_LANCZOS)
			raster.blit_rect(klein, Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
		raster.save_png("res://tools/stile_vergleich.png")
		print("  gespeichert: stile_vergleich")

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
