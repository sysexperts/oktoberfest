extends Node3D
## Eine Trailer-Szene: Kamerafahrt durchs echte Spiel.
##
## Aufbau (siehe tools/trailer/szene_01.tscn):
##   Kamerafahrt (Path3D)   — die Fahrt, Punkte im Editor ziehen
##     Wagen (PathFollow3D) — Regler progress_ratio = Stelle der Fahrt
##       Kamera             — schaut immer auf das Blickziel
##   Blickziel (Marker3D)   — dorthin schaut die Kamera
##   Vorschau               — Spielwelt als Kulisse, nur im Editor
##   (optional) Ansturm     — tools/trailer/ansturm.gd: rennende Horde
##
## Anschauen im Editor: Kamera auswählen, oben im 3D-Fenster „Vorschau“
## anhaken, dann am Wagen den Regler progress_ratio ziehen.
## Abspielen in Echtzeit: Szene offen, F6 (läuft in Schleife, Esc beendet).
## Prüfen (vor dem Rendern!): bash tools/trailer/pruefen.sh 01 — meldet, wo die
##   Kamera in Bäumen/Buden steckt oder die Sicht aufs Blickziel verdeckt ist.
## Rendern: bash tools/trailer/render.sh 01
##
## Spielstände und Einstellungen werden vorher gesichert und danach
## zurückgeschrieben — die Szene startet ein neues Spiel.

const Spielstart := preload("res://tools/spielstart.gd")
const Besucher := preload("res://scripts/visitor.gd")
## So heißt das Zelt im Trailer
const ZELTNAME := "Sloptoberfest"

## Länge der Fahrt in Sekunden
@export var dauer := 6.0
## Anfahren und Abbremsen weich statt gleichmäßig
@export var weich := true
## Uhrzeit fürs Licht (8 = Morgen, 13 = Mittag, 20 = Abend, 22 = Nacht)
@export_range(6.0, 23.5, 0.25) var uhr := 8.0
## Besucher draußen (0 = leer, 1 = voll)
@export_range(0.0, 1.0, 0.05) var besucher := 0.0
## So viele Besucher sind „voll“ (im Spiel je nach Grafikstufe 150–450)
@export var max_besucher := 700
## Vorlauf in Sekunden, bevor die Aufnahme beginnt — Besucher erscheinen und
## verteilen sich, damit niemand im Bild auftaucht
@export var vorlauf := 1.0
## Brennweite: kleiner = weiter Blick
@export_range(20.0, 90.0, 1.0) var sichtfeld := 55.0
## Schärfentiefe: ab dieser Entfernung wird es unscharf (0 = aus)
@export var unscharf_ab := 45.0
## Wie stark es dahinter verschwimmt
@export_range(0.0, 0.3, 0.005) var unschaerfe := 0.12
## Dunst in der Luft (Morgennebel)
@export_range(0.0, 0.05, 0.001) var dunst := 0.01

func _ready() -> void:
	var lauf := Lauf.new()
	lauf.einstellungen = {"dauer": dauer, "weich": weich, "uhr": uhr, "besucher": besucher, "max_besucher": max_besucher, "vorlauf": vorlauf,
		"sichtfeld": sichtfeld, "unscharf_ab": unscharf_ab, "unschaerfe": unschaerfe, "dunst": dunst,
		"name": String(scene_file_path.get_file().get_basename())}
	# Alles außer der Editor-Vorschau (Fahrt, Blickziel, Ansturm …) überlebt
	# den Szenenwechsel beim Spielstart
	get_node("Vorschau").free()
	for k in get_children():
		var t := (k as Node3D).global_transform if k is Node3D else Transform3D()
		remove_child(k)
		lauf.add_child(k)
		if k is Node3D:
			(k as Node3D).transform = t
	get_tree().root.add_child.call_deferred(lauf)


