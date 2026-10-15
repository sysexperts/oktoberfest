extends "res://scripts/ui/casino_wetten_basis.gd"
## Roulette im Casino (scenes/ui/casino_roulette.tscn, Tisch erzeugt tools/casino_grafik/bauen_roulette_tscn.py).
## Jeton wählen, Felder anklicken (Zahl 35:1, Dutzend/Spalte 2:1, Rot/Schwarz/Gerade/Ungerade/1-18/19-36 1:1), „Drehen“.
## Der Server würfelt und schreibt den Gewinn nach der Animation gut (GameManager.net_roulette, KASINO_DAUER);
## hier laufen Kessel und Kugel auf die gezogene Zahl zu. Wetten, Jetons und Fenster: scripts/ui/casino_wetten_basis.gd.

## Fächerreihenfolge im Kessel (gleich wie tools/casino_grafik/rad.py), Fach 0 liegt oben
const REIHENFOLGE := [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
const ROT := [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
const KESSEL_MITTE := Vector2(310, 400)
const R_BAHN := 226.0
const R_FACH := 170.0
const LAUF_ZEIT := 6.6

var _lauf := -1.0
var _ziel := 0
var _w0 := 0.0

@onready var _kessel: TextureRect = %Kessel
@onready var _kugel: TextureRect = %Kugel

func _gruppe() -> String:
	return "roulette_ui"

func _beim_zeigen() -> void:
	%Ergebnis.text = tr("ROULETTE_SETZEN")
	%Gewinnzahl.visible = false
	_kugel.visible = false

func _beim_senden() -> void:
	%Ergebnis.text = tr("ROULETTE_RIEN_NE_VA_PLUS")
	%Gewinnzahl.visible = false

func _senden(liste: Array) -> void:
	_welt().net_roulette.rpc_id(1, liste)

## Vom Server: die Zahl ist gefallen. Nur der Spieler, der gesetzt hat, sieht die Kugel laufen.
func ergebnis_zeigen(zahl: int, spieler_peer: int) -> void:
	if not aktiv or not _gesperrt or spieler_peer != multiplayer.get_unique_id() or _lauf >= 0.0:
		return
	_warte = 0.0
	_ziel = REIHENFOLGE.find(zahl)
	_w0 = _kessel.rotation_degrees
	_lauf = 0.0
	_kugel.visible = true
	_klang("scrub", -16.0)

func _fach_winkel(i: int) -> float:
	return -90.0 + i * (360.0 / 37.0)

func _process(delta: float) -> void:
	if not aktiv:
		return
	_basis_process(delta)
	if _lauf >= 0.0:
		_lauf += delta
		var p := clampf(_lauf / LAUF_ZEIT, 0.0, 1.0)
		var bremse := 1.0 - pow(1.0 - p, 3.0)
		_kessel.rotation_degrees = _w0 + 540.0 * bremse
		var rel := -2520.0 * pow(1.0 - p, 2.3)
		var fall := smoothstep(0.58, 0.86, p)
		var r := lerpf(R_BAHN, R_FACH, fall)
		if p > 0.7 and p < 0.93:
			r += absf(sin((p - 0.7) * 52.0)) * 9.0 * (0.93 - p) / 0.23
		var winkel := deg_to_rad(_fach_winkel(_ziel) + _kessel.rotation_degrees + rel)
		_kugel.position = KESSEL_MITTE + Vector2(cos(winkel), sin(winkel)) * r - Vector2(14, 14)
		if p >= 1.0:
			_lauf = -1.0
			_gelandet()

func _gelandet() -> void:
	var zahl: int = REIHENFOLGE[_ziel]
	var farbe := Color(0.1, 0.62, 0.3) if zahl == 0 else (Color(0.95, 0.22, 0.25) if zahl in ROT else Color(0.92, 0.92, 0.95))
	%Gewinnzahl.text = str(zahl)
	%Gewinnzahl.add_theme_color_override("font_color", farbe)
	%Gewinnzahl.visible = true
	%Gewinnzahl.pivot_offset = %Gewinnzahl.size / 2.0
	%Gewinnzahl.scale = Vector2(2.2, 2.2)
	%Gewinnzahl.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(%Gewinnzahl, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(%Gewinnzahl, "modulate:a", 1.0, 0.2)
	_verlauf_eintragen(zahl)
	# Auswertung: Gewinner pulsieren, Verlierer verblassen
	var einsatz := _summe()
	var auszahlung := 0
	for w in _wetten:
		var a: int = _welt().roulette_auszahlung(w, zahl)
		auszahlung += a
		var chip: Control = _chips.get(w.feld)
		if chip == null or not is_instance_valid(chip):
			continue
		if a > 0:
			chip.pivot_offset = Vector2(26, 26)
			var ct := create_tween().set_loops(4)
			ct.tween_property(chip, "scale", Vector2(1.35, 1.35), 0.18)
			ct.tween_property(chip, "scale", Vector2.ONE, 0.18)
		else:
			create_tween().tween_property(chip, "modulate:a", 0.0, 0.8).set_delay(0.5)
	var farbname := tr("CROUPIER_GRUEN") if zahl == 0 else (tr("CROUPIER_ROT") if zahl in ROT else tr("CROUPIER_SCHWARZ"))
	var netto := auszahlung - einsatz
	if auszahlung > 0 and netto >= 0:
		%Ergebnis.text = tr("ROULETTE_UI_GEWINN") % [zahl, farbname, Texte.euro(netto)]
		%Ergebnis.add_theme_color_override("font_color", Color(0.6, 1.0, 0.55))
		%Gewinnregen.restart()
		%Gewinnregen.emitting = true
		_klang("cheer")
		_klang("muenzen")
	else:
		%Ergebnis.text = tr("ROULETTE_UI_VERLUST") % [zahl, farbname, Texte.euro(einsatz - auszahlung)]
		%Ergebnis.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
	await get_tree().create_timer(1.6).timeout
	_gesperrt = false
	if not aktiv:
		return
	_kugel.visible = false
	_leeren_still()
	%Ergebnis.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
	_aktualisieren()

## Verlauf: kleine runde Felder mit den letzten Zahlen, neueste links
func _verlauf_eintragen(zahl: int) -> void:
	var l := Label.new()
	l.text = str(zahl)
	l.custom_minimum_size = Vector2(48, 48)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 24)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.46, 0.24) if zahl == 0 else (Color(0.72, 0.10, 0.14) if zahl in ROT else Color(0.07, 0.07, 0.09))
	sb.set_corner_radius_all(24)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.91, 0.74, 0.33)
	l.add_theme_stylebox_override("normal", sb)
	%Verlauf.add_child(l)
	%Verlauf.move_child(l, 0)
	while %Verlauf.get_child_count() > 9:
		var letzter := %Verlauf.get_child(%Verlauf.get_child_count() - 1)
		%Verlauf.remove_child(letzter)
		letzter.queue_free()
