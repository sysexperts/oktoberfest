extends Control
## Ansicht für alle Animationen: links die Liste (alte "geliehen/…" und neue "mixamo/…"), rechts ein Mann und eine Frau
## (Dirndl) in der gewählten Animation. Mit der Maus drehen, mit dem Mausrad zoomen. Starten: Szene öffnen und F6,
## oder godot --path . res://scenes/werkzeuge/animationen_ansicht.tscn

const Look := preload("res://scripts/charakter_look.gd")

var _mann: Figur
var _frau: Figur
var _aktuell := ""
var _wartet := 0.0
var _zoom := 4.2
var _ziehen := false

func _ready() -> void:
	var lm := Look.standard("m")
	lm["hut"] = "tirolerhut"
	lm["hut_farbe"] = "4a6a3a"
	_mann = _figur_bauen(lm, %MannPlatz)
	_frau = _figur_bauen(Look.standard("w"), %FrauPlatz)
	await get_tree().process_frame
	for f: Figur in [_mann, _frau]:
		f.stehen()
	_liste_fuellen()
	%Suche.text_changed.connect(func(_t: String) -> void: _liste_fuellen())
	%Clips.item_selected.connect(_gewaehlt)
	%Pause.toggled.connect(func(an: bool) -> void:
		for f: Figur in _figuren():
			f.anim.speed_scale = 0.0 if an else %Tempo.value)
	%Tempo.value_changed.connect(func(v: float) -> void:
		%TempoText.text = "%.2f×" % v
		if not %Pause.button_pressed:
			for f: Figur in _figuren():
				f.anim.speed_scale = v)
	%Zeit.drag_started.connect(func() -> void: _ziehen = true)
	%Zeit.drag_ended.connect(func(_g: bool) -> void: _ziehen = false)
	%Zeit.value_changed.connect(func(v: float) -> void:
		if _ziehen and _aktuell != "":
			for f: Figur in _figuren():
				f.anim.seek(v * f.anim.get_animation(_aktuell).length, true))
	var gruppe := ButtonGroup.new()
	for b: Button in [%NurMann, %NurFrau, %Beide]:
		b.button_group = gruppe
		b.pressed.connect(_figuren_zeigen)
	%Beide.button_pressed = true
	_figuren_zeigen()
	%Vorschau.gui_input.connect(_vorschau_eingabe)
	if %Clips.item_count > 0:
		%Clips.select(0)
		_gewaehlt(0)

func _figur_bauen(l: Dictionary, platz: Node3D) -> Figur:
	var f := Look.bauen(l)
	platz.add_child(f)
	Look.faerben(f, l)
	return f

func _figuren() -> Array[Figur]:
	var r: Array[Figur] = []
	if _mann.visible:
		r.append(_mann)
	if _frau.visible:
		r.append(_frau)
	return r

func _figuren_zeigen() -> void:
	_mann.visible = not %NurFrau.button_pressed
	_frau.visible = not %NurMann.button_pressed
	%MannPlatz.position.x = -0.45 if %Beide.button_pressed else 0.0
	%FrauPlatz.position.x = 0.45 if %Beide.button_pressed else 0.0
	if _aktuell != "":
		_abspielen(_aktuell)

func _liste_fuellen() -> void:
	var filter := (%Suche.text as String).to_lower()
	%Clips.clear()
	var namen: Array[String] = []
	for n in _mann.anim.get_animation_list():
		if String(n) != "RESET" and (filter == "" or String(n).to_lower().contains(filter)):
			namen.append(String(n))
	# mixamo zuerst, dann geliehen
	namen.sort_custom(func(a: String, b: String) -> bool:
		var am := a.begins_with("mixamo/")
		var bm := b.begins_with("mixamo/")
		return a < b if am == bm else am)
	for n in namen:
		var i: int = %Clips.add_item(n)
		%Clips.set_item_metadata(i, n)
	%Anzahl.text = "%d Animationen" % namen.size()

func _gewaehlt(i: int) -> void:
	_aktuell = str(%Clips.get_item_metadata(i))
	_abspielen(_aktuell)

func _abspielen(name: String) -> void:
	%Name.text = name
	for f: Figur in _figuren():
		f.anim.root_motion_track = NodePath()
		f.anim.stop()
		if not f.abspielen(name):
			# z. B. Männer-Clips bei der Frau: sie steht stattdessen
			f.stehen()
			continue
		f.anim.seek(0.0, true)
		f.anim.speed_scale = 0.0 if %Pause.button_pressed else %Tempo.value
	var a := _mann.anim.get_animation(name)
	%Laenge.text = "%.1f s%s" % [a.length, "  (einmalig)" if a.loop_mode == Animation.LOOP_NONE else "  (Schleife)"]

func _process(delta: float) -> void:
	if _aktuell == "" or _mann == null:
		return
	var f: Figur = _mann if _mann.visible else _frau
	var a := f.anim.get_animation(_aktuell)
	if a == null:
		return
	if not _ziehen:
		%Zeit.set_value_no_signal(clampf(f.anim.current_animation_position / maxf(a.length, 0.01), 0.0, 1.0))
	# Einmalige Bewegungen nach kurzer Pause wiederholen
	if a.loop_mode == Animation.LOOP_NONE and not f.anim.is_playing() and %Wiederholen.button_pressed:
		_wartet += delta
		if _wartet > 0.8:
			_wartet = 0.0
			_abspielen(_aktuell)
	var kam: Camera3D = %Kamera
	kam.position = kam.position.lerp(Vector3(0, 1.0, _zoom), clampf(delta * 8.0, 0.0, 1.0))

func _vorschau_eingabe(e: InputEvent) -> void:
	if e is InputEventMouseMotion and (e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		%Drehteller.rotate_y((e as InputEventMouseMotion).relative.x * 0.01)
	elif e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		match (e as InputEventMouseButton).button_index:
			MOUSE_BUTTON_WHEEL_UP: _zoom = maxf(1.6, _zoom - 0.3)
			MOUSE_BUTTON_WHEEL_DOWN: _zoom = minf(8.0, _zoom + 0.3)
