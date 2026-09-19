extends Control
## Sloptoberfest-Logo aus Einzelteilen (assets/ui/logo/, zerlegt mit
## tools/logo_teilen.gd). Szene: scenes/ui/logo_animiert.tscn, Größe wie das
## Originalbild (1774×887) — zum Einbauen einfach skalieren.
##
## Auftritt: Brett fällt ein, Schriftzug plumpst drauf, Fahnen und Ähren klappen
## auf, die Brezel hüpft rein. Danach dauerhaft: Fahnen wehen, Schild wiegt sich
## (Brett + Schriftzug gemeinsam), Brezel wippt, Ähren wiegen sich.
##
## Die Teile dürfen im Editor frei verschoben werden: bei "einpassen" misst das
## Logo die Bounding-Box seiner Teile und skaliert/zentriert sich selbst in den
## Eltern-Control (z. B. die LogoBox im Hauptmenü). Höhe des Eltern-Controls wird
## dabei passend zum Seitenverhältnis gesetzt.

## Selbst in den Eltern-Control einpassen (im Menü an, für freie Platzierung aus)
@export var einpassen := true

@onready var _schrift: TextureRect = $Schriftzug
@onready var _brett: TextureRect = $Brett
@onready var _brezel: TextureRect = $Brezel
@onready var _fahne_l: TextureRect = $FahneLinks
@onready var _fahne_r: TextureRect = $FahneRechts
@onready var _aehre_l: TextureRect = $AehreLinks
@onready var _aehre_r: TextureRect = $AehreRechts

var _t := 0.0
var _bereit := false
var _wackeln := 0.0
var _basis := {}

func _ready() -> void:
	# Drehpunkte: Fahnen an der Stange oben, Ähren an der Brezel-Seite, Rest mittig
	for n: TextureRect in [_schrift, _brett, _brezel]:
		n.pivot_offset = n.size * 0.5
	_fahne_l.pivot_offset = Vector2(_fahne_l.size.x * 0.5, 10)
	_fahne_r.pivot_offset = Vector2(_fahne_r.size.x * 0.5, 10)
	_aehre_l.pivot_offset = Vector2(_aehre_l.size.x, _aehre_l.size.y * 0.6)
	_aehre_r.pivot_offset = Vector2(0, _aehre_r.size.y * 0.6)
	for n in get_children():
		_basis[n] = (n as Control).position
	mouse_entered.connect(func() -> void: _wackeln = 1.0)
	if einpassen:
		pivot_offset = Vector2.ZERO
		var eltern := get_parent() as Control
		if eltern != null:
			eltern.resized.connect(_einpassen)
		_einpassen()
	auftritt()

## Bounding-Box aller Teile in lokalen Koordinaten (Ruhelage, ohne Animation)
func _inhalt() -> Rect2:
	var box := Rect2()
	var erstes := true
	for n in _basis:
		var c: Control = n
		var r := Rect2(_basis[n], c.size)
		box = r if erstes else box.merge(r)
		erstes = false
	return box

## Skaliert und zentriert das Logo so, dass die Teile den Eltern-Control ausfüllen
func _einpassen() -> void:
	var eltern := get_parent() as Control
	if eltern == null:
		return
	var box := _inhalt()
	if box.size.x <= 0.0 or box.size.y <= 0.0 or eltern.size.x <= 0.0:
		return
	# Eltern-Höhe ans Seitenverhältnis der Teile anpassen (setzt sich nach einem
	# Durchlauf von selbst fest, löst also keine Endlosschleife aus)
	var hoehe := eltern.size.x * box.size.y / box.size.x
	if absf(eltern.custom_minimum_size.y - hoehe) > 0.5:
		eltern.custom_minimum_size.y = hoehe
	var s: float = minf(eltern.size.x / box.size.x, maxf(eltern.size.y, hoehe) / box.size.y)
	scale = Vector2(s, s)
	position = -box.position * s + (eltern.size - box.size * s) * 0.5

func auftritt() -> void:
	_bereit = false
	var tw := create_tween().set_parallel(true)
	_brett.position.y = _basis[_brett].y - 500
	_brett.modulate.a = 0.0
	tw.tween_property(_brett, "position:y", _basis[_brett].y, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_brett, "modulate:a", 1.0, 0.2)
	_schrift.scale = Vector2(1.5, 1.5)
	_schrift.modulate.a = 0.0
	tw.tween_property(_schrift, "scale", Vector2.ONE, 0.5).set_delay(0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_schrift, "modulate:a", 1.0, 0.25).set_delay(0.35)
	for f: TextureRect in [_fahne_l, _fahne_r]:
		f.scale = Vector2(1, 0)
		tw.tween_property(f, "scale", Vector2.ONE, 0.45).set_delay(0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	for a: TextureRect in [_aehre_l, _aehre_r]:
		a.scale = Vector2.ZERO
		tw.tween_property(a, "scale", Vector2.ONE, 0.4).set_delay(0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_brezel.position.y = _basis[_brezel].y + 300
	_brezel.modulate.a = 0.0
	tw.tween_property(_brezel, "position:y", _basis[_brezel].y, 0.6).set_delay(0.95).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_brezel, "modulate:a", 1.0, 0.2).set_delay(0.95)
	tw.chain().tween_callback(func() -> void: _bereit = true)

func _process(delta: float) -> void:
	_t += delta
	# Fahnen wehen immer (auch während des Auftritts)
	_fahne_l.rotation = sin(_t * 1.7) * 0.07 + sin(_t * 3.1) * 0.02
	_fahne_r.rotation = sin(_t * 1.7 + 1.3) * 0.07 + sin(_t * 2.9 + 0.5) * 0.02
	if not _bereit:
		return
	_wackeln = maxf(0.0, _wackeln - delta * 1.2)
	# Der Schriftzug klebt auf dem Brett: beide wiegen und neigen sich gemeinsam,
	# sonst löst sich der Text sichtbar vom Schild.
	var wiegen := sin(_t * 1.5) * 3.0
	var neigen := sin(_t * 0.9) * 0.006
	_brett.position.y = _basis[_brett].y + wiegen
	_brett.rotation = neigen
	_schrift.scale = Vector2.ONE
	_schrift.position.y = _basis[_schrift].y + wiegen
	_schrift.rotation = neigen + sin(_t * 18.0) * 0.05 * _wackeln
	# Brezel wippt vor dem Schild, Ähren wiegen sich zu ihr hin
	_brezel.rotation = sin(_t * 2.4) * 0.06
	_brezel.position.y = _basis[_brezel].y + wiegen * 0.5 - absf(sin(_t * 2.4)) * 6.0
	_aehre_l.rotation = sin(_t * 1.3) * 0.045
	_aehre_l.position.y = _basis[_aehre_l].y + wiegen * 0.5
	_aehre_r.rotation = -sin(_t * 1.3) * 0.045
	_aehre_r.position.y = _basis[_aehre_r].y + wiegen * 0.5
