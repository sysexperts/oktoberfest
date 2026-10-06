extends CanvasLayer
## Einleitung: Brief von Onkel Sepp („Ich vermache dir mein Festzelt …") auf
## schwarzem Grund, danach Überblende auf die Kirmes. Der Brief schickt die
## Spieler zum Festleiter in sein Festbüro (scripts/npc_festleiter.gd), dort
## beginnt die erste Mission. Aufbau: scenes/ui/kino.tscn.
##
## Läuft einmal beim ersten Start eines neuen Spielstands. Der Server startet sie
## (game_manager.net_kino_start), danach blättert jeder Spieler selbst — Esc
## schließt den Brief nur bei sich.
##
## Texte in locale/texte.csv: BRIEF_<n>_DU für Solo, BRIEF_<n>_IHR für Koop.

## Wird gesendet, wenn ein Brief oder die Eröffnung zu Ende ist (Horst fragt danach weiter)
signal beendet

const SEITEN := 3
## Eröffnung am Kirmestor: Kamerafahrt über die Kirmes mit Titel, so lange in Sekunden
const TITEL_DAUER := 12.0
## Ab hier steht das Schlussbild (Spieler von hinten), ab T_HALTEN fährt die Kamera in die Spielansicht
const T_FAHRT := 7.0
const T_HALTEN := 9.4
var _seiten := SEITEN
var _praefix := "BRIEF"

## Wo die Spieler am Tor stehen (Reihenfolge = Spielerliste)
const PLAETZE := [Vector3(-1.8, 0.1, 84.0), Vector3(1.8, 0.1, 84.0), Vector3(-4.0, 0.1, 85.0), Vector3(4.0, 0.1, 85.0)]

@onready var _brief: Control = %Brief
@onready var _schwarz: ColorRect = %Abdunkeln
@onready var _titel: Label = %Titel
@onready var _text: Label = %Text
@onready var _hinweis: Label = %Hinweis
@onready var _titel_bild: Control = %TitelBild
@onready var _kinokamera: Camera3D = %Kinokamera

var aktiv := false
var _seite := -1
var _t := 0.0
var _spieler: Node = null
var _mehrere := false
## Eröffnung (Titel und Kamerafahrt) läuft oder ist schon gelaufen
var _modus := ""
var _gezeigt := false
var _titel_t := 0.0
var _spieler_kamera: Camera3D

func _ready() -> void:
	visible = false

## Läuft gerade ein Werkzeug aus tools/ (Test, Bilder)? Dann keine Einleitung —
## sie würde Eingaben blockieren. Das Kino-Werkzeug selbst will sie sehen.
static func werkzeuglauf() -> bool:
	for a in OS.get_cmdline_args():
		if a.begins_with("res://tools/") and not a.contains("kino"):
			return true
	return false

## Neues Spiel: sobald die eigene Figur da ist und das Tutorial bei Schritt 0 steht, läuft die Eröffnung einmal
## (Kamera fährt über die Kirmes, Titel). Jeder Spieler startet sie bei sich, das geht auch bei Koop und Beitritt.
func _eroeffnung_pruefen() -> void:
	if _gezeigt or werkzeuglauf():
		return
	var welt := get_parent()
	if welt == null or not ("_players_nodes" in welt) or not ("_quest_step" in welt):
		return
	var sp: Node = welt._players_nodes.get(multiplayer.get_unique_id())
	if sp == null or not is_instance_valid(sp):
		return
	_gezeigt = true
	if int(welt._quest_step) != 0 or int(welt._tent_stage) > 0 or int(welt._day) > 1:
		return
	_eroeffnung_starten(welt, sp)

