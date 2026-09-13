extends Node
## Licht-Vorschau für den Lichterfest-Look: volles Zelt abends und nachts, einmal mit
## der heutigen Zeltbeleuchtung, einmal mit mehr Licht (hellere Wandlampen,
## warme Deckenlichter ohne Schatten, mehr Grundhelligkeit im Zelt), dazu außen.
## Nur zum Vergleichen — nichts davon ist im Spiel.
## Aufruf: godot --path . res://tools/render_licht.tscn --resolution 1280x720
## Bilder: tools/licht_*.png (nicht im Git)

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]
const FRAKTUR := preload("res://assets/fonts/UnifrakturCook-Bold.ttf")

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}
	var gm: Node
	var env: Environment
	var spieler: Node3D
	var titel: Label
	var zeltlampen: Array[OmniLight3D] = []
	var lampen_energie := {}
	var deckenlichter: Array[OmniLight3D] = []

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".lichtbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".lichtbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".lichtbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".lichtbackup"))
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

		var aufnahmen := [
			["Heute · 19:30", 19.5, false, "innen"],
			["Mehr Zeltlicht · 19:30", 19.5, true, "innen"],
			["Heute · 21:30", 21.5, false, "innen"],
			["Mehr Zeltlicht · 21:30", 21.5, true, "innen"],
			["Heute · 21:30 · außen", 21.5, false, "aussen"],
			["Mehr Zeltlicht · 21:30 · außen", 21.5, true, "aussen"],
		]
		var bilder: Array[Image] = []
		for a in aufnahmen:
			_anwenden(a[1], a[2], a[3])
			titel.text = a[0]
			await _frames(50)
			var img := get_viewport().get_texture().get_image()
			img.save_png("res://tools/licht_%d.png" % bilder.size())
			print("  gespeichert: licht_%d (%s)" % [bilder.size(), a[0]])
			bilder.append(img)
		_vergleich_speichern(bilder)

		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".lichtbackup", echt)
				DirAccess.remove_absolute(echt + ".lichtbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

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
		spieler = gm.get_node("Players").get_child(0)
		spieler.set_physics_process(false)
		gm.get_node("HUD").visible = false
		env = (gm.get_node("WorldEnvironment") as WorldEnvironment).environment
		for l in gm.get_node("Tent").find_children("*", "OmniLight3D", true, false):
			zeltlampen.append(l as OmniLight3D)
			lampen_energie[l] = [(l as OmniLight3D).light_energy, (l as OmniLight3D).omni_range]
		# Warme Deckenlichter über den Tischreihen — ohne Schatten, damit es billig bleibt
		for x in [-8.0, -2.5, 3.0]:
			for z in [-5.5, -0.5, 4.5, 9.0]:
				var d := OmniLight3D.new()
				d.position = Vector3(x, 3.5, z)
				d.light_color = Color(1.0, 0.8, 0.55)
				d.light_energy = 0.55
				d.omni_range = 7.0
				d.omni_attenuation = 1.6
				d.shadow_enabled = false
				d.visible = false
				gm.add_child(d)
				deckenlichter.append(d)
		var ebene := CanvasLayer.new()
		ebene.layer = 50
		add_child(ebene)
		titel = Label.new()
		titel.position = Vector2(26, 18)
		titel.add_theme_font_override("font", FRAKTUR)
		titel.add_theme_font_size_override("font_size", 42)
		titel.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
		titel.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02))
		titel.add_theme_constant_override("outline_size", 14)
		ebene.add_child(titel)

	## Lichterfest-Look (wie in render_stile) zur Uhrzeit, optional mit mehr Zeltlicht.
	func _anwenden(uhr: float, mehr_licht: bool, blick: String) -> void:
		gm._night_t = -1.0
		gm._apply_daylight(uhr)
		env.fog_enabled = false
		env.glow_enabled = true
		env.glow_intensity = 1.5
		env.glow_bloom = 0.22
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.006
		env.volumetric_fog_albedo = Color(1.0, 0.82, 0.62)
		env.tonemap_exposure = 1.25
		for l in zeltlampen:
			var basis: Array = lampen_energie[l]
			l.light_energy = float(basis[0]) * (1.5 if mehr_licht else 1.0)
			l.omni_range = float(basis[1]) * (1.3 if mehr_licht else 1.0)
		for d in deckenlichter:
			d.visible = mehr_licht
		# Kein Ambient-Aufschlag: der hob das ganze Zelt auf Tageshelligkeit und nahm
		# der Nacht den Kontrast (erster Versuch)
		if blick == "innen":
			spieler.global_position = Vector3(-3.0, 0.0, 10.2)
			spieler.rotation.y = deg_to_rad(-24.0)
			spieler.get_node("Head").position.y = 2.6
			spieler.get_node("Head").rotation.x = deg_to_rad(-14.0)
		else:
			spieler.global_position = Vector3(2.0, 0.0, 26.0)
			spieler.rotation.y = deg_to_rad(8.0)
			spieler.get_node("Head").position.y = 1.35
			spieler.get_node("Head").rotation.x = deg_to_rad(4.0)

	func _vergleich_speichern(bilder: Array[Image]) -> void:
		var w := 640
		var h := 360
		var raster := Image.create(w * 2, h * 3, false, Image.FORMAT_RGBA8)
		for i in bilder.size():
			var klein := bilder[i].duplicate() as Image
			klein.convert(Image.FORMAT_RGBA8)
			klein.resize(w, h, Image.INTERPOLATE_LANCZOS)
			raster.blit_rect(klein, Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
		raster.save_png("res://tools/licht_vergleich.png")
		print("  gespeichert: licht_vergleich")

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
