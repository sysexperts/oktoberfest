extends CanvasLayer
## Baumodus (F8): Buden, Fahrgeschäfte, Bäume und Deko frei auf die Kirmes stellen.
## Freie Kamera von oben, links der Katalog. Alles geht über Kirmes/Karte an den
## Server und wird dort gespeichert — so bauen alle Mitspieler an derselben Karte.
##   Katalog anklicken → Vorschau hängt an der Maus, Linksklick setzt (mehrfach)
##   Linksklick auf ein Teil → auswählen, gedrückt halten → verschieben
##   R / Q-E oder Umschalt+Mausrad: drehen · G: Raster · Entf: löschen
##   Pfeiltasten: Auswahl fein verschieben · Strg+Z: rückgängig
##   Umschalt+Klick: mehrere gleiche Teile hintereinander setzen
##   Strg+D: kopieren · Esc: abwählen / Baumodus verlassen
##   WASD: Kamera · Mausrad: Höhe · rechte Maustaste: umsehen

const Katalog := preload("res://scripts/karten_katalog.gd")
const Karte := preload("res://scripts/karte.gd")
const DREH_SCHRITT := PI / 12.0

@export var karte_pfad: NodePath = ^"../Kirmes/Karte"

@onready var _kamera: Camera3D = $Kamera
@onready var _gruppe: OptionButton = %Gruppe
@onready var _suche: LineEdit = %Suche
@onready var _liste: ItemList = %Liste
@onready var _info: Label = %Info
@onready var _markierung: MeshInstance3D = $Markierung

var aktiv := false
var _karte: Karte
var _katalog: Array = []
var _spieler: Node = null
var _geist: Node3D = null
var _geist_pfad := ""
var _drehung := 0.0
var _raster := true
var _auswahl := -1
var _zieht := false
var _zieh_versatz := Vector3.ZERO
var _zieh_start := {}
## Rückgängig-Verlauf (nur eigene Schritte): {art, n, …}
var _verlauf: Array = []
## Vom Server erwartete neue Teile: "neu" (Klick) oder "wieder" (Rückgängig)
var _erwartet: Array = []
const VERLAUF_MAX := 100
var _yaw := 0.0
var _pitch := -0.9
var _hoehe := 30.0

func _ready() -> void:
	visible = false
	_markierung.visible = false
	_karte = get_node_or_null(karte_pfad) as Karte
	_katalog = Katalog.alle()
	for g: Array in _katalog:
		_gruppe.add_item("%s (%d)" % [g[0], (g[1] as Array).size()])
	_gruppe.item_selected.connect(func(_i: int) -> void: _liste_fuellen())
	_suche.text_changed.connect(func(_t: String) -> void: _liste_fuellen())
	_liste.item_selected.connect(_katalog_gewaehlt)
	if _karte:
		_karte.gesetzt.connect(_neu_gesetzt)
	%Vorlage.pressed.connect(func() -> void: _alles_ersetzen(Karte.vorlage()))
	%Leeren.pressed.connect(_leeren)
	%Kopieren.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(_karte.als_text())
		_melden("Karte in die Zwischenablage kopiert"))
	%Einfuegen.pressed.connect(func() -> void:
		var text := DisplayServer.clipboard_get()
		if JSON.parse_string(text) is Dictionary:
			_alles_ersetzen(text)
		else:
			_melden("Zwischenablage enthält keine Karte"))
	%Schliessen.pressed.connect(beenden)
	_liste_fuellen()

func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.physical_keycode == KEY_F8:
		get_viewport().set_input_as_handled()
		if aktiv:
			beenden()
		else:
			starten()

func starten() -> void:
	var welt := get_parent()
	if _karte == null or not "_players_nodes" in welt:
		return
	_spieler = welt._players_nodes.get(multiplayer.get_unique_id())
	if _spieler == null or _spieler.minispiel != null:
		return
	aktiv = true
	visible = true
	_spieler.minispiel = self
	var start: Vector3 = (_spieler as Node3D).global_position
	_kamera.global_position = start + Vector3(0, _hoehe, 18.0)
	_yaw = 0.0
	_kamera_setzen()
	_kamera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_melden("")

