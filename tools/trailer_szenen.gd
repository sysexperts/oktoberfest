extends Node
## Einzelne Trailer-Einstellungen als Standbild — zum Aussuchen, bevor gefilmt wird.
##
## Zwei Stufen:
##   leicht: 1280x720, ohne SSIL/Schärfentiefe/Nebel — schnell, nur zur Bildkontrolle
##   voll:   1920x1080, alle Effekte an wie in tools/render_trailer.gd
##
## Aufruf über tools/trailer_szenen.sh [leicht|voll] [szene ...]
## Bilder landen in build/szenen/<name>.png
##
## Sichert Spielstände/Einstellungen vorher und stellt sie wieder her
## (gleiches Verfahren wie render_trailer.gd).

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	const Figuren := preload("res://scripts/figuren.gd")
	const ZELTNAME := "Zum Durstigen Hirsch"
	const EINLASS := Vector3(0.0, 0.1, 9.6)
	const AUSGABE := "build/szenen"

	## Die Einstellungen. ort/ziel = Kamera, uhr = Tageszeit, fov = Brennweite.
	## aufbau: was vorher im Zelt passieren muss (siehe _aufbau_fuer).
	## "menge": um diesen Punkt werden die Kirmes-Besucher zusammengeholt,
	## sonst verteilen sie sich über das ganze Gelände und das Bild wirkt leer.
	const SZENEN := [
		{"name": "kirmes_gasse", "ort": Vector3(-26.0, 1.75, 10.0), "ziel": Vector3(-14.0, 1.6, -6.0),
			"uhr": 18.6, "fov": 60.0, "aufbau": "draussen", "menge": Vector3(-18.0, 0.0, 0.0)},
		{"name": "kirmes_schraeg", "ort": Vector3(-34.0, 9.0, 26.0), "ziel": Vector3(-12.0, 1.5, -4.0),
			"uhr": 18.6, "fov": 52.0, "aufbau": "draussen", "menge": Vector3(-20.0, 0.0, 8.0)},
		{"name": "kirmes_sued", "ort": Vector3(22.0, 1.8, -34.0), "ziel": Vector3(4.0, 1.6, -48.0),
			"uhr": 18.9, "fov": 62.0, "aufbau": "draussen", "menge": Vector3(10.0, 0.0, -44.0)},
		{"name": "kirmes_kran", "ort": Vector3(-40.0, 26.0, 40.0), "ziel": Vector3(-6.0, 2.0, -12.0),
			"uhr": 18.2, "fov": 55.0, "aufbau": "draussen", "menge": Vector3(-12.0, 0.0, 6.0)},
		{"name": "zelt_eingang", "ort": Vector3(-2.0, 3.2, 30.0), "ziel": Vector3(0.5, 3.6, 13.0),
			"uhr": 19.2, "fov": 50.0, "aufbau": "zelt_klein", "menge": Vector3(0.0, 0.0, 18.0)},
		{"name": "zelt_voll", "ort": Vector3(-3.5, 4.4, 9.8), "ziel": Vector3(4.0, 1.0, -3.0),
			"uhr": 21.0, "fov": 58.0, "aufbau": "zelt_voll"},
		{"name": "zelt_theke", "ort": Vector3(-6.5, 2.0, -4.0), "ziel": Vector3(0.0, 1.2, 1.0),
			"uhr": 21.0, "fov": 58.0, "aufbau": "zelt_voll"},
		{"name": "zelt_tanz", "ort": Vector3(0.0, 2.6, 7.0), "ziel": Vector3(0.0, 1.4, -2.0),
			"uhr": 21.4, "fov": 60.0, "aufbau": "zelt_tanz"},
	]

	var _gab_es := {}
	var gm: Node
	var env: Environment
	var kamera: Camera3D
	var attribute: CameraAttributesPractical
	var stufe := "leicht"
	var wunsch: Array[String] = []
	var _staff_id := 900
	var _deko_id := 800

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_argumente_lesen()
		_sichern()
		TranslationServer.set_locale("de")
		Net.start_solo(true)
		for i in 60000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(30)
		gm = get_tree().current_scene
		TranslationServer.set_locale("de")
		await _grundaufbau()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + AUSGABE))
		var letzter_aufbau := ""
		for s: Dictionary in SZENEN:
			if not wunsch.is_empty() and not wunsch.has(String(s.name)):
				continue
			if String(s.aufbau) != letzter_aufbau:
				await _aufbau_fuer(String(s.aufbau))
				letzter_aufbau = String(s.aufbau)
			await _bild(s)
		_zuruecksichern()
		print("SZENEN FERTIG")
		get_tree().quit()

	func _argumente_lesen() -> void:
		var nach_trenner := false
		for a in OS.get_cmdline_user_args():
			if a == "leicht" or a == "voll":
				stufe = a
			else:
				wunsch.append(a)
		if nach_trenner:
			pass

	# ------------------------------------------------------------ Aufbau
	func _grundaufbau() -> void:
		Game.add_money(90000)
		gm._popularity = 95.0
		gm._hygiene = 100.0
		gm._quest_step = 99
		gm.set_process(false)
		var eigen: Node3D = gm.get_node("Players").get_child(0)
		eigen.set_physics_process(false)
		eigen.visible = false
		gm.get_node("HUD").visible = false
		for n in gm.find_children("*", "", true, false):
			if String(n.name).contains("Zielmarker"):
				if n is CanvasItem:
					(n as CanvasItem).visible = false
				elif n is Node3D:
					(n as Node3D).visible = false
		kamera = Camera3D.new()
		kamera.fov = 55.0
		kamera.far = 400.0
		gm.add_child(kamera)
		kamera.current = true
		env = (gm.get_node("WorldEnvironment") as WorldEnvironment).environment
		attribute = CameraAttributesPractical.new()
		attribute.dof_blur_far_enabled = false
		kamera.attributes = attribute
		_grafik_setzen()

	func _grafik_setzen() -> void:
		var vp := get_viewport()
		if stufe == "voll":
			vp.msaa_3d = Viewport.MSAA_4X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			vp.scaling_3d_scale = 1.0
			env.ssao_enabled = true
			env.ssao_intensity = 1.6
			env.ssao_radius = 1.2
			env.ssil_enabled = true
			env.ssil_intensity = 0.8
			env.adjustment_enabled = true
		else:
			vp.msaa_3d = Viewport.MSAA_2X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			env.ssao_enabled = true
			env.ssao_intensity = 1.2
			env.ssil_enabled = false

	## Beschriftungen im Spiel stören im Bild — Zeltname bleibt.
	func _beschriftungen_aus() -> void:
		for l in gm.find_children("*", "Label3D", true, false):
			var lab := l as Label3D
			if lab.is_in_group("zeltname"):
				continue
			lab.visible = false

	func _stimmung(uhr: float) -> void:
		gm._night_t = -1.0
		gm._apply_daylight(uhr)
		env.glow_enabled = true
		env.glow_intensity = lerpf(0.6, 1.2, clampf((uhr - 17.0) / 4.0, 0.0, 1.0))
		env.glow_bloom = lerpf(0.05, 0.15, clampf((uhr - 17.0) / 4.0, 0.0, 1.0))
		env.tonemap_exposure = 1.15
		if stufe == "voll":
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.008
			env.volumetric_fog_albedo = Color(1.0, 0.8, 0.58)

	## Zustand, den eine Gruppe von Einstellungen braucht.
	func _aufbau_fuer(art: String) -> void:
		match art:
			"draussen":
				gm._tent_stage = 1
				gm._active_count = 4
				gm._zelt_name = ZELTNAME
				gm._apply_tent()
				gm._zeltname_anzeigen()
				gm._rebuild_seats()
				await _menge_fuellen()
			"zelt_klein":
				gm._tent_stage = 1
				gm._active_count = 4
				gm._apply_tent()
				gm._rebuild_seats()
				await _gaeste_setzen(20)
			"zelt_voll", "zelt_tanz":
				gm._tent_stage = 4
				gm._active_count = 24
				gm._apply_tent()
				gm._rebuild_seats()
				gm._artist_tier = 3
				gm._remove_artists()
				gm._spawn_artists()
				# Ohne Haengelaternen — die brauchen einen Balken ueber sich.
				_deko_setzen(["lichtergirlande", "lichtergirlande", "kronleuchter", "kronleuchter",
					"kronleuchter", "banner", "riesenbrezel"],
					[Vector2(-5.0, 1.0), Vector2(5.0, 1.0), Vector2(-6.0, -3.0), Vector2(0.0, -3.0),
					Vector2(6.0, -3.0), Vector2(-11.6, -2.0), Vector2(11.6, -6.0)])
				await _gaeste_setzen(96)
				_kruege_fuellen()
				_kellner(Vector3(-6.0, 0.1, -2.0), 0.0)
				_kellner(Vector3(3.0, 0.1, 2.0), PI * 0.6)
				if art == "zelt_tanz":
					_gaeste_tanzen()
		_beschriftungen_aus()
		await _frames(20)

	## Kirmes-Besucher: volle Dichte und warten, bis sie wirklich alle da sind.
	## Crowd setzt pro Frame nur ein paar Besucher — ohne Warten bleibt es leer.
	func _menge_fuellen() -> void:
		var menge = gm._crowd
		if menge == null:
			return
		menge.max_visitors = 500
		menge.set_density(1.0)
		for i in 1200:
			if menge._visitors.size() >= menge._target:
				break
			await get_tree().process_frame
		# kurz laufen lassen, damit sie sich verteilen statt zu stapeln
		await _frames(120)

	## Gäste an die Tische setzen (ohne Anmarsch, nur Darstellung).
	func _gaeste_setzen(anzahl: int) -> void:
		for k in anzahl:
			var vorher: int = gm._guest_next
			gm._spawn_guest()
			if gm._guest_next == vorher:
				break
			var id: int = vorher
			var g: Dictionary = gm._guest_sim[id]
			var ziel: Vector3 = gm._platz_pos_fuer(id, int(g.seat))
			g.pos = ziel
			g.mode = 1
			g.weg = []
			g.tgt = ziel
			var knoten: Node3D = gm._guests[id]
			knoten.position = ziel
			knoten.set_net(ziel, float(gm._seats[int(g.seat)].yaw))
			if k % 12 == 0:
				await get_tree().process_frame
		await _frames(10)

	func _gaeste_tanzen() -> void:
		for k in 16:
			gm._tanz_timer = 0.0
			gm._update_tanz(0.1)
		for id in gm._guest_sim.keys():
			var g: Dictionary = gm._guest_sim[id]
			var knoten = gm._guests.get(id)
			if knoten == null:
				continue
			if int(g.mode) == 5 or int(g.mode) == 6:
				knoten.set_net(g.tgt, float(g.yaw))
				knoten.set_tanz(true, int(g.mode) == 6)

	func _deko_setzen(arten: Array, orte: Array) -> void:
		for k in arten.size():
			var ort: Vector2 = orte[k]
			var lage: Dictionary = gm._deko_platz(String(arten[k]), ort.x, ort.y, 0.0)
			_deko_id += 1
			gm._add_einrichtung(_deko_id, String(arten[k]), float(lage.x), float(lage.z), float(lage.rot))

	func _kellner(ort: Vector3, blick: float) -> void:
		_staff_id += 1
		gm._add_staff(_staff_id, ort, gm.ROLE_KELLNER, 3)
		var container: Node = gm._staff_container
		if container.get_child_count() == 0:
			return
		var k: Node3D = container.get_child(container.get_child_count() - 1)
		k.set_carrying(4)
		k.set_net(ort, blick)

	func _kruege_fuellen() -> void:
		var ausgabe := get_tree().get_first_node_in_group("ausgabe")
		if ausgabe == null:
			return
		ausgabe.set_inhalt({"1_1": 3, "1_2": 3, "1_3": 3, "1_4": 3, "2_1": 2, "2_2": 2, "2_3": 2})
		for n in ausgabe.find_children("K*", "", true, false):
			if n is Krug:
				(n as Krug).fuellung = 1.0

	## Besucher zum Bildausschnitt holen. Die Kirmes ist 140x160 m groß — gleichmäßig
	## verteilt stehen selbst 500 Leute so weit auseinander, dass jedes Bild leer wirkt.
	## Darum werden sie vor der Aufnahme auf die Gassen rund um den Blickpunkt gesetzt.
	func _menge_bei(mitte: Vector3, radius: float) -> void:
		var menge = gm._crowd
		if menge == null or menge._points.is_empty():
			return
		var nah := []
		for p: Vector3 in menge._points:
			if Vector2(p.x - mitte.x, p.z - mitte.z).length() < radius:
				nah.append(p)
		if nah.is_empty():
			return
		for v in menge._visitors:
			if not is_instance_valid(v):
				continue
			var p: Vector3 = nah.pick_random()
			v.global_position = p + Vector3(randf_range(-1.1, 1.1), 0.0, randf_range(-1.1, 1.1))
			v.rotation.y = randf() * TAU
		# laufen lassen, damit sie auseinandergehen und nicht ineinander stecken
		await _frames(90)

	# ------------------------------------------------------------ Bild
	func _bild(s: Dictionary) -> void:
		if s.has("menge"):
			await _menge_bei(s.menge as Vector3, 26.0)
		_stimmung(float(s.uhr))
		kamera.fov = float(s.get("fov", 55.0))
		kamera.global_position = s.ort
		kamera.look_at(s.ziel)
		if stufe == "voll":
			attribute.dof_blur_far_enabled = bool(s.get("dof", false))
			attribute.dof_blur_far_distance = float(s.get("dof_ab", 22.0))
			attribute.dof_blur_far_transition = 16.0
			attribute.dof_blur_amount = 0.06
		# ein paar Frames, damit Licht, Schatten und Nebel stehen
		await _frames(30 if stufe == "voll" else 12)
		var bild := get_viewport().get_texture().get_image()
		var pfad := "res://%s/%s.png" % [AUSGABE, String(s.name)]
		bild.save_png(pfad)
		print("SZENE %s -> %s" % [String(s.name), ProjectSettings.globalize_path(pfad)])

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame

	# ------------------------------------------------------------ Spielstände
	func _sichern() -> void:
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".szenenbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".szenenbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".szenenbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".szenenbackup"))

	func _zuruecksichern() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".szenenbackup", echt)
				DirAccess.remove_absolute(echt + ".szenenbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
