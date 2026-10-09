extends Control
## Computer-Desktop im Festbüro (Plan: docs/PLAN_STORY.md, Bauplan P2). Aufbau in scenes/ui/desktop.tscn.
## Sieht aus wie ein PC: Hintergrundbild, Symbole links, verschiebbare Fenster, unten eine Taskleiste mit Startmenü, Mail-Anzeige,
## und Uhr. Eigene Optik (bayerisches Rautenmuster, Holz und Gold), nichts von einem fremden Betriebssystem.
## E-Mail und Quests laufen als eigene Apps in den Fenstern. Festbüro (Shop, Personal, Bilanz) und Zeltcomputer (Bierpreis & Ware)
## sind die bestehenden Fenster und werden zum Öffnen in ein Desktop-Fenster eingebettet. Der Kalender öffnet wie bisher.
## Beim Öffnen fährt die Kamera kurz auf den Bildschirm zu.

const Fokus := preload("res://scripts/ui/fokus.gd")
const Texte := preload("res://scripts/ui/texte.gd")
const ICON_PFAD := "res://assets/ui/desktop/icon_%s.png"
const FENSTER := preload("res://scenes/ui/desktop_fenster.tscn")
const TASK := preload("res://scenes/ui/task_knopf.tscn")
const MAIL := preload("res://scenes/ui/desktop_mail.tscn")
const QUESTS := preload("res://scenes/ui/desktop_quests.tscn")
const BANK := preload("res://scenes/ui/desktop_bank.tscn")
const WETTER := preload("res://scenes/ui/desktop_wetter.tscn")
const SOCIAL := preload("res://scenes/ui/desktop_social.tscn")
const FEST := preload("res://scenes/ui/desktop_fest.tscn")
const WAGEN := preload("res://scenes/ui/desktop_wagen.tscn")
const AUSBAU := preload("res://scenes/ui/desktop_ausbau.tscn")
const KALENDER := preload("res://scenes/ui/desktop_kalender.tscn")
const BALD := preload("res://scenes/ui/desktop_bald.tscn")

## App → [Titel-Schlüssel, Symbolname, Größe des Inhalts, Art]; Art: intern = eigene Szene, legacy = bestehendes Fenster, bald = Platzhalter
const APPS := {
	"mail": ["DESKTOP_APP_MAIL", "papier", Vector2(980, 620), "intern"],
	"quests": ["DESKTOP_APP_QUESTS", "buch", Vector2(780, 620), "intern"],
	"shop": ["DESKTOP_APP_SHOP", "kiste", Vector2(1210, 770), "legacy"],
	"personal": ["DESKTOP_APP_PERSONAL", "person", Vector2(1210, 770), "legacy"],
	"bilanz": ["DESKTOP_APP_BILANZ", "diagramm", Vector2(1210, 770), "legacy"],
	"bierpreis": ["DESKTOP_APP_BIERPREIS", "bier", Vector2(1260, 880), "legacy"],
	"kalender": ["DESKTOP_APP_KALENDER", "kalender", Vector2(980, 780), "intern"],
	"bank": ["DESKTOP_APP_BANK", "bank", Vector2(960, 860), "intern"],
	"wetter": ["DESKTOP_APP_WETTER", "ausruf", Vector2(980, 780), "intern"],
	"social": ["DESKTOP_APP_SOCIAL", "megafon", Vector2(980, 760), "intern"],
	"fest": ["DESKTOP_APP_FEST", "stern", Vector2(1000, 800), "intern"],
	"wagen": ["DESKTOP_APP_WAGEN", "fahne", Vector2(900, 700), "intern"],
	"ausbau": ["DESKTOP_APP_AUSBAU", "fahne", Vector2(960, 800), "intern"],
}
## Banner der Büro-Apps: [Farbe oben, Farbe unten, Untertitel-Farbe, Untertitel-Schlüssel]
const BANNER := {
	"shop": [Color(0.86, 0.42, 0.1), Color(0.3, 0.13, 0.08), Color(1, 0.88, 0.7), "SHOP_SUB"],
	"personal": [Color(0.1, 0.55, 0.52), Color(0.04, 0.17, 0.2), Color(0.75, 0.97, 0.94), "PERSONAL_SUB"],
	"bilanz": [Color(0.78, 0.2, 0.36), Color(0.22, 0.07, 0.15), Color(1, 0.82, 0.88), "BILANZ_SUB"],
	"bierpreis": [Color(0.78, 0.5, 0.08), Color(0.24, 0.14, 0.05), Color(1, 0.92, 0.7), "BIERPREIS_SUB"],
}
## Freigeschaltete Apps je Kapitel (Plan: docs/PLAN_STORY.md): Kapitel 1 nur E-Mail und Shop, Kapitel 2 der Rest, Kapitel 3 Social Media
const FREI := {
	1: ["mail", "shop"],
	2: ["mail", "shop", "quests", "kalender", "bank", "personal", "bilanz", "bierpreis", "wetter"],
	3: ["mail", "shop", "quests", "kalender", "bank", "personal", "bilanz", "bierpreis", "wetter", "social"],
}
## Reiter im Festbüro-Fenster (scenes/ui/festbuero.tscn)
## Reiter im Festbüro-Fenster je App: Shop = Zelt, Lizenzen, Künstler, Ware (Bier!), Deko; Personal; Bilanz + Ziele
const REITER := {"shop": [0, 1, 3, 4, 7], "personal": [2], "bilanz": [5, 6]}
## Diese Apps teilen sich das Festbüro-Fenster
const BUERO_APPS := ["shop", "personal", "bilanz"]