func beenden() -> void:
	if not aktiv:
		return
	aktiv = false
	visible = false
	_geist_weg()
	_waehlen(-1)
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## player.gd hält den Baumodus wie ein Minispiel
func laeuft() -> bool:
	return aktiv

# ------------------------------------------------------------------ Katalog
func _liste_fuellen() -> void:
	_liste.clear()
	if _katalog.is_empty():
		return
	var filter := _suche.text.strip_edges().to_lower()
	var quellen: Array = _katalog[_gruppe.selected][1] if filter == "" else []
	if filter != "":
		for g: Array in _katalog:
			quellen.append_array(g[1])
	for p: String in quellen:
		var anzeige := Katalog.name_von(p)
		if filter == "" or anzeige.to_lower().contains(filter):
			var i := _liste.add_item(anzeige)
			_liste.set_item_metadata(i, p)
			_liste.set_item_tooltip(i, p)

func _katalog_gewaehlt(i: int) -> void:
	_waehlen(-1)
	_geist_setzen(str(_liste.get_item_metadata(i)))
	_liste.release_focus()

func _geist_setzen(pfad: String) -> void:
	_geist_weg()
	var szene := load(pfad) as PackedScene
	if szene == null:
		return
	_geist = szene.instantiate() as Node3D
	_geist_pfad = pfad
	# Nur Optik: keine Skripte (keine Spiele, keine Gruppen), keine Kollision
	for n in _geist.find_children("*", "", true, false) + [_geist]:
		if n != _geist and n.get_script() != null:
			n.set_script(null)
		if n is CollisionObject3D:
			(n as CollisionObject3D).collision_layer = 0
			(n as CollisionObject3D).collision_mask = 0
	if _geist.get_script() != null:
		var t := _geist.transform
		_geist.set_script(null)
		_geist.transform = t
	_geist.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_geist)
	_melden(Katalog.name_von(pfad) + " — Linksklick setzt (Umschalt: mehrere), R dreht, Esc bricht ab")

func _geist_weg() -> void:
	if _geist:
		_geist.queue_free()
	_geist = null
	_geist_pfad = ""

# ------------------------------------------------------------------ Eingabe
func eingabe(event: InputEvent) -> void:
	if not aktiv:
		return
	var tippt := get_viewport().gui_get_focus_owner() is LineEdit
	if event is InputEventKey and event.pressed and not tippt:
		var k := event as InputEventKey
		match k.physical_keycode:
			KEY_ESCAPE:
				if _geist:
					_geist_weg()
					_melden("")
				elif _auswahl >= 0:
					_waehlen(-1)
				else:
					beenden()
			KEY_R, KEY_E:
				_drehen(DREH_SCHRITT)
			KEY_Q:
				_drehen(-DREH_SCHRITT)
			KEY_G:
				_raster = not _raster
				_melden("Raster " + ("an (0,5 m)" if _raster else "aus"))
			KEY_DELETE, KEY_BACKSPACE:
				if _auswahl >= 0:
					_merke({"art": "loeschen", "e": (_karte.eintraege[_auswahl] as Dictionary).duplicate(true)})
					_karte.net_loeschen.rpc_id(1, _auswahl)
					_waehlen(-1)
			KEY_Z:
				if k.ctrl_pressed:
					_rueckgaengig()
			KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT:
				if _auswahl >= 0:
					var schritt := 0.5 if _raster else 0.1
					var d := {KEY_UP: Vector3(0, 0, -1), KEY_DOWN: Vector3(0, 0, 1), KEY_LEFT: Vector3(-1, 0, 0), KEY_RIGHT: Vector3(1, 0, 0)}[k.physical_keycode] as Vector3
					_verschieben(_auswahl, _karte.knoten(_auswahl).position + Basis(Vector3.UP, _yaw) * d * schritt)
			KEY_D:
				if k.ctrl_pressed and _auswahl >= 0:
					var e: Dictionary = _karte.eintraege.get(_auswahl, {})
					var r := float(e.get("r", 0.0))
					_waehlen(-1)
					_geist_setzen(str(e.p))
					_drehung = r
	elif event is InputEventKey and event.pressed and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		get_viewport().gui_release_focus()
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if not mb.pressed:
				return
			var richtung := 1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
			if mb.shift_pressed:
				_drehen(DREH_SCHRITT * richtung)
			else:
				_hoehe = clampf(_hoehe - richtung * 2.5, 3.0, 120.0)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_klick(mb.position)
			elif _zieht:
				_zieht = false
				var k := _karte.knoten(_auswahl)
				if k and not k.position.is_equal_approx(Vector3(_zieh_start.x, _zieh_start.y, _zieh_start.z)):
					_merke(_zieh_start)
					_karte.net_bewegen.rpc_id(1, _auswahl, k.position, float(_karte.eintraege[_auswahl].get("r", 0.0)))
	var mm := event as InputEventMouseMotion
	if mm and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_yaw -= mm.relative.x * 0.005
		_pitch = clampf(_pitch - mm.relative.y * 0.005, -1.5, -0.15)

