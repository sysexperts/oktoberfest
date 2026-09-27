extends Node3D
## Glücksrad — reines Glücksspiel. Aufbau: scenes/kirmes/gluecksrad.tscn — gebackener
## Stand (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige mit vier Einsatzknöpfen.
##
## Beim Budenbesitzer E → Blick aufs Rad. Einsatz wählen (1/10/100/1.000 €) → der
## Server zieht ihn ab, würfelt das Feld und bucht den Gewinn (GameManager.
## net_gluecksrad_setzen). Hier dreht das Rad nur noch sichtbar dorthin — der Spieler
## hat keinen Einfluss, darum lässt sich nichts ausnutzen. Esc beendet.

## Eintritt kostet nichts, bezahlt wird je Drehung
@export var preis := 0
@export var hinweis := "HINT_GLUECKSRAD"
## So lange (s) dreht das Rad bis zum Ergebnis
@export var drehdauer := 3.2
## Volle Umdrehungen bis zum Ziel
@export var umdrehungen := 4

## Markiert den Stand für den Server: abgerechnet wird je Einsatz, nicht nach Treffern
const Texte := preload("res://scripts/ui/texte.gd")

var glueckspiel := true

## Faktor ×10 je Feld im Uhrzeigersinn ab oben (tools/bake_kirmes_spiele.gd, RAD_WERTE;
## GameManager.GLUECK_FELDER)
const WERTE := [0, 20, 10, 0, 15, 10, 0, 50, 0, 10, 20, 0, 10, 0, 10, 0]
const FELD := TAU / 16.0
const EINSAETZE := [1, 10, 100, 1000]

enum { WARTET, DREHT, WACKELT, ZEIGT }

var _spieler: Node = null
var _winkel := 0.0
var _zustand := WARTET
var _start := 0.0
var _ziel := 0.0
var _t := 0.0
var _zeigen := 0.0
var _einsatz := 0
var _gewinn := 0
## Show-Effekte: Tick je Stift, Wackeln am Ende, Lampen, Konfetti, Münzen
var _letztes_feld := 0
var _wackel_t := 0.0
var _wackel_ziel := 0.0
var _jubel_t := 0.0
var _blink_t := 0.0
var _zaehl_t := 0.0
var _birnen: Array[Node3D] = []
## Feld mit ×5 — daneben stehen bleiben ist ein Beinahe-Treffer
const GROSS := 50

@onready var _rad: Node3D = $Stand/Rad
@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _ergebnis: Label = $Anzeige/Ergebnis
@onready var _knoepfe: Array[Button] = [$Anzeige/Einsaetze/Einsatz1, $Anzeige/Einsaetze/Einsatz10,
	$Anzeige/Einsaetze/Einsatz100, $Anzeige/Einsaetze/Einsatz1000]
@onready var _besitzer: Node3D = $Besitzer

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	_besitzer.position = ($Stand/BesitzerMitte as Node3D).position
	for i in _knoepfe.size():
		_knoepfe[i].pressed.connect(setzen.bind(EINSAETZE[i]))
	for n in _rad.get_children():
		if String(n.name).begins_with("Birne"):
			_birnen.append(n)
	# Konfetti vor dem Rad
	$Konfetti.position = _rad.position + Vector3(0, 0.3, 0.6)

func laeuft() -> bool:
	return _spieler != null

func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Stand/BesitzerMitte as Node3D).position, ($Stand/BesitzerSeite as Node3D).position)

func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_zustand = WARTET
	_kamera.current = true
	_anzeige.visible = true
	_ergebnis.visible = false
	# Maus frei für die Einsatzknöpfe
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_knoepfe_frei(true)
	_knoepfe[0].grab_focus.call_deferred()
	_info.text = tr("GLUECKSRAD_SETZEN")

## Einsatz wählen → Server entscheidet (GameManager.net_gluecksrad_setzen)
func setzen(einsatz: int) -> void:
	if _spieler == null or _zustand == DREHT:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_gluecksrad_setzen"):
		_knoepfe_frei(false)
		welt.net_gluecksrad_setzen.rpc_id(1, einsatz)
		# Kommt keine Antwort (kein Geld), Knöpfe nach kurzer Zeit wieder frei
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if _zustand != DREHT and _spieler != null:
				_knoepfe_frei(true))

## Antwort vom Server: auf dieses Feld drehen
func drehen_auf(feld: int, einsatz: int, gewinn: int) -> void:
	if _spieler == null:
		return
	_einsatz = einsatz
	_gewinn = gewinn
	_ergebnis.visible = false
	_knoepfe_frei(false)
	# Ziel: nächster Winkel mit diesem Feld oben, plus volle Umdrehungen
	var basis := feld * FELD
	var ziel := basis + TAU * ceilf((_winkel - basis) / TAU)
	_start = _winkel
	_ziel = ziel + TAU * umdrehungen
	_t = 0.0
	_zustand = DREHT
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder("klick", "pop", -10.0)