## Kamera: so weit zoomt der Blick auf den Bildschirm, in Sekunden
const ZOOM_FAKTOR := 0.62
const ZOOM_DAUER := 0.42

var _gm: Node
var _hud: Node
var _story: Node
var _kamera: Camera3D
var _fov_vorher := 0.0
var _tween: Tween
## app → Fenster (nur offene)
var _offen := {}
## app → Taskleistenknopf
var _tasks := {}
var _aktiv := ""
var _takt := 0.0

func _ready() -> void:
	visible = false
	for name: String in ["Mail", "Quests", "Shop", "Personal", "Bilanz", "Bierpreis", "Bank", "Wetter", "Social", "Kalender", "Fest", "Wagen", "Ausbau"]:
		var icon := get_node("%Icon" + name) as Button
		icon.pressed.connect(_symbol_geklickt.bind(name.to_lower()))
		var start := get_node("%Start" + name) as Button
		start.pressed.connect(_start_geklickt.bind(name.to_lower()))
	%TrayMail.pressed.connect(app_oeffnen.bind("mail"))
	%StartKnopf.toggled.connect(_start_umschalten)
	%StartAus.pressed.connect(schliessen)
	%Hintergrund.gui_input.connect(_hintergrund_eingabe)
	%Hintergrund.mouse_filter = Control.MOUSE_FILTER_STOP

func einrichten(gm: Node, hud: Node) -> void:
	_gm = gm
	_hud = hud
	_story = gm.get_node_or_null("Story")
	if _story:
		_story.geaendert.connect(_aktualisieren)

# ------------------------------------------------------------------ Öffnen und Schließen
func oeffnen() -> void:
	if visible:
		return
	visible = true
	%Startmenue.visible = false
	%StartKnopf.set_pressed_no_signal(false)
	_aktualisieren()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_zoom(true)
	# Einmaliger Hinweis beim ersten Mal (daten/hinweise.json)
	if _story and _hud and _hud.has_method("melde_text"):
		var h: String = _story.hinweis_zeigen("desktop_erstmals")
		if h != "":
			_hud.melde_text(tr(h), 0)

func schliessen() -> void:
	if not visible:
		return
	for app: String in _offen.keys():
		_fenster_schliessen(_offen[app])
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_zoom(false)

func ist_offen() -> bool:
	return visible

## Escape: erst Startmenü, dann das oberste Fenster, zuletzt der Desktop
func escape() -> void:
	if %Startmenue.visible:
		%Startmenue.visible = false
		%StartKnopf.set_pressed_no_signal(false)
		return
	var oben := _oberstes_fenster()
	if oben != null:
		_fenster_schliessen(oben)
		return
	schliessen()

