extends "res://scripts/ui/casino_wetten_basis.gd"
## Würfelbecher im Casino (scenes/ui/casino_wuerfel.tscn, erzeugt von tools/casino_grafik/bauen_wuerfel_tscn.py).
## Wetten: Tief (2 bis 6) und Hoch (8 bis 12) 1:1, Sieben und Pasch 4:1. Der Server würfelt (GameManager.net_wuerfel), hier schüttelt
## der Becher, die Würfel purzeln auf die Bahn und bleiben liegen. Wetten, Jetons und Fenster: scripts/ui/casino_wetten_basis.gd.

const FLAECHEN: Array[Texture2D] = [
	preload("res://assets/casino/wuerfel_1.png"), preload("res://assets/casino/wuerfel_2.png"), preload("res://assets/casino/wuerfel_3.png"),
	preload("res://assets/casino/wuerfel_4.png"), preload("res://assets/casino/wuerfel_5.png"), preload("res://assets/casino/wuerfel_6.png"),
]
const BECHER_RUHE := Vector2(640, 300)
const ZIEL := [Vector2(230, 300), Vector2(500, 350)]
const WURF_ZEIT := 1.0

var _laeuft := false
var letzter_wurf := [0, 0]            # für Tests

@onready var _becher: TextureRect = %Becher
@onready var _wuerfel: Array[TextureRect] = [%Wuerfel0, %Wuerfel1]

func _gruppe() -> String:
	return "wuerfel_ui"

func _beim_zeigen() -> void:
	%Ergebnis.text = tr("ROULETTE_SETZEN")
	%Summe.visible = false
	for w in _wuerfel:
		w.visible = false
	_becher.position = BECHER_RUHE
	_becher.modulate.a = 1.0
	_becher.rotation_degrees = 0.0

func _beim_senden() -> void:
	%Ergebnis.text = tr("WUERFEL_SCHUETTELN")
	%Summe.visible = false
	for w in _wuerfel:
		w.visible = false

func _senden(liste: Array) -> void:
	_welt().net_wuerfel.rpc_id(1, liste)

func _chip_ort(knopf: Button) -> Vector2:
	return knopf.position + Vector2(knopf.size.x - 78, knopf.size.y / 2.0 - 26)

func _process(delta: float) -> void:
	if aktiv:
		_basis_process(delta)

## Vom Server: die Würfel sind gefallen. Nur der Spieler, der gesetzt hat, sieht sie purzeln.
func ergebnis_zeigen(a: int, b: int, spieler_peer: int) -> void:
	if not aktiv or not _gesperrt or spieler_peer != multiplayer.get_unique_id() or _laeuft:
		return
	_laeuft = true
	_warte = 0.0
	letzter_wurf = [a, b]
	_wurf(a, b)

func _wurf(a: int, b: int) -> void:
	# 1. Becher schütteln
	_klang("scrub", -10.0)
	var schuettel := create_tween()
	for i in 9:
		schuettel.tween_property(_becher, "position", BECHER_RUHE + Vector2(randf_range(-26, 26), randf_range(-34, 10)), 0.07)
		schuettel.parallel().tween_property(_becher, "rotation_degrees", randf_range(-14, 14), 0.07)
	await schuettel.finished
	# 2. Becher kippt, die Würfel fliegen heraus
	var kippen := create_tween().set_parallel(true)
	kippen.tween_property(_becher, "rotation_degrees", -62.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	kippen.tween_property(_becher, "position", BECHER_RUHE + Vector2(40, -40), 0.28)
	var start := _becher.position + Vector2(40, 60)
	var ergebnisse := [a, b]
	for i in 2:
		_flug(i, start, ZIEL[i], int(ergebnisse[i]), i * 0.12)
	await get_tree().create_timer(WURF_ZEIT + 0.4).timeout
	# 3. Becher räumt ab
	var weg := create_tween().set_parallel(true)
	weg.tween_property(_becher, "position", BECHER_RUHE + Vector2(260, 0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	weg.tween_property(_becher, "modulate:a", 0.0, 0.5)
	_auswerten(a, b)

## Ein Würfel fliegt im Bogen auf die Bahn, wechselt dabei die Augen und hüpft einmal nach
func _flug(i: int, von: Vector2, nach: Vector2, ziel_augen: int, verzoegerung: float) -> void:
	var w := _wuerfel[i]
	w.visible = true
	w.position = von
	w.scale = Vector2(0.5, 0.5)
	w.texture = FLAECHEN[randi() % 6]
	var drehungen := randf_range(540.0, 900.0) * (1.0 if i == 0 else -1.0)
	var tw := create_tween()
	tw.tween_interval(verzoegerung)
	tw.tween_method(func(t: float) -> void:
		var bogen := Vector2(0, -230.0 * sin(t * PI))
		w.position = von.lerp(nach, ease(t, -2.2)) + bogen
		w.rotation_degrees = drehungen * (1.0 - t)
		w.scale = Vector2.ONE * lerpf(0.5, 1.0, minf(t * 3.0, 1.0))
		if t < 0.82:
			w.texture = FLAECHEN[int(t * 34.0) * 7 % 6]
		else:
			w.texture = FLAECHEN[ziel_augen - 1], 0.0, 1.0, WURF_ZEIT)
	tw.tween_callback(func() -> void: _klang("pop", -4.0))
	# kleiner Hüpfer nach der Landung
	tw.tween_property(w, "position:y", nach.y - 26.0, 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(w, "position:y", nach.y, 0.12).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: _klang("pop", -8.0))

func _auswerten(a: int, b: int) -> void:
	var s := a + b
	%Summe.text = str(s)
	%Summe.visible = true
	%Summe.pivot_offset = %Summe.size / 2.0
	%Summe.scale = Vector2(2.0, 2.0)
	%Summe.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(%Summe, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(%Summe, "modulate:a", 1.0, 0.2)
	var einsatz := _summe()
	var auszahlung := 0
	for w in _wetten:
		var x: int = _welt().wuerfel_auszahlung(w, a, b)
		auszahlung += x
		var chip: Control = _chips.get(w.feld)
		if chip == null or not is_instance_valid(chip):
			continue
		if x > 0:
			chip.pivot_offset = Vector2(26, 26)
			var ct := create_tween().set_loops(4)
			ct.tween_property(chip, "scale", Vector2(1.35, 1.35), 0.18)
			ct.tween_property(chip, "scale", Vector2.ONE, 0.18)
		else:
			create_tween().tween_property(chip, "modulate:a", 0.0, 0.8).set_delay(0.5)
	var netto := auszahlung - einsatz
	if auszahlung > 0 and netto >= 0:
		%Ergebnis.text = tr("WUERFEL_UI_GEWINN") % [a, b, s, Texte.euro(netto)]
		%Ergebnis.add_theme_color_override("font_color", Color(0.6, 1.0, 0.55))
		%Gewinnregen.restart()
		%Gewinnregen.emitting = true
		_klang("cheer")
		_klang("muenzen")
	else:
		%Ergebnis.text = tr("WUERFEL_UI_VERLUST") % [a, b, s, Texte.euro(einsatz - auszahlung)]
		%Ergebnis.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
	await get_tree().create_timer(2.2).timeout
	_laeuft = false
	_gesperrt = false
	if not aktiv:
		return
	_leeren_still()
	%Ergebnis.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
	_becher.rotation_degrees = 0.0
	_becher.position = BECHER_RUHE
	_becher.modulate.a = 1.0
	_aktualisieren()