func _process(delta: float) -> void:
	if _spieler == null or _zustand == WARTET:
		# Ohne Spieler bzw. vor dem Einsatz dreht es gemächlich — lockt Besucher an
		_winkel += delta * 0.35
		_rad.rotation.z = _winkel
		return
	match _zustand:
		DREHT:
			_t = minf(1.0, _t + delta / drehdauer)
			# lange auslaufen: zum Schluss kriecht das Rad über die letzten Stifte
			_winkel = lerpf(_start, _ziel, 1.0 - pow(1.0 - _t, 4.0))
			_tick()
			if _t >= 1.0:
				_winkel = fmod(_ziel, TAU)
				if _beinahe():
					# neben dem ×5: kurz zum großen Feld hin wackeln, dann zurückfallen
					_zustand = WACKELT
					_wackel_t = 0.0
					_wackel_ziel = _winkel
				else:
					_ergebnis_zeigen()
		WACKELT:
			_wackel_t += delta
			var zum_gross := signf(angle_difference(_wackel_ziel, _gross_winkel()))
			_winkel = _wackel_ziel + zum_gross * FELD * 0.42 * sin(_wackel_t * 9.0) * exp(-_wackel_t * 2.2)
			_tick()
			if _wackel_t >= 1.3:
				_winkel = _wackel_ziel
				_ergebnis_zeigen()
		ZEIGT:
			_feiern(delta)
			_zeigen -= delta
			if _zeigen <= 0.0:
				_zustand = WARTET
				_ergebnis.visible = false
				for b in _birnen:
					b.visible = true
	_rad.rotation.z = _winkel

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	# Zifferntasten 1–4 als Abkürzung
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.keycode >= KEY_1 and k.keycode <= KEY_4:
		setzen(EINSAETZE[k.keycode - KEY_1])

## Feld unter dem Zeiger
func feld_oben() -> int:
	return posmod(roundi(_winkel / FELD), WERTE.size())

func _ergebnis_zeigen() -> void:
	_zustand = ZEIGT
	_zeigen = 2.6 if _gewinn > _einsatz else 1.6
	_jubel_t = 0.0
	_blink_t = 0.0
	_zaehl_t = 0.0
	var faktor: int = WERTE[feld_oben()]
	if _gewinn > _einsatz:
		var f := str(faktor / 10) if faktor % 10 == 0 else "%d,%d" % [faktor / 10, faktor % 10]
		_ergebnis.text = tr("GLUECKSRAD_GEWINN") % [f, Texte.euro(_gewinn - _einsatz)]
	elif _gewinn == _einsatz:
		_ergebnis.text = tr("GLUECKSRAD_ZURUECK")
	else:
		_ergebnis.text = tr("GLUECKSRAD_VERLOREN") % Texte.euro(_einsatz)
	_ergebnis.visible = true
	_knoepfe_frei(true)
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		if faktor >= GROSS:
			sfx.play("ding", 0.0)
			sfx.play_oder("cheer", "pop", 0.0)
		elif _gewinn > _einsatz:
			sfx.play("ding")
			sfx.play_oder("cheer", "pop", -6.0)
		else:
			sfx.play_oder("pop", "pop", -8.0)
	if faktor >= GROSS:
		$Konfetti.restart()
	if _gewinn > _einsatz:
		_muenzen(mini(12, 3 + int(log(float(_gewinn - _einsatz)) / log(10.0) * 3.0)))

## Beim Überfahren eines Stifts klicken — zum Ende hin immer langsamer
func _tick() -> void:
	var f := floori(_winkel / FELD + 0.5)
	if f == _letztes_feld:
		return
	_letztes_feld = f
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder("klick", "pop", -16.0 if _t < 0.8 else -9.0)

func _gross_winkel() -> float:
	return WERTE.find(GROSS) * FELD

## Liegt das Ergebnis direkt neben dem ×5?
func _beinahe() -> bool:
	var g := WERTE.find(GROSS)
	var f := feld_oben()
	return f != g and (posmod(f - g, WERTE.size()) == 1 or posmod(g - f, WERTE.size()) == 1)

## Gewinn feiern: Lampen blinken, Budenbesitzer jubelt, Betrag zählt hoch
func _feiern(delta: float) -> void:
	if _gewinn <= _einsatz:
		return
	var gross: bool = WERTE[feld_oben()] >= GROSS
	_blink_t += delta
	var an := int(_blink_t * (10.0 if gross else 6.0)) % 2 == 0
	for i in _birnen.size():
		_birnen[i].visible = an == (i % 2 == 0) or _zeigen < 0.4
	_jubel_t += delta
	var figur := _besitzer.get_node_or_null("Model") as Figur
	if figur and gross:
		if _zeigen > 0.3:
			figur.jubel_pose(_jubel_t)
		else:
			figur.pose_loesen()
			figur.stehen()
	# Betrag hochzählen
	_zaehl_t = minf(1.0, _zaehl_t + delta / 0.9)
	var f: int = WERTE[feld_oben()]
	var fs := str(f / 10) if f % 10 == 0 else "%d,%d" % [f / 10, f % 10]
	_ergebnis.text = tr("GLUECKSRAD_GEWINN") % [fs, Texte.euro(roundi((_gewinn - _einsatz) * _zaehl_t))]

## Münzen fliegen vom Ergebnis zum Kontostand oben links
func _muenzen(anzahl: int) -> void:
	var vorlage := $Anzeige/Muenze as TextureRect
	var start := _ergebnis.get_global_rect().get_center()
	var ziel := Vector2(60, 36)
	for i in anzahl:
		var m := vorlage.duplicate() as TextureRect
		$Anzeige.add_child(m)
		m.visible = true
		m.position = start + Vector2(randf_range(-80, 80), randf_range(-20, 20))
		var tw := m.create_tween()
		tw.tween_interval(i * 0.07)
		tw.tween_property(m, "position", ziel, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(m, "scale", Vector2(0.6, 0.6), 0.7)
		tw.tween_callback(func() -> void:
			var sfx = get_tree().current_scene.get_node_or_null("Sfx")
			if sfx and i % 3 == 0:
				sfx.play_oder("muenzen", "pop", -14.0)
			m.queue_free())

func _knoepfe_frei(an: bool) -> void:
	for i in _knoepfe.size():
		_knoepfe[i].disabled = not an or Game.money < int(EINSAETZE[i])

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, 0)
	_anzeige.visible = false
	_kamera.current = false
	_zustand = WARTET
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