func _oberstes_fenster() -> Control:
	var kinder := %Fenster.get_children()
	for i in range(kinder.size() - 1, -1, -1):
		if (kinder[i] as Control).visible:
			return kinder[i] as Control
	return null

## Übergangs-Animation: Desktop blendet ein, die Kamera fährt auf den Bildschirm zu (und zurück)
func _zoom(hinein: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if hinein:
		modulate.a = 0.0
		_tween.tween_property(self, "modulate:a", 1.0, ZOOM_DAUER)
	_kamera = get_viewport().get_camera_3d()
	if _kamera == null:
		return
	if hinein:
		_fov_vorher = _kamera.fov
		_tween.tween_property(_kamera, "fov", _fov_vorher * ZOOM_FAKTOR, ZOOM_DAUER)
	elif _fov_vorher > 0.0:
		_tween.tween_property(_kamera, "fov", _fov_vorher, ZOOM_DAUER * 0.7)

# ------------------------------------------------------------------ Symbole und Startmenü
func _start_umschalten(an: bool) -> void:
	%Startmenue.visible = an
	if an:
		_menue_platzieren.call_deferred()

## Das Menü klappt über dem Startknopf auf
func _menue_platzieren() -> void:
	var menue: Control = %Startmenue
	menue.size = menue.get_combined_minimum_size()
	var knopf: Control = %StartKnopf
	var ziel := Vector2(knopf.global_position.x - 6.0, %Taskleiste.global_position.y - menue.size.y - 10.0)
	ziel.x = clampf(ziel.x, 8.0, size.x - menue.size.x - 8.0)
	menue.position = ziel

func _symbol_geklickt(name: String) -> void:
	app_oeffnen(name)

func _start_geklickt(name: String) -> void:
	%Startmenue.visible = false
	%StartKnopf.set_pressed_no_signal(false)
	app_oeffnen(name)

func _hintergrund_eingabe(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		%Startmenue.visible = false
		%StartKnopf.set_pressed_no_signal(false)

func _input(event: InputEvent) -> void:
	# Klick in ein Fenster holt es nach vorn
	if not visible or not (event is InputEventMouseButton) or not event.pressed:
		return
	var kinder := %Fenster.get_children()
	for i in range(kinder.size() - 1, -1, -1):
		var f := kinder[i] as Control
		if f.visible and Rect2(f.global_position, f.size * f.scale).has_point(event.position):
			_vorn(f)
			return

# ------------------------------------------------------------------ Apps und Fenster
func app_frei(app: String) -> bool:
	var kapitel := int(_story.kapitel) if _story else 3
	if app == "fest":
		return kapitel >= 6   # das Fest gibt es erst nach der Geschichte
	if app == "wagen":
		return kapitel >= 3
	if app == "ausbau":
		return kapitel >= 5
	return app in FREI[clampi(kapitel, 1, 3)]

func app_oeffnen(name: String) -> void:
	if not app_frei(name):
		return
	if not APPS.has(name):
		return
	if name in BUERO_APPS and not _buero_offen():
		return
	var gemeinsam := name in BUERO_APPS
	# Festbüro-Apps teilen ein Fenster: ist es schon offen, nur auf den Reiter wechseln
	if gemeinsam:
		for a: String in BUERO_APPS:
			if _offen.has(a):
				_offen[a].app = name
				_offen[name] = _offen[a]
				if a != name:
					_offen.erase(a)
					_tasks[name] = _tasks[a]
					_tasks.erase(a)
				_buero_reiter(name)
				_titel_und_task(name)
				_vorn(_offen[name])
				return
	if _offen.has(name):
		var f: Control = _offen[name]
		f.visible = true
		_vorn(f)
		return
	var def: Array = APPS[name]
	var fenster := FENSTER.instantiate()
	%Fenster.add_child(fenster)
	fenster.app = name
	fenster.einrichten(str(def[0]), _icon(name), def[2])
	fenster.fokussiert.connect(_vorn)
	fenster.schliessen_angefordert.connect(_fenster_schliessen)
	fenster.minimiert.connect(_fenster_minimieren)
	match str(def[3]):
		"intern":
			var szene: PackedScene = {"mail": MAIL, "quests": QUESTS, "bank": BANK, "wetter": WETTER, "social": SOCIAL, "kalender": KALENDER, "fest": FEST, "wagen": WAGEN, "ausbau": AUSBAU}[name]
			var app: Control = szene.instantiate()
			fenster.inhalt().add_child(app)
			app.set_anchors_preset(Control.PRESET_FULL_RECT)
			app.einrichten(_gm, _hud if name in ["bank", "wetter", "social", "kalender", "fest", "wagen", "ausbau"] else _story)
			app.zeigen()
		"bald":
			var platzhalter: Control = BALD.instantiate()
			fenster.inhalt().add_child(platzhalter)
			platzhalter.set_anchors_preset(Control.PRESET_FULL_RECT)
		"legacy":
			_banner(name, fenster)
			_legacy_einbetten(name, fenster)
	_offen[name] = fenster
	var knopf := TASK.instantiate() as Button
	%Laufende.add_child(knopf)
	knopf.icon = _icon(name)
	knopf.tooltip_text = tr(str(def[0]))
	knopf.pressed.connect(_task_geklickt.bind(name))
	_tasks[name] = knopf
	var frei := _freier_platz()
	fenster.anpassen(frei)
	fenster.mittig(Vector2(26, 22) * float(_offen.size() - 1))
	_vorn(fenster)

## Buntes App-Icon (assets/ui/desktop/icon_<app>.png, gezeichnet mit tools/bake_desktop_icons.py)
func _icon(app: String) -> Texture2D:
	var pfad := ICON_PFAD % app
	return load(pfad) as Texture2D if ResourceLoader.exists(pfad) else null

func _freier_platz() -> Vector2:
	return %Fenster.size

func _titel_und_task(name: String) -> void:
	var def: Array = APPS[name]
	var f: Control = _offen[name]
	f.titel_setzen(str(def[0]))
	_banner(name, f)
	(_tasks[name] as Button).tooltip_text = tr(str(def[0]))
	(_tasks[name] as Button).icon = _icon(name)
	f.get_node("%Symbol").texture = _icon(name)

func _vorn(f: Control) -> void:
	%Fenster.move_child(f, %Fenster.get_child_count() - 1)
	_aktiv = str(f.get("app"))
	f.visible = true
	_tasks_markieren()

func _tasks_markieren() -> void:
	for a: String in _tasks:
		(_tasks[a] as Button).set_pressed_no_signal(a == _aktiv and (_offen[a] as Control).visible)

func _task_geklickt(name: String) -> void:
	var f: Control = _offen.get(name)
	if f == null:
		return
	if f.visible and _aktiv == name:
		f.visible = false
		_aktiv = ""
		_tasks_markieren()
	else:
		_vorn(f)

func _fenster_minimieren(f: Control) -> void:
	f.visible = false
	_aktiv = ""
	_tasks_markieren()

func _fenster_schliessen(f: Control) -> void:
	if f == null or not is_instance_valid(f):
		return
	var name := str(f.get("app"))
	if str(APPS.get(name, ["", "", Vector2.ZERO, ""])[3]) == "legacy":
		_legacy_ausbetten(name, f)
	_offen.erase(name)
	var knopf: Button = _tasks.get(name)
	_tasks.erase(name)
	if knopf:
		knopf.queue_free()
	f.queue_free()
	if _aktiv == name:
		_aktiv = ""
	_tasks_markieren()
	# nach dem Schließen muss die Maus sichtbar bleiben (das alte Fenster fängt sie sonst ein)
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# ------------------------------------------------------------------ Bestehende Fenster einbetten
func _legacy_knoten(name: String) -> Control:
	if name in BUERO_APPS:
		return _hud.get("_buero") as Control
	return _hud.get("_computer") as Control

func _legacy_einbetten(name: String, fenster: Control) -> void:
	var alt := _legacy_knoten(name)
	if alt == null:
		return
	alt.reparent(fenster.inhalt(), false)
	alt.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dunkel := alt.get_node_or_null("Abdunkeln") as CanvasItem
	if dunkel:
		dunkel.visible = false
	alt.oeffnen()
	if name in BUERO_APPS:
		_buero_reiter(name)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Schließt sich das alte Fenster selbst (sein eigener Knopf), schließt auch das Desktop-Fenster
	if not alt.visibility_changed.is_connected(_legacy_zu):
		alt.visibility_changed.connect(_legacy_zu.bind(name))

func _banner(name: String, fenster: Control) -> void:
	var b: Array = BANNER.get(name, [])
	if not b.is_empty():
		fenster.banner_setzen(_icon(name), tr(str(APPS[name][0])), tr(str(b[3])), b[0], b[1], b[2])

func _buero_reiter(name: String) -> void:
	var buero := _hud.get("_buero") as Control
	if buero and buero.has_method("reiter_gruppe"):
		buero.reiter_gruppe(REITER.get(name, [0]))

func _legacy_zu(name: String) -> void:
	var alt := _legacy_knoten(name)
	if alt == null or alt.visible:
		return
	var f: Control = _offen.get(name)
	if f != null:
		_fenster_schliessen(f)

func _legacy_ausbetten(name: String, f: Control) -> void:
	var alt := _legacy_knoten(name)
	if alt == null:
		return
	if alt.visibility_changed.is_connected(_legacy_zu):
		alt.visibility_changed.disconnect(_legacy_zu)
	alt.visible = false
	var dunkel := alt.get_node_or_null("Abdunkeln") as CanvasItem
	if dunkel:
		dunkel.visible = true
	alt.reparent(_hud, false)
	alt.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Zwei Apps teilen das Festbüro: beim Ausbetten darf die andere nicht mehr als offen gelten
	if name in BUERO_APPS:
		for a: String in BUERO_APPS:
			_offen.erase(a)
			if _tasks.has(a):
				(_tasks[a] as Button).queue_free()
				_tasks.erase(a)

## Der Kalender ist ein eigenes Fenster (Taste K) und öffnet darüber
func _kalender() -> void:
	var kal := _gm.get_node_or_null("Kalender")
	if kal != null and kal.has_method("zeigen"):
		kal.zeigen()

func _buero_offen() -> bool:
	return _gm != null and _gm.has_method("buero_offen") and _gm.buero_offen()

# ------------------------------------------------------------------ Anzeige
func _process(delta: float) -> void:
	if not visible:
		return
	# Der Zeiger bleibt am Desktop immer sichtbar — andere Fenster und Klicks ins Leere dürfen die Maus nicht einfangen
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_takt -= delta
	if _takt <= 0.0:
		_takt = 0.5
		_uhr()

func _uhr() -> void:
	if _gm == null:
		return
	var tag := int(_gm.get("_day")) if _gm.get("_day") != null else 1
	var stunde := float(_gm.call("_clock_hour")) if _gm.has_method("_clock_hour") else 8.0
	if stunde < 0.0:
		stunde = 8.0   # vor Schichtbeginn zeigt die Uhr die Öffnungszeit
	%Uhr.text = "%s %d · %02d:%02d" % [tr("DESKTOP_TAG"), tag, int(stunde), int((stunde - floor(stunde)) * 60.0)]

func _aktualisieren() -> void:
	if _gm == null:
		return
	_uhr()
	var offen := _buero_offen()
	for app: String in ["Mail", "Quests", "Shop", "Personal", "Bilanz", "Bierpreis", "Bank", "Wetter", "Social", "Kalender", "Fest", "Wagen", "Ausbau"]:
		var frei := app_frei(app.to_lower())
		(get_node("%Icon" + app) as Button).visible = frei
		(get_node("%Start" + app) as Button).visible = frei
	for n: String in ["Shop", "Personal"]:
		(get_node("%Icon" + n) as Button).disabled = not offen
		(get_node("%Start" + n) as Button).disabled = not offen
	var n: int = int(_story.ungelesen()) if _story else 0
	%Badge.visible = n > 0
	%Badge.text = str(n)
	var mail: Control = _offen.get("mail")
	if mail != null:
		var app: Node = mail.inhalt().get_child(0)
		if app.has_method("zeigen"):
			app.zeigen()
	var quests: Control = _offen.get("quests")
	if quests != null:
		var app2: Node = quests.inhalt().get_child(0)
		if app2.has_method("zeigen"):
			app2.zeigen()
