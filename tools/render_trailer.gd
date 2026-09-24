extends Node
## Steam-Trailer (~90 s) als Aufstiegsgeschichte, im echten Spiel gedreht:
## Studio-Intro → Kirmes → leeres Zelt mieten → mit 2 Tischen klein anfangen (Koop-
## Spieler tragen Krüge, erste Gäste) → Lieferwagen → Zeitraffer bis zum vollen Zelt
## (Tische, Gäste, Deko, Band, Abend) → Full House mit Ausgabe und Kellner → Tanz
## auf den Tischen → Streit, Massenschlägerei, Rauswurf → Nacht mit Logo.
## Grafik fürs Video aufgewertet (SSAO/SSIL, MSAA, Schärfentiefe, Glühen, Lichtnebel,
## Farbkorrektur). Nichts davon verändert das Spiel.
##
## Aufruf über tools/render_trailer.sh (nimmt auf, schneidet den Aufbau weg, mischt Musik).
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	const FRAKTUR := preload("res://assets/fonts/UnifrakturCook-Bold.ttf")
	const LOGO_BOGEN := preload("res://assets/ui/ui_bogen.png")
	const RAUFBOLD := preload("res://scenes/pruegel/raufbold.tscn")
	const MASSENSCHLAEGEREI := preload("res://scenes/pruegel/massenschlaegerei.tscn")
	const STAUB := preload("res://scenes/effekte/staub.tscn")
	const Figuren := preload("res://scripts/figuren.gd")
	const ZELTNAME := "Zum Durstigen Hirsch"
	## Freie Fläche hinter dem Eingang (Schlägerei, Einlass der Gäste)
	const RAUF_MITTE := Vector3(0.0, 0.0, 7.6)
	const EINLASS := Vector3(0.0, 0.1, 9.6)
	const TISCH_STUFEN := [[2, 1], [4, 1], [8, 2], [12, 3], [16, 3], [20, 4], [24, 4]]
	const FPS := 30.0

	var _gab_es := {}
	var gm: Node
	var env: Environment
	var kamera: Camera3D
	var attribute: CameraAttributesPractical
	var ebene: CanvasLayer
	var titel: Label
	var untertitel: Label
	var zaehler: Label
	var schwarz: ColorRect
	var studio: Label
	var studio_zeile: Label
	var logo: TextureRect
	var raufbolde: Array[Node3D] = []
	var spieler: Array[Node3D] = []
	var _staff_id := 900
	var _paket_id := 9000
	var _deko_id := 800
	var _bahn_nr := 0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		# Sofort schwarz — der Ladebildschirm soll nicht ins Video
		_ueberlagerung_bauen()
		_sichern()
		TranslationServer.set_locale("de")
		await _spiel_starten()
		TranslationServer.set_locale("de")
		await _aufbauen()
		_grafik_aufwerten()
		await _frames(45)
		# Schnittmarke für render_trailer.sh: ab hier beginnt das Video
		print("TRAILER_START %.3f" % (float(Engine.get_frames_drawn()) / FPS))
		await _drehbuch()
		_zuruecksichern()
		print("TRAILER FERTIG")
		get_tree().quit()

	## Spiel starten und warten, bis es wirklich da ist.
	## Nicht über Net.start_solo: das geht über den Ladebildschirm, und der
	## wechselt im Aufnahmemodus (--write-movie) nie weiter — das Werkzeug hat
	## dann stundenlang den Ladebildschirm gefilmt. Hier direkt in die Spielszene.
	func _spiel_starten() -> void:
		Net.solo = true
		Net.neues_spiel = true
		Net.slot = 1
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		get_tree().change_scene_to_file(Net.GAME_SCENE)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		gm = get_tree().current_scene
		if gm == null or not gm.has_method("net_book_tent"):
			push_error("Spielszene kam nicht hoch — Abbruch statt ins Leere filmen.")
			print("TRAILER ABBRUCH: keine Spielszene")
			get_tree().quit(1)
			return
		await _frames(30)

	# ------------------------------------------------------------ Aufbau
	func _aufbauen() -> void:
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
			if String(n.name).contains("Zielmarker") and n is CanvasItem:
				(n as CanvasItem).visible = false
			elif String(n.name).contains("Zielmarker") and n is Node3D:
				(n as Node3D).visible = false
		kamera = Camera3D.new()
		kamera.fov = 55.0
		gm.add_child(kamera)
		kamera.current = true
		# Koop-Spieler (werden wie Mitspieler angezeigt: Figur, Namensschild)
		var namen := [["Sepp", 0, 0], ["Resi", 2, 2], ["Toni", 1, 1]]
		for i in namen.size():
			gm._add_player(101 + i, i + 1)
			var p: Node3D = gm._players_nodes[101 + i]
			p.set_info(str(namen[i][0]), int(namen[i][1]), int(namen[i][2]))
			p._net_pos = Vector3(-30, 0, -30)
			p.global_position = p._net_pos
			spieler.append(p)

	func _grafik_aufwerten() -> void:
		var vp := get_viewport()
		vp.msaa_3d = Viewport.MSAA_4X
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		vp.scaling_3d_scale = 1.0
		env = (gm.get_node("WorldEnvironment") as WorldEnvironment).environment
		env.ssao_enabled = true
		env.ssao_intensity = 1.6
		env.ssao_radius = 1.2
		env.ssil_enabled = true
		env.ssil_intensity = 0.8
		env.adjustment_enabled = true
		attribute = CameraAttributesPractical.new()
		attribute.dof_blur_far_enabled = false
		attribute.dof_blur_far_distance = 28.0
		attribute.dof_blur_far_transition = 18.0
		attribute.dof_blur_amount = 0.06
		kamera.attributes = attribute

	## Beschriftungen im Spiel (Stationen, Künstler, Personal) stören im Video —
	## Zeltname, Mietschild und Namensschilder der Spieler bleiben.
	func _beschriftungen_aus() -> void:
		for l in gm.find_children("*", "Label3D", true, false):
			var lab := l as Label3D
			if lab.is_in_group("zeltname") or lab.name == "Namensschild" or lab.name == "Bubble":
				continue
			var p := lab.get_parent()
			if p and (p is ZeltVermietung or p.has_method("ist_eroeffnung")):
				continue
			lab.visible = false

	## Lichterfest-Look zur Uhrzeit, etwas kräftiger fürs Video.
	func _stimmung(uhr: float) -> void:
		gm._night_t = -1.0
		gm._apply_daylight(uhr)
		gm._apply_crowd(uhr)
		env.glow_enabled = true
		env.glow_intensity = lerpf(0.6, 1.2, clampf((uhr - 17.0) / 4.0, 0.0, 1.0))
		env.glow_bloom = lerpf(0.05, 0.15, clampf((uhr - 17.0) / 4.0, 0.0, 1.0))
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.008
		env.volumetric_fog_albedo = Color(1.0, 0.8, 0.58)
		env.tonemap_exposure = 1.15

	func _ueberlagerung_bauen() -> void:
		ebene = CanvasLayer.new()
		ebene.layer = 100
		add_child(ebene)
		schwarz = ColorRect.new()
		schwarz.color = Color.BLACK
		schwarz.set_anchors_preset(Control.PRESET_FULL_RECT)
		ebene.add_child(schwarz)
		titel = _label(88, 0.64)
		untertitel = _label(40, 0.76)
		titel.modulate.a = 0.0
		untertitel.modulate.a = 0.0
		zaehler = _label(64, 0.06)
		zaehler.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		zaehler.offset_right = -60.0
		zaehler.modulate.a = 0.0
		studio = Label.new()
		studio.set_anchors_preset(Control.PRESET_FULL_RECT)
		studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		studio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		studio.add_theme_font_size_override("font_size", 64)
		studio.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
		studio.text = "STEAMBOAT STUDIOS\n"
		studio.modulate.a = 0.0
		ebene.add_child(studio)
		studio_zeile = _label(40, 0.56)
		studio_zeile.text = "präsentiert"
		studio_zeile.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
		studio_zeile.modulate.a = 0.0
		var atlas := AtlasTexture.new()
		atlas.atlas = LOGO_BOGEN
		atlas.region = Rect2(24, 16, 1068, 318)
		logo = TextureRect.new()
		logo.texture = atlas
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.set_anchors_preset(Control.PRESET_FULL_RECT)
		logo.anchor_left = 0.18
		logo.anchor_right = 0.82
		logo.anchor_top = 0.12
		logo.anchor_bottom = 0.5
		logo.modulate.a = 0.0
		ebene.add_child(logo)

	func _label(groesse: int, oben: float) -> Label:
		var l := Label.new()
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		l.anchor_top = oben
		l.add_theme_font_override("font", FRAKTUR)
		l.add_theme_font_size_override("font_size", groesse)
		l.add_theme_color_override("font_color", Color(1.0, 0.88, 0.5))
		l.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.02))
		l.add_theme_constant_override("outline_size", 22 if groesse > 50 else 12)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		l.add_theme_constant_override("shadow_offset_y", 6)
		ebene.add_child(l)
		return l

	# ------------------------------------------------------------ Drehbuch
	func _drehbuch() -> void:
		# 0 Studio-Intro auf Schwarz
		var intro := create_tween().set_parallel()
		intro.tween_property(studio, "modulate:a", 1.0, 1.0)
		intro.tween_property(studio_zeile, "modulate:a", 1.0, 0.8).set_delay(0.9)
		await _warte(3.2)
		var aus := create_tween().set_parallel()
		aus.tween_property(studio, "modulate:a", 0.0, 0.7)
		aus.tween_property(studio_zeile, "modulate:a", 0.0, 0.7)
		_stimmung(17.4)
		_beschriftungen_aus()
		_kamera_auf(Vector3(-40.0, 26.0, 74.0), Vector3(0.0, 2.0, 10.0))
		await _warte(0.8)

		# 1 Kirmes am späten Nachmittag: Kranfahrt aufs leere Zelt zu
		_blende(0.0, 1.2)
		_titel("Die Wiesn ruft.", 0.8, 3.4)
		await _fahrt(Vector3(-40.0, 26.0, 74.0), Vector3(0.0, 2.0, 10.0),
			Vector3(-12.0, 8.0, 36.0), Vector3(2.0, 2.5, 13.0), 6.0)

		# 2 Zelt mieten: Schild verschwindet in Staub, Zeltname ploppt auf
		_titel("Miete dein eigenes Festzelt …", 0.2, 2.6)
		_fahrt(Vector3(9.0, 1.8, 20.5), Vector3(4.2, 1.4, 13.2),
			Vector3(6.5, 2.4, 19.0), Vector3(2.0, 3.2, 12.0), 5.0)
		await _warte(2.2)
		_staub(Vector3(4.2, 0.1, 13.2), 1.2, "ko")
		gm._tent_stage = 1
		gm._active_count = 2
		gm._zelt_name = ZELTNAME
		gm._apply_tent()
		gm._zeltname_anzeigen()
		for l in get_tree().get_nodes_in_group("zeltname"):
			_ploppen(l as Node3D, 0.6)
		_titel("… und gib ihm deinen Namen.", 0.1, 2.0)
		await _warte(2.8)

		# 3 Klein anfangen: 2 Tische, erste Gäste, Koop-Spieler tragen Krüge
		_stimmung(17.8)
		attribute.dof_blur_far_enabled = true
		attribute.dof_blur_far_distance = 14.0
		attribute.dof_blur_far_transition = 10.0
		gm._rebuild_seats()
		_titel("Klein anfangen.", 0.4, 3.4)
		await _gaeste_einlassen(6, 0.25)
		_spieler_laufen(0, Vector3(-3.0, 0.1, -8.0), Vector3(-0.8, 0.1, 1.0), 4.0, true)
		_spieler_laufen(1, Vector3(3.0, 0.1, -7.6), Vector3(1.4, 0.1, 1.8), 4.4, true)
		await _fahrt(Vector3(-5.0, 1.9, 7.0), Vector3(0.0, 0.9, 0.0),
			Vector3(3.5, 2.1, 6.0), Vector3(0.0, 0.9, 0.0), 6.0)

		# 4 Lieferwagen bringt Ware
		_titel("Ware ranschaffen.", 0.6, 2.6)
		_lieferwagen(4.5)
		_spieler_laufen(2, Vector3(-3.0, 0.1, 13.0), Vector3(0.5, 0.1, 15.0), 4.0, false)
		# Auf Wagen (haelt bei z 24,5) und Abladeplatz (z 21,4) zugleich schauen.
		# Von Osten heranfahren wurde ausprobiert und war schlechter: dort steckt
		# die Kamera im Dach einer Bude. Links ragt jetzt eine Bude ins Bild —
		# stoert weniger als eine schwarze Flaeche.
		await _fahrt(Vector3(-7.0, 5.5, 34.0), Vector3(0.0, 1.5, 23.0),
			Vector3(-5.0, 3.2, 29.5), Vector3(0.0, 1.0, 22.0), 5.0)

		# 5 Zeitraffer: 2 → 24 Tische, Gäste, Deko, Band, Abend
		_titel("… und groß rauskommen!", 0.8, 4.0)
		zaehler.text = "Tische: 2"
		create_tween().tween_property(zaehler, "modulate:a", 1.0, 0.4)
		_fahrt(Vector3(-2.5, 1.7, 9.6), Vector3(2.0, 1.0, -3.0),
			Vector3(-2.0, 5.2, 9.4), Vector3(1.0, 0.0, -4.0), 16.0)
		var uhr := 17.8
		for stufe_i in range(1, TISCH_STUFEN.size()):
			var stufe: Array = TISCH_STUFEN[stufe_i]
			await _tische_auf(int(stufe[0]), int(stufe[1]))
			zaehler.text = "Tische: %d" % int(stufe[0])
			_ploppen_ui(zaehler)
			match stufe_i:
				2:
					_deko_setzen(["lichtergirlande", "lichtergirlande"], [Vector2(-5.0, 1.0), Vector2(5.0, 1.0)])
				3:
					gm._artist_tier = 1
					gm._spawn_artists()
				4:
					_deko_setzen(["kronleuchter", "kronleuchter", "kronleuchter"], [Vector2(-6.0, -3.0), Vector2(0.0, -3.0), Vector2(6.0, -3.0)])
				5:
					gm._remove_artists()
					gm._artist_tier = 3
					gm._spawn_artists()
					# Keine Haengelaternen: die haengen auf 3,6 m und brauchen einen
					# Balken ueber sich. Frei in den Raum gesetzt schweben sie im Bild.
					_deko_setzen(["banner", "riesenbrezel"],
						[Vector2(-11.6, -2.0), Vector2(11.6, -6.0)])
			_beschriftungen_aus()
			for k in 20:
				uhr = minf(21.0, uhr + 0.02)
				_stimmung(uhr)
				await get_tree().process_frame
			await _warte(1.4)
		await _warte(1.0)
		create_tween().tween_property(zaehler, "modulate:a", 0.0, 0.5)

		# 6 Full House: Fahrt über die Reihen, Krüge an der Ausgabe, Kellner mit Tablett
		_stimmung(21.0)
		attribute.dof_blur_far_distance = 22.0
		attribute.dof_blur_far_transition = 16.0
		_titel("Full House!", 0.3, 3.0)
		await _fahrt(Vector3(-3.5, 4.4, 9.8), Vector3(4.0, 1.0, -3.0),
			Vector3(-2.5, 3.0, -1.5), Vector3(9.0, 1.4, 2.0), 5.0)
		attribute.dof_blur_far_distance = 3.0
		attribute.dof_blur_far_transition = 3.0
		_titel("Zapfen. Servieren. Kassieren.", 0.2, 3.4)
		_kruege_fuellen(3.6)
		await _fahrt(Vector3(-3.8, 1.55, -7.6), Vector3(-2.4, 1.0, -9.1),
			Vector3(-1.0, 1.45, -7.8), Vector3(-2.0, 1.05, -9.1), 4.0)
		attribute.dof_blur_far_distance = 10.0
		attribute.dof_blur_far_transition = 8.0
		var kellner := _kellner(Vector3(-6.0, 0.1, -6.8), Vector3(-6.0, 0.1, 6.0), 5.0)
		if kellner:
			await _folgen(kellner, Vector3(2.2, 1.9, 2.6), 5.0)

		# 7 Party: Tanz auf den Tischen, Band, Spieler tanzen mit
		_gaeste_tanzen()
		for p in spieler:
			p._net_pos = Vector3(randf_range(3.0, 7.0), 0.1, randf_range(-1.0, 5.0))
			p.global_position = p._net_pos
			p.carry_state = 1
			p.carry_fill = 1.0
			p.carry_type = 1
			p.emote = 1
		_titel("Bis die Bänke wackeln", 0.4, 3.2)
		var taenzer := _taenzer_ort()
		await _fahrt(taenzer + Vector3(-4.0, 2.4, 4.5), taenzer + Vector3(0, 1.2, 0),
			taenzer + Vector3(3.5, 1.8, 4.0), taenzer + Vector3(0, 1.3, 0), 5.0)
		await _fahrt(Vector3(4.5, 1.7, 5.5), Vector3(10.0, 1.6, 2.0),
			Vector3(6.0, 2.4, -1.5), Vector3(10.0, 1.6, 2.0), 3.5)
		for p in spieler:
			p.emote = 0

		# 8 Streit und Massenschlägerei
		attribute.dof_blur_far_distance = 8.0
		attribute.dof_blur_far_transition = 6.0
		_raufbolde_aufstellen()
		_titel("…und wenn's kracht,", 0.6, 2.6)
		raufbolde[0].streit_mit(raufbolde[1])
		await _fahrt(RAUF_MITTE + Vector3(-2.8, 1.5, 2.6), raufbolde[0].global_position + Vector3(0.6, 1.0, 0),
			RAUF_MITTE + Vector3(-1.6, 1.3, 2.2), raufbolde[0].global_position + Vector3(0.6, 1.0, 0), 3.5)
		var masse := MASSENSCHLAEGEREI.instantiate()
		masse.dauer = 14.0
		gm.add_child(masse)
		masse.starten(raufbolde, RAUF_MITTE, raufbolde.size())
		_titel("dann richtig.", 1.2, 3.0)
		await _kreisfahrt(RAUF_MITTE, 4.2, 2.4, deg_to_rad(200.0), deg_to_rad(20.0), 10.0)

		# 9 Rauswurf durch den Eingang
		masse.beenden()
		if gm._crowd:
			gm._crowd.set_density(0.05)
		for pid in gm._packages.keys():
			gm._remove_package(pid)
		var opfer := raufbolde[2]
		opfer.packen()
		opfer.global_position = Vector3(0.0, 0.5, 8.6)
		attribute.dof_blur_far_enabled = false
		_kamera_auf(Vector3(4.0, 2.2, 18.5), Vector3(0.0, 1.8, 12.0))
		_titel("Raus mit dir!", 0.2, 2.6)
		await _warte(0.4)
		opfer.werfen(Vector3(0.4, 6.0, 12.5))
		await _fahrt(Vector3(4.0, 2.2, 18.5), Vector3(0.0, 1.8, 12.0),
			Vector3(5.0, 2.0, 20.5), Vector3(0.3, 0.8, 17.5), 3.6)

		# 10 Abschluss: Nacht, Logo, Wunschliste, Studio
		_stimmung(22.2)
		_blende(0.55, 0.8)
		await _warte(0.8)
		_kamera_auf(Vector3(-8.0, 3.0, 32.0), Vector3(0.0, 4.5, 11.0))
		untertitel.anchor_top = 0.54
		untertitel.add_theme_font_size_override("font_size", 46)
		untertitel.text = "Das Festzelt-Chaos für 1–4 Spieler\nJetzt auf die Wunschliste!"
		studio_zeile.anchor_top = 0.86
		studio_zeile.add_theme_font_size_override("font_size", 30)
		studio_zeile.text = "Steamboat Studios"
		logo.pivot_offset = get_viewport().get_visible_rect().size * Vector2(0.5, 0.31)
		logo.scale = Vector2(0.9, 0.9)
		var tw := create_tween().set_parallel()
		tw.tween_property(logo, "modulate:a", 1.0, 1.0)
		tw.tween_property(logo, "scale", Vector2.ONE, 1.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(untertitel, "modulate:a", 1.0, 1.0).set_delay(1.0)
		tw.tween_property(studio_zeile, "modulate:a", 1.0, 1.0).set_delay(1.8)
		await _fahrt(Vector3(-8.0, 3.0, 32.0), Vector3(0.0, 4.5, 11.0),
			Vector3(-3.0, 3.6, 25.0), Vector3(0.0, 4.8, 11.0), 6.5)
		_blende(1.0, 1.0)
		await _warte(1.2)

	# ------------------------------------------------------------ Szenenbausteine
	## Neue Tische aufstellen: ploppen mit Staub auf, dann kommen Gäste für die neuen Plätze.
	func _tische_auf(anzahl: int, stufe: int) -> void:
		var vorher: int = gm._active_count
		gm._tent_stage = stufe
		gm._active_count = anzahl
		gm._apply_tent()
		gm._rebuild_seats()
		for i in range(vorher, anzahl):
			var t := gm._all_tables[i] as Node3D
			t.scale = Vector3(0.01, 0.01, 0.01)
			var tw := create_tween()
			tw.tween_interval(float(i - vorher) * 0.08)
			tw.tween_property(t, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func() -> void: _staub(t.global_position, 0.7, ""))
		await _warte(0.4)
		_gaeste_einlassen(mini(gm._seats.size(), 96) - gm._guest_sim.size(), 0.06)

	## Gäste kommen durch den Eingang und laufen zu ihrem Platz (nur Darstellung).
	func _gaeste_einlassen(anzahl: int, abstand: float) -> void:
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
			var start := EINLASS + Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-0.4, 0.8))
			knoten.position = start
			knoten.set_net(start, 0.0)
			var weg: Vector3 = ziel - start
			var dauer := clampf(weg.length() / 4.5, 0.6, 3.0)
			var tw := create_tween()
			tw.tween_method(func(v: Vector3) -> void:
				if is_instance_valid(knoten):
					knoten.set_net(v, atan2(-weg.x, -weg.z)), start, ziel, dauer)
			tw.tween_callback(func() -> void:
				if is_instance_valid(knoten):
					knoten.set_net(ziel, float(gm._seats[int(g.seat)].yaw)))
			if abstand > 0.0:
				await _warte(abstand)

	func _spieler_laufen(i: int, von: Vector3, nach: Vector3, dauer: float, mit_kruegen: bool) -> void:
		var p := spieler[i]
		p.global_position = von
		p._net_pos = von
		var r := nach - von
		p._net_yaw = atan2(-r.x, -r.z)
		p.rotation.y = p._net_yaw
		p.carry_state = 1 if mit_kruegen else 3
		p.carry_fill = 1.0
		p.carry_type = 1 + i
		p.carry_pkg_kind = 1
		p.extra_kruege.assign([2, 3] if mit_kruegen else [])
		create_tween().tween_property(p, "_net_pos", nach, dauer)

	func _lieferwagen(dauer: float) -> void:
		# Der Wagen fährt seit v179 eine Wegpunktliste ab (VAN_REIN/VAN_RAUS);
		# die alten Konstanten VAN_START/VAN_DROP/VAN_END gibt es nicht mehr.
		# Erster Punkt von VAN_REIN = Zufahrt, letzter = Halt, letzter von
		# VAN_RAUS = wieder weg.
		var start: Vector3 = gm.VAN_REIN[0][0]
		var halt: Vector3 = gm.VAN_REIN[gm.VAN_REIN.size() - 1][0]
		var weg: Vector3 = gm.VAN_RAUS[gm.VAN_RAUS.size() - 1][0]
		gm._van_show(true, start)
		var wagen: Node3D = gm._van_node
		var tw := create_tween()
		tw.tween_property(wagen, "position", halt, dauer * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			gm._van_honk()
			for k in 5:
				_paket_id += 1
				var ort: Vector3 = gm.DROP_POINT + Vector3(randf_range(-2.2, 2.2), 0.0, randf_range(-1.2, 1.2))
				gm._add_package(_paket_id, ort, 1 + (k % 2), 10)
				var paket: Node3D = gm._packages[_paket_id]
				_ploppen(paket, 0.4, float(k) * 0.12)
				_staub(ort, 0.5, "")
			# Die Pakete entstehen erst hier und bringen ihre eigenen Schilder
			# mit ("Bierfass x10 ([E]: aufnehmen)") — die lagen sonst quer
			# uebereinander mitten im Bild.
			_beschriftungen_aus())
		tw.tween_interval(dauer * 0.25)
		tw.tween_property(wagen, "position", weg, dauer).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void: gm._van_show(false, weg))

	func _deko_setzen(arten: Array, orte: Array) -> void:
		for k in arten.size():
			var art: String = arten[k]
			var ort: Vector2 = orte[k]
			var lage: Dictionary = gm._deko_platz(art, ort.x, ort.y, 0.0)
			_deko_id += 1
			gm._add_einrichtung(_deko_id, art, float(lage.x), float(lage.z), float(lage.rot))
			var knoten: Node3D = gm._einrichtung_nodes.get(_deko_id)
			if knoten:
				_ploppen(knoten, 0.5, float(k) * 0.15)

	func _kellner(von: Vector3, nach: Vector3, dauer: float) -> Node3D:
		_staff_id += 1
		gm._add_staff(_staff_id, von, gm.ROLE_KELLNER, 3)
		var container: Node = gm._staff_container
		if container.get_child_count() == 0:
			return null
		var k: Node3D = container.get_child(container.get_child_count() - 1)
		k.set_carrying(4)
		var r := nach - von
		var tw := create_tween()
		tw.tween_method(func(v: Vector3) -> void:
			if is_instance_valid(k):
				k.set_net(v, atan2(-r.x, -r.z)), von, nach, dauer)
		_beschriftungen_aus()
		return k

	## Tanz auf den Tischen wie im Spiel (GameManager._update_tanz), dann anzeigen.
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

	func _kruege_fuellen(dauer: float) -> void:
		var ausgabe := get_tree().get_first_node_in_group("ausgabe")
		if ausgabe == null:
			return
		ausgabe.set_inhalt({"1_1": 3, "1_2": 3, "1_3": 3, "1_4": 3, "2_1": 2, "2_2": 2, "2_3": 2})
		var kruege: Array = ausgabe.find_children("K*", "", true, false).filter(func(n: Node) -> bool: return n is Krug)
		var tw := create_tween()
		for i in kruege.size():
			(kruege[i] as Krug).fuellung = 0.0
			tw.parallel().tween_property(kruege[i], "fuellung", 1.0, 0.9).set_delay(float(i) * dauer / float(kruege.size()) * 0.8)

	func _taenzer_ort() -> Vector3:
		for c in get_tree().get_nodes_in_group("customer"):
			if c.has_method("tanzt") and c.tanzt():
				return (c as Node3D).global_position
		return Vector3(-4.0, 0.0, 0.0)

	func _raufbolde_aufstellen() -> void:
		for i in 22:
			var r := RAUFBOLD.instantiate()
			gm.add_child(r)
			var winkel := randf() * TAU
			var abstand := randf_range(0.4, 2.6)
			r.global_position = RAUF_MITTE + Vector3(cos(winkel) * abstand * 1.4, 0.0, sin(winkel) * abstand * 0.9)
			r.rotation.y = randf() * TAU
			r.figur_setzen(Figuren.ALLE[i % Figuren.ALLE.size()])
			r.flucht_ziel = Vector3(randf_range(-2.0, 2.0), 0.0, 20.0)
			raufbolde.append(r)

	# ------------------------------------------------------------ Kamera, Titel, Effekte
	func _titel(text: String, verzug: float, dauer: float) -> void:
		titel.text = text
		titel.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(verzug)
		tw.tween_property(titel, "modulate:a", 1.0, 0.45)
		tw.tween_interval(dauer)
		tw.tween_property(titel, "modulate:a", 0.0, 0.5)

	func _blende(ziel: float, dauer: float) -> void:
		create_tween().tween_property(schwarz, "color:a", ziel, dauer)

	func _ploppen(n: Node3D, dauer: float, verzug := 0.0) -> void:
		if n == null:
			return
		var ende := n.scale
		n.scale = ende * 0.01
		var tw := create_tween()
		tw.tween_interval(verzug)
		tw.tween_property(n, "scale", ende, dauer).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _ploppen_ui(c: Control) -> void:
		c.pivot_offset = Vector2(c.size.x - 200.0, 40.0)
		c.scale = Vector2(1.25, 1.25)
		create_tween().tween_property(c, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _staub(ort: Vector3, staerke: float, ton: String) -> void:
		var s := STAUB.instantiate()
		gm.add_child(s)
		s.global_position = Vector3(ort.x, maxf(0.02, ort.y), ort.z)
		s.ausloesen(staerke, ton)

	## Weiche Kamerafahrt zwischen zwei Einstellungen (Ort und Blickziel).
	func _fahrt(von: Vector3, von_ziel: Vector3, nach: Vector3, nach_ziel: Vector3, dauer: float) -> void:
		# Jede neue Kamerabewegung löst die vorige ab (Fahrten laufen teils nebenher)
		_bahn_nr += 1
		var nr := _bahn_nr
		var t := 0.0
		while t < dauer:
			if nr != _bahn_nr:
				return
			var k := smoothstep(0.0, 1.0, t / dauer)
			_kamera_auf(von.lerp(nach, k), von_ziel.lerp(nach_ziel, k))
			await get_tree().process_frame
			t += get_process_delta_time()
		if nr == _bahn_nr:
			_kamera_auf(nach, nach_ziel)

	## Kamera folgt einem Knoten mit festem Versatz.
	func _folgen(ziel: Node3D, versatz: Vector3, dauer: float) -> void:
		_bahn_nr += 1
		var t := 0.0
		while t < dauer and is_instance_valid(ziel):
			_kamera_auf(ziel.global_position + versatz, ziel.global_position + Vector3(0, 1.2, 0))
			await get_tree().process_frame
			t += get_process_delta_time()

	func _kreisfahrt(mitte: Vector3, radius: float, hoehe: float, von_winkel: float, nach_winkel: float, dauer: float) -> void:
		_bahn_nr += 1
		var t := 0.0
		while t < dauer:
			var w := lerpf(von_winkel, nach_winkel, t / dauer)
			var r := radius + sin(t * 0.7) * 0.6
			_kamera_auf(mitte + Vector3(cos(w) * r, hoehe + sin(t * 0.5) * 0.4, sin(w) * r), mitte + Vector3(0, 0.9, 0))
			await get_tree().process_frame
			t += get_process_delta_time()

	func _kamera_auf(ort: Vector3, ziel: Vector3) -> void:
		kamera.global_position = ort
		if ort.distance_to(ziel) > 0.01:
			kamera.look_at(ziel)

	func _warte(s: float) -> void:
		await get_tree().create_timer(s).timeout

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame

	# ------------------------------------------------------------ Spielstände
	func _sichern() -> void:
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".trailerbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".trailerbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".trailerbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".trailerbackup"))

	func _zuruecksichern() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".trailerbackup", echt)
				DirAccess.remove_absolute(echt + ".trailerbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