func _klick(bildschirm: Vector2) -> void:
	var p = _boden(bildschirm)
	if p == null:
		return
	if _geist:
		var pfad := _geist_pfad
		var pos := _geist.position
		# Ohne Umschalt: Vorschau weg, das neue Teil wird ausgewählt (gleich nachjustieren)
		if not Input.is_physical_key_pressed(KEY_SHIFT):
			_geist_weg()
		_erwartet.append("neu")
		_karte.net_setzen.rpc_id(1, pfad, pos, _drehung)
		return
	var n := _karte.naechster(p, 4.0)
	_waehlen(n)
	if n >= 0:
		_zieht = true
		_zieh_start = _bewegung_merken(n)
		_zieh_versatz = _karte.knoten(n).position - (p as Vector3)

func _drehen(schritt: float) -> void:
	if _geist:
		_drehung = wrapf(_drehung + schritt, -PI, PI)
	elif _auswahl >= 0:
		var e: Dictionary = _karte.eintraege.get(_auswahl, {})
		var k := _karte.knoten(_auswahl)
		if k:
			_merke(_bewegung_merken(_auswahl))
			_karte.net_bewegen.rpc_id(1, _auswahl, k.position, wrapf(float(e.get("r", 0.0)) + schritt, -PI, PI))

func _waehlen(n: int) -> void:
	_auswahl = n
	_zieht = false
	_markierung.visible = n >= 0
	if n >= 0:
		_melden(Katalog.name_von(str(_karte.eintraege[n].p)) + " — ziehen oder Pfeiltasten verschieben, R dreht, Entf löscht, Strg+D kopiert, Strg+Z rückgängig")

## Mausstrahl auf den Boden (Höhe 0)
func _boden(bildschirm: Vector2) -> Variant:
	var von := _kamera.project_ray_origin(bildschirm)
	var dir := _kamera.project_ray_normal(bildschirm)
	if dir.y > -0.01:
		return null
	var p := von + dir * (-von.y / dir.y)
	if _raster:
		p = Vector3(snappedf(p.x, 0.5), 0.0, snappedf(p.z, 0.5))
	return p

func _process(delta: float) -> void:
	if not aktiv:
		return
	# Kamera
	var tippt := get_viewport().gui_get_focus_owner() is LineEdit
	var v := Vector2.ZERO
	if not tippt:
		if Input.is_physical_key_pressed(KEY_W) or (_auswahl < 0 and Input.is_physical_key_pressed(KEY_UP)): v.y -= 1
		if Input.is_physical_key_pressed(KEY_S) or (_auswahl < 0 and Input.is_physical_key_pressed(KEY_DOWN)): v.y += 1
		if Input.is_physical_key_pressed(KEY_A) or (_auswahl < 0 and Input.is_physical_key_pressed(KEY_LEFT)): v.x -= 1
		if Input.is_physical_key_pressed(KEY_D) and not Input.is_physical_key_pressed(KEY_CTRL): v.x += 1
		if _auswahl < 0 and Input.is_physical_key_pressed(KEY_RIGHT): v.x += 1
	var tempo := (18.0 + _hoehe) * (2.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0)
	var bewegung := Basis(Vector3.UP, _yaw) * Vector3(v.x, 0, v.y).normalized() * tempo * delta
	var pos := _kamera.global_position + bewegung
	pos.y = lerpf(pos.y, _hoehe, minf(1.0, delta * 8.0))
	_kamera.global_position = pos
	_kamera_setzen()
	# Vorschau / Ziehen folgt der Maus
	var maus := get_viewport().get_mouse_position()
	var p = _boden(maus)
	if p != null and _geist:
		_geist.position = p
		_geist.rotation = Vector3(0, _drehung, 0)
	if p != null and _zieht and _auswahl >= 0:
		var k := _karte.knoten(_auswahl)
		if k:
			var ziel: Vector3 = p + _zieh_versatz
			if _raster:
				ziel = Vector3(snappedf(ziel.x, 0.5), 0.0, snappedf(ziel.z, 0.5))
			k.position = ziel
	# Markierung über der Auswahl
	if _auswahl >= 0:
		var k := _karte.knoten(_auswahl)
		if k == null:
			_waehlen(-1)
		else:
			_markierung.global_position = k.global_position + Vector3(0, 0.15, 0)
	_info.text = "%d Teile · Raster %s · Pos %s" % [_karte.eintraege.size(), "an" if _raster else "aus",
		"" if p == null else "%.1f / %.1f" % [(p as Vector3).x, (p as Vector3).z]]

