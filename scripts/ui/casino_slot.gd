extends CanvasLayer
## Spielautomat im Casino (scenes/ui/casino_slot.tscn, erzeugt von tools/casino_grafik/bauen_slot_tscn.py).
## Drei Walzen mit je drei sichtbaren Symbolen, fünf Gewinnlinien (Mitte, oben, unten, zwei Diagonalen); der Einsatz verteilt sich auf die Linien,
## die Bayernraute ist Wild. Der Server lost das Bild und rechnet (GameManager.net_slot), hier drehen die Walzen und halten nacheinander an,
## dann leuchten die Gewinnlinien und der Gewinn zählt hoch. Hält den Spieler wie ein Minispiel fest.

const Texte := preload("res://scripts/ui/texte.gd")
const STREIFEN_LAENGE := 23           # Symbole je Walze (GameManager.SLOT_STREIFEN), dahinter 3 Wiederholungen für den Übergang
const ZELLE_H := 140.0
const EINSAETZE := [50, 100, 250, 500, 1000]
const DAUER := [1.5, 2.1, 2.7]        # wann die Walzen anhalten
const REIHEN := [[1, 1, 1], [0, 0, 0], [2, 2, 2], [0, 1, 2], [2, 1, 0]]

var aktiv := false
var _spieler: Node = null
var _t := 0.0
var _einsatz := 50
var _gesperrt := false
var _warte := 0.0
var _laeuft := false
var letzte_auszahlung := -1           # für Tests
var _pos := [0.0, 0.0, 0.0]           # Walzenstand (Index des oberen Symbols, Bruchteil = Zwischenstellung)
var _lampen_t := 0.0
var _lampen_tempo := 3.0

@onready var _streifen: Array[Control] = [%Walze0/Streifen, %Walze1/Streifen, %Walze2/Streifen]
@onready var _lampen: Array[Control] = []

func _ready() -> void:
	add_to_group("slot_ui")
	visible = false
	for l in %Lampen.get_children():
		_lampen.append(l)
	for e in EINSAETZE:
		(get_node("%%einsatz_%d" % e) as Button).pressed.connect(_einsatz_waehlen.bind(e))
	%Drehen.pressed.connect(_drehen)
	%Schliessen.pressed.connect(beenden)
	_einsatz_waehlen(50, false)
	for r in 3:
		_pos[r] = float(randi() % STREIFEN_LAENGE)
		_walze_setzen(r)

func laeuft() -> bool:
	return aktiv

func _welt() -> Node:
	return get_parent()

func _klang(name: String, db := -6.0) -> void:
	var s := _welt().get_node_or_null("Sfx")
	if s:
		s.play(name, db)

func zeigen(spieler: Node) -> void:
	if aktiv:
		return
	_spieler = spieler
	aktiv = true
	visible = true
	_t = 0.0
	spieler.minispiel = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%Ergebnis.text = tr("SLOT_BEREIT")
	%LcdText.text = tr("SLOT_LCD_BEREIT")
	for li in %Linien.get_children():
		li.visible = false
	_aktualisieren()

func eingabe(event: InputEvent) -> void:
	if _t > 0.25 and event.is_action_pressed("ui_cancel"):
		beenden()

func beenden() -> void:
	if not aktiv or _gesperrt:
		return
	aktiv = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()

func _einsatz_waehlen(wert: int, klang := true) -> void:
	if _gesperrt:
		return
	_einsatz = wert
	for e in EINSAETZE:
		(get_node("%%einsatz_%d" % e) as Button).button_pressed = e == wert
	if klang:
		_klang("pop")

func _aktualisieren() -> void:
	%Kasse.text = tr("ROULETTE_KASSE") % Texte.euro(Game.money)
	%Kasse2.text = tr("SLOT_EINSATZ_ZEILE") % Texte.euro(_einsatz)
	%Drehen.disabled = _gesperrt
	%Schliessen.disabled = _gesperrt
	for e in EINSAETZE:
		(get_node("%%einsatz_%d" % e) as Button).disabled = _gesperrt

func _drehen() -> void:
	if _gesperrt:
		return
	if not _welt()._afford(_einsatz):
		_klang("honk", -14.0)
		%Ergebnis.text = tr("ROULETTE_ZU_WENIG")
		return
	_gesperrt = true
	_warte = 3.0
	%Ergebnis.text = ""
	%LcdText.text = tr("SLOT_LCD_DREHT")
	for li in %Linien.get_children():
		li.visible = false
	_hebel_ziehen()
	_klang("ding")
	_aktualisieren()
	_welt().net_slot.rpc_id(1, _einsatz)

