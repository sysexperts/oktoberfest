extends CanvasLayer
## Leistungsanzeige: F3 blendet oben rechts Bildrate, Bildzeit und die Aufteilung ein (Skripte, Physik,
## Render-CPU, GPU), dazu Zeichenaufrufe, Objekte, Auflösung und Grafikstufe. Zum Messen am echten Rechner
## (Aufbau: autoload/leistungsanzeige.tscn). Zeigt nichts und kostet nichts, solange sie aus ist.

const INTERVALL := 0.5

## Misst die echte Skriptzeit eines Bildes: eine Marke läuft als Erste, eine als Letzte (Priorität).
## Godots eigene Zahl TIME_PROCESS enthält den ganzen Bildaufbau samt Warten auf die Grafikkarte.
class Marke extends Node:
	var zeit := 0
	## Nur bei der letzten Marke: Dauer seit der ersten (µs)
	var erste: Marke = null
	var dauer := 0
	func _process(_delta: float) -> void:
		zeit = Time.get_ticks_usec()
		if erste != null:
			dauer = zeit - erste.zeit

var _anfang: Marke
var _ende: Marke
var _skript_ms := 0.0
@onready var _text: Label = $Rand/Text
var _t := 0.0

func _ready() -> void:
	layer = 120
	visible = false
	_anfang = Marke.new()
	_anfang.process_priority = -2147483647
	add_child(_anfang)
	_ende = Marke.new()
	_ende.process_priority = 2147483647
	_ende.erste = _anfang
	add_child(_ende)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F3 and _ergebnis_steht:
		_ergebnis_steht = false
		_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F4:
		_taste_f4()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F3:
		visible = not visible
		_t = INTERVALL
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), visible)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible:
		return
	# Letztes Bild: Ende minus Anfang der Verarbeitung (geglättet)
	var roh := float(_ende.dauer) / 1000.0
	if roh >= 0.0 and roh < 1000.0:
		_skript_ms = lerpf(_skript_ms, roh, 0.1)
	if _test_laeuft or _ergebnis_steht:
		return
	_t += delta
	if _t < INTERVALL:
		return
	_t = 0.0
	var vp := get_viewport()
	var rid := vp.get_viewport_rid()
	var fps := Engine.get_frames_per_second()
	var groesse := Vector2(DisplayServer.window_get_size()) * vp.scaling_3d_scale
	var fenster := DisplayServer.window_get_size()
	_text.text = "%d FPS  ·  %.1f ms\
Skripte(echt) %.1f  Physik %.1f  Render-CPU %.1f  GPU %.1f ms\
Aufrufe %d  ·  Objekte %d  ·  Dreiecke %.1f Mio.\
Bild %dx%d (3D %dx%d)  ·  Grafik %d  ·  %s" % [
		fps, 1000.0 / maxf(1.0, float(fps)),
		_skript_ms,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(rid),
		RenderingServer.viewport_get_measured_render_time_gpu(rid),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		float(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)) / 1000000.0,
		fenster.x, fenster.y, int(groesse.x), int(groesse.y), Einstellungen.grafik,
		RenderingServer.get_video_adapter_name()]

## ------------------------------------------------------------ Selbsttest (F4)
## Misst auf dem eigenen Rechner, was die einzelnen Teile kosten: schaltet je einen Teil ab, misst die Bildzeit
## und stellt alles wieder her. Dauert rund eine Minute, das Ergebnis steht als Liste im Bild und in
## user://leistungstest.txt. Nur im Spiel (Spielszene), nicht im Menü.
var _test_laeuft := false
var _test_zeilen: PackedStringArray = []
## Nach dem Test bleibt die Liste stehen, bis F3 gedrückt wird
var _ergebnis_steht := false

func _taste_f4() -> void:
	if _test_laeuft:
		return
	var welt := get_tree().current_scene
	if welt == null or not welt.has_method("net_book_tent"):
		return
	visible = true
	_selbsttest(welt)

func _bildzeit(s: float) -> float:
	var t := 0.0
	var f := 0
	await get_tree().create_timer(0.8).timeout   # kurz einschwingen
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
		f += 1
	return t / maxf(1.0, float(f)) * 1000.0