func _kamera_setzen() -> void:
	_kamera.rotation = Vector3(_pitch, _yaw, 0)

func _leeren() -> void:
	if %Leeren.text == "Wirklich leeren?":
		_alles_ersetzen("{\"eintraege\": []}")
		%Leeren.text = "Alles leeren"
	else:
		%Leeren.text = "Wirklich leeren?"
		get_tree().create_timer(3.0).timeout.connect(func() -> void: %Leeren.text = "Alles leeren")

func _melden(text: String) -> void:
	%Hinweis.text = text if text != "" else "Katalog links anklicken, dann auf den Boden klicken · F8 beendet"

# ------------------------------------------------------------------ Rückgängig
func _merke(schritt: Dictionary) -> void:
	_verlauf.append(schritt)
	if _verlauf.size() > VERLAUF_MAX:
		_verlauf.pop_front()

func _bewegung_merken(n: int) -> Dictionary:
	var e: Dictionary = _karte.eintraege.get(n, {})
	return {"art": "bewegen", "n": n, "x": float(e.get("x", 0.0)), "y": float(e.get("y", 0.0)),
		"z": float(e.get("z", 0.0)), "r": float(e.get("r", 0.0))}

func _verschieben(n: int, ziel: Vector3) -> void:
	_merke(_bewegung_merken(n))
	_karte.net_bewegen.rpc_id(1, n, ziel, float(_karte.eintraege[n].get("r", 0.0)))

func _alles_ersetzen(text: String) -> void:
	_merke({"art": "alles", "text": _karte.als_text()})
	_waehlen(-1)
	_karte.net_ersetzen.rpc_id(1, text)

func _neu_gesetzt(n: int, von: int) -> void:
	if von != multiplayer.get_unique_id() or _erwartet.is_empty():
		return
	if _erwartet.pop_front() == "neu":
		_merke({"art": "setzen", "n": n})
		if _geist == null and aktiv:
			_waehlen(n)

func _rueckgaengig() -> void:
	if _verlauf.is_empty():
		_melden("Nichts mehr rückgängig zu machen")
		return
	var s: Dictionary = _verlauf.pop_back()
	match str(s.art):
		"setzen":
			if _auswahl == int(s.n):
				_waehlen(-1)
			_karte.net_loeschen.rpc_id(1, int(s.n))
		"bewegen":
			_karte.net_bewegen.rpc_id(1, int(s.n), Vector3(s.x, s.y, s.z), float(s.r))
		"loeschen":
			var e: Dictionary = s.e
			_erwartet.append("wieder")
			_karte.net_setzen.rpc_id(1, str(e.p), Vector3(float(e.x), float(e.y), float(e.z)), float(e.get("r", 0.0)),
				float(e.get("s", 1.0)), int(e.get("n", 0)), e.get("b", []))
		"alles":
			_waehlen(-1)
			_karte.net_ersetzen.rpc_id(1, str(s.text), true)
	_melden("Rückgängig (%d übrig)" % _verlauf.size())