func _eroeffnung_starten(welt: Node, sp: Node) -> void:
	_spieler = sp
	_mehrere = multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0
	aktiv = true
	visible = true
	_modus = "titel"
	_titel_t = 0.0
	_brief.visible = false
	_schwarz.color.a = 1.0
	_titel_bild.visible = true
	_titel_bild.modulate.a = 0.0
	%TitelUnter.text = String(TranslationServer.translate("INTRO_UNTER" + ("_IHR" if _mehrere else "")))
	%TitelSkip.text = String(TranslationServer.translate("INTRO_SKIP"))
	# Alle ans Kirmestor stellen, Blick in die Kirmes
	var ids: Array = (welt._players_nodes as Dictionary).keys()
	ids.sort()
	var platz: int = maxi(0, ids.find(multiplayer.get_unique_id()))
	_spieler.global_position = PLAETZE[platz % PLAETZE.size()]
	(_spieler as Node3D).rotation.y = 0.0
	_spieler.minispiel = self
	_spieler.kino_zeigen(true)
	_spieler_kamera = get_viewport().get_camera_3d()
	_hud_zeigen(welt, false)
	_kinokamera.make_current()
	_kamera_setzen(0.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## Kamerafahrt: von hoch über dem Fest herab hinter die Spieler (Schlussbild, von hinten), kurz halten,
## dann in die Spielkamera hineinfahren. Danach geht das Spiel los.
## Die Anzeige (Geld, Aufgabe) stört in der Kamerafahrt
func _hud_zeigen(welt: Node, an: bool) -> void:
	var hud: Variant = welt.get("_hud") if welt != null else null
	if hud != null and "visible" in hud:
		hud.visible = an

func _schlussbild() -> Transform3D:
	var anzahl := 1
	var welt := get_parent()
	if welt != null and "_players_nodes" in welt:
		anzahl = maxi(1, (welt._players_nodes as Dictionary).size())
	var mitte := Vector3.ZERO
	var breit := 0.0
	for i in anzahl:
		mitte += PLAETZE[i % PLAETZE.size()]
	mitte /= float(anzahl)
	for i in anzahl:
		breit = maxf(breit, PLAETZE[i % PLAETZE.size()].distance_to(mitte))
	var pos := mitte + Vector3(0.0, 2.5, 4.6 + breit * 1.2)
	return Transform3D(Basis(), pos).looking_at(mitte + Vector3(0.0, 1.1, 0.0), Vector3.UP)

func _kamera_setzen(t: float) -> void:
	var schluss := _schlussbild()
	var start := Transform3D(Basis(), Vector3(34.0, 24.0, 30.0)).looking_at(Vector3(0.0, 4.0, 0.0), Vector3.UP)
	var pose: Transform3D
	if t < T_FAHRT:
		pose = start.interpolate_with(schluss, ease(smoothstep(0.0, T_FAHRT, t), -2.0))
	elif t < T_HALTEN:
		# kaum merklich weiter heranrücken, solange das Schlussbild steht
		pose = schluss
		pose.origin += schluss.basis.z * -0.5 * (t - T_FAHRT) / (T_HALTEN - T_FAHRT)
	else:
		var ziel: Transform3D = _spieler_kamera.global_transform if _spieler_kamera != null else schluss
		var q := smoothstep(T_HALTEN, TITEL_DAUER, t)
		pose = schluss.interpolate_with(ziel, q)
		# am Ende der Fahrt sieht man sich nicht mehr von außen
		if q > 0.9 and _spieler and is_instance_valid(_spieler):
			_spieler.kino_zeigen(false)
	_kinokamera.global_transform = pose

func _eroeffnung_lauf(delta: float) -> void:
	_titel_t += delta
	var t := _titel_t
	_schwarz.color.a = 1.0 - smoothstep(0.4, 2.4, t)
	_titel_bild.modulate.a = smoothstep(1.4, 2.6, t) * (1.0 - smoothstep(5.2, 6.6, t))
	_kamera_setzen(t)
	if t >= TITEL_DAUER:
		_eroeffnung_ende()

func _eroeffnung_ende() -> void:
	if _modus != "titel":
		return
	_modus = ""
	aktiv = false
	_hud_zeigen(get_parent(), true)
	_titel_bild.visible = false
	_brief.visible = true
	_schwarz.color.a = 0.0
	visible = false
	if _spieler_kamera != null and is_instance_valid(_spieler_kamera):
		_spieler_kamera.make_current()
	if _spieler and is_instance_valid(_spieler):
		_spieler.kino_zeigen(false)
		_spieler.minispiel_beendet()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	beendet.emit()

## player.gd hält den Brief wie ein Minispiel (blockiert Bewegung)
func laeuft() -> bool:
	return aktiv

func starten(mehrere: bool) -> void:
	if aktiv:
		return
	var welt := get_parent()
	_mehrere = mehrere
	_praefix = "BRIEF"
	_seiten = SEITEN
	_spieler = welt._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in welt else null
	if _spieler == null:
		return
	aktiv = true
	visible = true
	_schwarz.color.a = 1.0
	_brief.modulate.a = 1.0
	# Alle ans Kirmestor stellen (Ankunft), Blick nach Süden in die Kirmes
	var ids: Array = (welt._players_nodes as Dictionary).keys()
	ids.sort()
	var platz: int = maxi(0, ids.find(multiplayer.get_unique_id()))
	_spieler.global_position = PLAETZE[platz % PLAETZE.size()]
	(_spieler as Node3D).rotation.y = 0.0
	_spieler.minispiel = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_titel.text = String(TranslationServer.translate("BRIEF_TITEL"))
	_seite = -1
	_weiter()

func eingabe(event: InputEvent) -> void:
	if _modus == "titel":
		var klick := event as InputEventMouseButton
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept") or (klick and klick.pressed):
			_eroeffnung_ende()
		return
	if event.is_action_pressed("ui_cancel"):
		beenden()
		return
	var mb := event as InputEventMouseButton
	# Am Controller wird A zusätzlich zum Linksklick (Einstellungen._pad_klick) —
	# ohne diese Ausnahme blätterte ein Druck zwei Seiten weiter.
	if (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT) 			or (event.is_action_pressed("ui_accept") and not event is InputEventJoypadButton):
		_weiter()

func _weiter() -> void:
	_seite += 1
	if _seite >= _seiten:
		beenden()
		return
	_t = 0.0
	_text.text = _wort(_praefix + "_%d" % (_seite + 1))
	_hinweis.text = String(TranslationServer.translate("BRIEF_WEITER" if _seite < _seiten - 1 else ("BRIEF_SCHLIESSEN")))

## Text in der passenden Anrede (Solo „du", Koop „ihr")
func _wort(key: String) -> String:
	return String(TranslationServer.translate(key + ("_IHR" if _mehrere else "_DU")))

func _process(delta: float) -> void:
	if not aktiv:
		_eroeffnung_pruefen()
		return
	if _modus == "titel":
		_eroeffnung_lauf(delta)
		return
	# jede Seite sanft einblenden
	_t += delta
	_text.modulate.a = minf(1.0, _t * 2.5)
	_brief.scale = Vector2.ONE * lerpf(0.96, 1.0, minf(1.0, _t * 4.0))
	_brief.pivot_offset = _brief.size * 0.5

func beenden() -> void:
	if not aktiv:
		return
	aktiv = false
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Übergang: Brief ausblenden, kurz schwarz, dann wird es auf der Kirmes hell
	var tw := create_tween()
	tw.tween_property(_brief, "modulate:a", 0.0, 0.6)
	tw.tween_interval(0.7)
	tw.tween_property(_schwarz, "color:a", 0.0, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		visible = false
		beendet.emit())

## Weiterer Brief mitten im Spiel (z. B. Sepps letzter Brief nach dem Sieg
## über Huber): ohne ans Tor zu stellen, Seiten <praefix>_<n>_DU/_IHR.
func brief_zeigen(mehrere: bool, praefix: String, seiten: int, titel: String) -> void:
	var welt := get_parent()
	_spieler = welt._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in welt else null
	if aktiv or _spieler == null:
		return
	_mehrere = mehrere
	_praefix = praefix
	_seiten = seiten
	aktiv = true
	visible = true
	_schwarz.color.a = 0.75
	_brief.modulate.a = 1.0
	_spieler.minispiel = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_titel.text = String(TranslationServer.translate(titel))
	_seite = -1
	_weiter()