class Lauf extends Node:
	const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
		"user://einstellungen.cfg"]

	var einstellungen := {}
	var _gesichert := {}
	var _aufnahme := false
	var _pruefen := false
	var _hindernisse: Array = []   # [AABB, Name]
	var _meldungen := {}
	## So nah darf die Kamera an keine Figur (m)
	const MIN_ABSTAND := 3.0
	var _schwarz: ColorRect

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_aufnahme = "--aufnahme" in OS.get_cmdline_user_args() or "--pruefen" in OS.get_cmdline_user_args()
		_pruefen = "--pruefen" in OS.get_cmdline_user_args()
		var ebene := CanvasLayer.new()
		ebene.layer = 100
		add_child(ebene)
		_schwarz = ColorRect.new()
		_schwarz.color = Color.BLACK
		_schwarz.set_anchors_preset(Control.PRESET_FULL_RECT)
		ebene.add_child(_schwarz)
		_sichern()
		TranslationServer.set_locale("de")
		var gm := await Spielstart.starten(self)
		if gm == null:
			_zuruecksichern()
			get_tree().quit(1)
			return
		var kamera := get_node("Kamerafahrt/Wagen/Kamera") as Camera3D
		_aufbauen(gm, kamera)
		var ablaeufe := find_children("*", "", false, false).filter(func(n: Node) -> bool: return n.has_method("aufstellen"))
		for a in ablaeufe:
			a.aufstellen()
		# Vorlauf: bei der Aufnahme in Bildern (feste 60 fps), sonst in echter Zeit
		if _aufnahme:
			for i in 30 + int(float(einstellungen.vorlauf) * 60.0):
				await get_tree().process_frame
		else:
			await get_tree().create_timer(0.5 + float(einstellungen.vorlauf)).timeout
		_schwarz.visible = false
		var wagen := get_node("Kamerafahrt/Wagen") as PathFollow3D
		var erste := true
		while true:
			for a in ablaeufe:
				if not erste:
					a.zuruecksetzen()
				a.starten()
			erste = false
			if _aufnahme:
				print("SZENE_START %d" % Engine.get_frames_drawn())
			await _fahren(wagen, kamera)
			if _aufnahme:
				print("SZENE_ENDE %d" % Engine.get_frames_drawn())
				if _pruefen:
					print("PRUEFUNG: %s" % ("SAUBER" if _meldungen.is_empty() else "%d Stellen" % _meldungen.size()))
				break
			# Vorschau: kurz stehen bleiben, dann von vorn
			await get_tree().create_timer(1.0).timeout
		_zuruecksichern()
		get_tree().quit()

	func _fahren(wagen: PathFollow3D, kamera: Camera3D) -> void:
		var dauer := float(einstellungen.dauer)
		var t := 0.0
		while t < dauer:
			var a := t / dauer
			wagen.progress_ratio = smoothstep(0.0, 1.0, a) if einstellungen.weich else a
			kamera.look_at((get_node("Blickziel") as Node3D).global_position, Vector3.UP)
			if _pruefen:
				_kamera_pruefen(kamera, t)
			await get_tree().process_frame
			# Bei der Aufnahme läuft die Zeit in festen Schritten (--write-movie)
			t += get_process_delta_time()
		wagen.progress_ratio = 1.0

	func _aufbauen(gm: Node, kamera: Camera3D) -> void:
		gm.set_process(false)   # Uhr und Besucherzahl nicht vom Spiel überschreiben lassen
		gm.get_node("HUD").visible = false
		var eigen: Node3D = gm.get_node("Players").get_child(0)
		eigen.set_physics_process(false)
		eigen.visible = false
		for n in gm.find_children("*Zielmarker*", "", true, false):
			if n is CanvasItem or n is Node3D:
				n.visible = false
		for l in gm.find_children("*", "Label3D", true, false):
			if not (l as Label3D).is_in_group("zeltname"):
				(l as Label3D).visible = false
		kamera.current = true
		kamera.fov = float(einstellungen.sichtfeld)
		# Zeltname am Eingang und über der Theke
		gm._zelt_name = ZELTNAME
		gm._zeltname_anzeigen()
		for l in gm.get_tree().get_nodes_in_group("zeltname"):
			(l as Label3D).visible = true
		# Keine Sichtweite: im Spiel werden ferne Teile, Lichter und Besucher
		# ausgeblendet (Leistung) — die Aufnahme darf sich Zeit lassen
		for g in gm.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).visibility_range_end = 0.0
		for l in gm.find_children("*", "Light3D", true, false):
			(l as Light3D).distance_fade_enabled = false
		Besucher.sichtbar_bis = INF
		var sonne := gm.find_children("*", "DirectionalLight3D", true, false)
		for s in sonne:
			(s as DirectionalLight3D).directional_shadow_max_distance = 250.0
		# Licht und Besucher
		gm._night_t = -1.0
		gm._apply_daylight(float(einstellungen.uhr))
		var menge := gm.get_node("Crowd")
		menge.max_visitors = int(einstellungen.max_besucher)
		menge.set_density(float(einstellungen.besucher))
		# Film-Look (verändert das Spiel nicht)
		var vp := get_viewport()
		vp.msaa_3d = Viewport.MSAA_4X
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		vp.scaling_3d_scale = 1.0
		var env := (gm.get_node("WorldEnvironment") as WorldEnvironment).environment
		env.ssao_enabled = true
		env.ssao_intensity = 1.6
		env.ssao_radius = 1.2
		env.ssil_enabled = true
		env.ssil_intensity = 0.8
		env.adjustment_enabled = true
		env.adjustment_saturation = 1.15
		env.adjustment_contrast = 1.06
		env.glow_enabled = true
		env.glow_intensity = 1.0
		env.glow_strength = 1.1
		env.glow_bloom = 0.18
		env.glow_hdr_threshold = 0.85
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		env.volumetric_fog_enabled = float(einstellungen.dunst) > 0.0
		env.volumetric_fog_density = float(einstellungen.dunst)
		env.volumetric_fog_albedo = Color(1.0, 0.86, 0.7)
		env.tonemap_exposure = 1.1
		var attr := CameraAttributesPractical.new()
		attr.dof_blur_far_enabled = float(einstellungen.unscharf_ab) > 0.0
		attr.dof_blur_far_distance = float(einstellungen.unscharf_ab)
		attr.dof_blur_far_transition = float(einstellungen.unscharf_ab) * 0.6
		attr.dof_blur_amount = float(einstellungen.unschaerfe)
		kamera.attributes = attr

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
			_zuruecksichern()
			get_tree().quit()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
			_zuruecksichern()

	func _sichern() -> void:
		for f: String in DATEIEN:
			_gesichert[f] = FileAccess.get_file_as_bytes(f) if FileAccess.file_exists(f) else null

	func _zuruecksichern() -> void:
		if _gesichert.is_empty():
			return
		for f: String in _gesichert:
			if _gesichert[f] == null:
				if FileAccess.file_exists(f):
					DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
			else:
				var d := FileAccess.open(f, FileAccess.WRITE)
				if d:
					d.store_buffer(_gesichert[f])
					d.close()
		_gesichert.clear()

	# ------------------------------------------------------------ Prüfung
	## Alle sichtbaren Teile als Kästen sammeln — Boden, Straßen, Stadt und die
	## Figuren (Besucher, Horde) zählen nicht. Kästen sind großzügig: eine
	## Baumkrone füllt ihren Kasten nicht ganz, aber lieber zu vorsichtig.
	func _hindernisse_sammeln(gm: Node) -> void:
		_hindernisse.clear()
		for g in gm.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if not gi.is_visible_in_tree() or _ist_figur(gi):
				continue
			var box := gi.global_transform * gi.get_aabb()
			if box.size.y < 0.5 or box.size.x > 45.0 or box.size.z > 45.0 or box.position.y > 40.0:
				continue
			_hindernisse.append([box, _name(gi)])

	func _ist_figur(n: Node) -> bool:
		var p := n.get_parent()
		while p != null:
			if p is Figur or p.name == "Crowd":
				return true
			p = p.get_parent()
		return false

	func _name(n: Node) -> String:
		# Kartenteile heißen K123 — den Szenennamen dazu, damit man weiß, was es ist
		var p := n
		while p != null and not String(p.name).begins_with("K"):
			p = p.get_parent()
		if p and p.scene_file_path != "":
			return "%s (%s)" % [p.scene_file_path.get_file().get_basename(), p.name]
		return String(n.name)

	func _kamera_pruefen(kamera: Camera3D, t: float) -> void:
		if _hindernisse.is_empty():
			_hindernisse_sammeln(get_tree().current_scene)
			print("  (%d Hindernisse erfasst)" % _hindernisse.size())
		var pos := kamera.global_position
		var ziel := (get_node("Blickziel") as Node3D).global_position
		var weg := ziel - pos
		# die letzten 3 m vor dem Blickziel stehen die Figuren selbst
		var ende := pos + weg * maxf(0.0, 1.0 - 3.0 / maxf(weg.length(), 0.01))
		# Nicht zu nah an Figuren: Animationen halten keine Nahaufnahme aus
		for f in find_children("*", "Node3D", true, false):
			if f is Figur and (f as Figur).visible:
				var d := (f as Figur).global_position + Vector3(0, 1.0, 0)
				if d.distance_to(pos) < MIN_ABSTAND:
					var sch := "zu nah %d" % int(t)
					if not _meldungen.has(sch):
						_meldungen[sch] = t
						print("  t=%.2f s: Kamera nur %.1f m von einer Figur" % [t, d.distance_to(pos)])
					break
		for h in _hindernisse:
			var box: AABB = h[0]
			var art := ""
			if box.grow(0.4).has_point(pos):
				art = "Kamera steckt in"
			elif box.intersects_segment(pos, ende):
				art = "Sicht verdeckt durch"
			if art == "":
				continue
			var schluessel := art + " " + str(h[1])
			if not _meldungen.has(schluessel):
				_meldungen[schluessel] = t
				print("  t=%.2f s: %s %s (Kasten %s bis %s, Kamera %s)" % [t, art, h[1], box.position.snapped(Vector3.ONE * 0.1), box.end.snapped(Vector3.ONE * 0.1), pos.snapped(Vector3.ONE * 0.1)])