func _hebel_ziehen() -> void:
	var tw := create_tween()
	tw.tween_property(%Hebel, "rotation_degrees", 38.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(%Hebel, "rotation_degrees", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Vom Server: das Bild steht fest. Nur der Spieler, der gedreht hat, sieht die Walzen laufen.
func ergebnis_zeigen(gitter: Array, halte: Array, treffer: Array, auszahlung: int, spieler_peer: int) -> void:
	if not aktiv or not _gesperrt or spieler_peer != multiplayer.get_unique_id() or _laeuft:
		return
	_laeuft = true
	_warte = 0.0
	letzte_auszahlung = auszahlung
	_ablauf(gitter, halte, treffer, auszahlung)

func _ablauf(_gitter: Array, halte: Array, treffer: Array, auszahlung: int) -> void:
	_lampen_tempo = 14.0
	_klang("scrub", -14.0)
	var enden: Array[Tween] = []
	for r in 3:
		var start: float = fposmod(_pos[r], STREIFEN_LAENGE)
		var ziel := float(int(halte[r]))
		var strecke := 5.0 * STREIFEN_LAENGE + fposmod(ziel - start, STREIFEN_LAENGE) + 2.0 * STREIFEN_LAENGE * r
		var tw := create_tween()
		tw.tween_method(func(f: float) -> void:
			_pos[r] = start + strecke * f
			_walze_setzen(r), 0.0, 1.0, DAUER[r] + 1.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			_pos[r] = fposmod(_pos[r], STREIFEN_LAENGE)
			_walze_setzen(r)
			_klang("pop", -2.0))
		enden.append(tw)
	await enden[2].finished
	_lampen_tempo = 3.0
	await _gewinn_zeigen(treffer, auszahlung)

func _gewinn_zeigen(treffer: Array, auszahlung: int) -> void:
	if auszahlung > 0:
		%LcdText.text = tr("SLOT_LCD_GEWINN") % Texte.euro(0)
		for t in treffer:
			var li := %Linien.get_node("Linie%d" % int(t.linie)) as Line2D
			li.visible = true
		var blink := create_tween().set_loops(5)
		blink.tween_property(%Linien, "modulate:a", 0.25, 0.14)
		blink.tween_property(%Linien, "modulate:a", 1.0, 0.14)
		_klang("cheer")
		_klang("muenzen")
		%Gewinnregen.restart()
		%Gewinnregen.emitting = true
		var zaehl := create_tween()
		zaehl.tween_method(func(v: float) -> void: %LcdText.text = tr("SLOT_LCD_GEWINN") % Texte.euro(int(v)), 0.0, float(auszahlung), 1.2)
		%Ergebnis.text = tr("SLOT_TREFFER") % [treffer.size(), Texte.euro(auszahlung)]
		%Ergebnis.add_theme_color_override("font_color", Color(0.6, 1.0, 0.55))
		await get_tree().create_timer(2.4).timeout
	else:
		%LcdText.text = tr("SLOT_LCD_NIETE")
		%Ergebnis.text = tr("SLOT_NICHTS")
		%Ergebnis.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
		await get_tree().create_timer(1.2).timeout
	_laeuft = false
	_gesperrt = false
	%Ergebnis.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
	if aktiv:
		_aktualisieren()

## Walze r so verschieben, dass der Index _pos[r] oben im Fenster steht
func _walze_setzen(r: int) -> void:
	var p: float = fposmod(_pos[r], STREIFEN_LAENGE)
	_streifen[r].position.y = -p * ZELLE_H

func _process(delta: float) -> void:
	if not aktiv:
		return
	_t += delta
	%Kasse.text = tr("ROULETTE_KASSE") % Texte.euro(Game.money)
	_lampen_t += delta * _lampen_tempo
	for i in _lampen.size():
		var an := fposmod(float(i) / 2.0 - _lampen_t, 4.0) < 1.5
		_lampen[i].modulate = Color(1, 1, 1, 1) if an else Color(0.45, 0.35, 0.2, 1)
	if _gesperrt and not _laeuft and _warte > 0.0:
		_warte -= delta
		if _warte <= 0.0:
			_gesperrt = false
			%Ergebnis.text = tr("ROULETTE_ABGELEHNT")
			%LcdText.text = tr("SLOT_LCD_BEREIT")
			_aktualisieren()
