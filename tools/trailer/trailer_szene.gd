extends Node3D
## Eine Trailer-Szene: Kamerafahrt durchs echte Spiel.
##
## Aufbau (siehe tools/trailer/szene_01.tscn):
##   Kamerafahrt (Path3D)   — die Fahrt, Punkte im Editor ziehen
##     Wagen (PathFollow3D) — Regler progress_ratio = Stelle der Fahrt
##       Kamera             — schaut immer auf das Blickziel
##   Blickziel (Marker3D)   — dorthin schaut die Kamera
##   Vorschau               — Spielwelt als Kulisse, nur im Editor
##
## Anschauen im Editor: Kamera auswählen, oben im 3D-Fenster „Vorschau“
## anhaken, dann am Wagen den Regler progress_ratio ziehen.
## Abspielen in Echtzeit: Szene offen, F6 (läuft in Schleife, Esc beendet).
## Rendern: bash tools/trailer/render.sh 01
##
## Spielstände und Einstellungen werden vorher gesichert und danach
## zurückgeschrieben — die Szene startet ein neues Spiel.

const Spielstart := preload("res://tools/spielstart.gd")

## Länge der Fahrt in Sekunden
@export var dauer := 6.0
## Anfahren und Abbremsen weich statt gleichmäßig
@export var weich := true
## Uhrzeit fürs Licht (8 = Morgen, 13 = Mittag, 20 = Abend, 22 = Nacht)
@export_range(6.0, 23.5, 0.25) var uhr := 8.0
## Besucher draußen (0 = leer, 1 = voll)
@export_range(0.0, 1.0, 0.05) var besucher := 0.0
## Brennweite: kleiner = weiter Blick
@export_range(20.0, 90.0, 1.0) var sichtfeld := 55.0
## Schärfentiefe: ab dieser Entfernung wird es unscharf (0 = aus)
@export var unscharf_ab := 0.0
## Dunst in der Luft (Morgennebel)
@export_range(0.0, 0.05, 0.001) var dunst := 0.01

func _ready() -> void:
	var lauf := Lauf.new()
	lauf.einstellungen = {"dauer": dauer, "weich": weich, "uhr": uhr, "besucher": besucher,
		"sichtfeld": sichtfeld, "unscharf_ab": unscharf_ab, "dunst": dunst,
		"name": String(scene_file_path.get_file().get_basename())}
	# Fahrt und Blickziel überleben den Szenenwechsel beim Spielstart
	for n in ["Kamerafahrt", "Blickziel"]:
		var k := get_node(n) as Node3D
		var t := k.global_transform
		remove_child(k)
		lauf.add_child(k)
		k.transform = t
	get_node("Vorschau").queue_free()
	get_tree().root.add_child.call_deferred(lauf)


class Lauf extends Node:
	const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
		"user://einstellungen.cfg"]

	var einstellungen := {}
	var _gesichert := {}
	var _aufnahme := false
	var _schwarz: ColorRect

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_aufnahme = "--aufnahme" in OS.get_cmdline_user_args()
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
		for i in 30:
			await get_tree().process_frame
		_schwarz.visible = false
		var wagen := get_node("Kamerafahrt/Wagen") as PathFollow3D
		while true:
			if _aufnahme:
				print("SZENE_START %d" % Engine.get_frames_drawn())
			await _fahren(wagen, kamera)
			if _aufnahme:
				print("SZENE_ENDE %d" % Engine.get_frames_drawn())
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
		# Licht und Besucher
		gm._night_t = -1.0
		gm._apply_daylight(float(einstellungen.uhr))
		gm.get_node("Crowd").set_density(float(einstellungen.besucher))
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
		env.glow_enabled = true
		env.glow_intensity = 0.7
		env.glow_bloom = 0.06
		env.volumetric_fog_enabled = float(einstellungen.dunst) > 0.0
		env.volumetric_fog_density = float(einstellungen.dunst)
		env.volumetric_fog_albedo = Color(1.0, 0.86, 0.7)
		env.tonemap_exposure = 1.1
		var attr := CameraAttributesPractical.new()
		attr.dof_blur_far_enabled = float(einstellungen.unscharf_ab) > 0.0
		attr.dof_blur_far_distance = float(einstellungen.unscharf_ab)
		attr.dof_blur_far_transition = float(einstellungen.unscharf_ab) * 0.6
		attr.dof_blur_amount = 0.06
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