func _selbsttest(welt: Node) -> void:
	_test_laeuft = true
	_test_zeilen = PackedStringArray()
	var vp := get_viewport()
	var we := welt.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var lichter: Array = welt.find_children("*", "Light3D", true, false).filter(func(l): return not (l is DirectionalLight3D))
	var sonne := welt.get_node_or_null("Sun") as Light3D
	var karte := welt.get_node_or_null("Kirmes/Karte") as Node3D
	var zelt := welt.get_node_or_null("Tent") as Node3D
	var filter := welt.get_node_or_null("Bildfilter") as CanvasLayer
	var hud := welt.get_node_or_null("HUD") as CanvasLayer
	var figuren: Array = welt.find_children("*", "Skeleton3D", true, false)
	var basis := await _bildzeit(3.0)
	_test_zeilen.append("Grundwert  %.1f ms  (%d FPS)" % [basis, roundi(1000.0 / basis)])
	_zeige_test(basis, "")
	# jeder Eintrag: [Name, Abschalten, Wiederherstellen]
	var env: Environment = we.environment if we else null
	var env_alt := {}
	if env:
		env_alt = {"ssao": env.ssao_enabled, "ssil": env.ssil_enabled, "glow": env.glow_enabled, "fog": env.fog_enabled, "adj": env.adjustment_enabled}
	var msaa_alt := vp.msaa_3d
	var aa_alt := vp.screen_space_aa
	var scale_alt := vp.scaling_3d_scale
	var schritte := [
		["ohne Lichter (%d)" % lichter.size(), func() -> void: for l in lichter: (l as Light3D).visible = false,
			func() -> void: for l in lichter: (l as Light3D).visible = true],
		["ohne Sonne", func() -> void: sonne.visible = false, func() -> void: sonne.visible = true],
		["ohne Kantenglättung", func() -> void: vp.msaa_3d = Viewport.MSAA_DISABLED; vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED,
			func() -> void: vp.msaa_3d = msaa_alt; vp.screen_space_aa = aa_alt],
		["ohne Effekte (SSAO, SSIL, Glow, Nebel, Farbe)", func() -> void:
				if env:
					env.ssao_enabled = false; env.ssil_enabled = false; env.glow_enabled = false; env.fog_enabled = false; env.adjustment_enabled = false,
			func() -> void:
				if env:
					env.ssao_enabled = env_alt.ssao; env.ssil_enabled = env_alt.ssil; env.glow_enabled = env_alt.glow; env.fog_enabled = env_alt.fog; env.adjustment_enabled = env_alt.adj],
		["ohne HUD und Bildfilter", func() -> void:
				if hud: hud.visible = false
				if filter: filter.visible = false,
			func() -> void:
				if hud: hud.visible = true
				if filter: filter.visible = true],
		["ohne Besucher", func() -> void: for v in get_tree().get_nodes_in_group("visitor"): (v as Node3D).visible = false,
			func() -> void: for v in get_tree().get_nodes_in_group("visitor"): (v as Node3D).visible = true],
		["ohne alle Figuren (%d)" % figuren.size(), func() -> void: for f in figuren: (f as Node3D).visible = false,
			func() -> void: for f in figuren: (f as Node3D).visible = true],
		["ohne Kirmes (Buden, Bäume)", func() -> void: if karte: karte.visible = false,
			func() -> void: if karte: karte.visible = true],
		["ohne Zelt", func() -> void: if zelt: zelt.visible = false, func() -> void: if zelt: zelt.visible = true],
		["3D-Auflösung 50 %", func() -> void: vp.scaling_3d_scale = 0.5, func() -> void: vp.scaling_3d_scale = scale_alt],
	]
	for st: Array in schritte:
		(st[1] as Callable).call()
		var ms := await _bildzeit(2.5)
		(st[2] as Callable).call()
		_test_zeilen.append("%-46s %5.1f ms  (%+.1f)" % [st[0], ms, ms - basis])
		_zeige_test(basis, st[0])
	_test_zeilen.append("Fertig. Screenshot an Claude schicken.")
	_zeige_test(basis, "")
	var f := FileAccess.open("user://leistungstest.txt", FileAccess.WRITE)
	if f:
		f.store_string("
".join(_test_zeilen) + "
")
	print("[Leistungstest]
", "
".join(_test_zeilen))
	_test_laeuft = false
	_ergebnis_steht = true

func _zeige_test(_basis: float, aktuell: String) -> void:
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var kopf := "LEISTUNGSTEST" + ("  — misst: " + aktuell if aktuell != "" else "")
	_text.text = kopf + "
" + "
".join(_test_zeilen)
