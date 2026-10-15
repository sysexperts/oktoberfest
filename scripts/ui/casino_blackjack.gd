extends CanvasLayer
## Blackjack im Casino (scenes/ui/casino_blackjack.tscn, erzeugt von tools/casino_grafik/bauen_blackjack_tscn.py).
## Jetons antippen = Einsatz, „Austeilen“, dann Karte / Halten / Verdoppeln. Der Server mischt und rechnet (GameManager.net_blackjack),
## hier werden die Karten ausgeteilt, aufgedeckt und das Ergebnis gezeigt. Hält den Spieler wie ein Minispiel fest.

const Texte := preload("res://scripts/ui/texte.gd")
const KARTE := preload("res://scenes/ui/casino_karte.tscn")
const JETONS := [10, 50, 100, 500, 1000]
const KARTE_B := 150.0
const KARTE_H := 210.0
const ABSTAND := 112.0
const REIHE_BANK := 120.0
const REIHE_SPIELER := 462.0
const STAPEL := Vector2(1288, 134)

var aktiv := false
var _spieler: Node = null
var _t := 0.0
var _einsatz := 50
var _gesperrt := false      # Wette abgeschickt, Antwort fehlt noch
var _warte := 0.0
var _runde := false         # eine Runde läuft (Fenster nicht schließbar)
var _sp: Array[TextureRect] = []
var _bank: Array[TextureRect] = []
var _warteschlange: Array = []
var _verarbeitet := false

@onready var _karten: Control = %Karten

func _ready() -> void:
	add_to_group("blackjack_ui")
	visible = false
	for j in JETONS:
		(get_node("%%jeton_%d" % j) as TextureButton).pressed.connect(_jeton_gedrueckt.bind(j))
	%Leeren.pressed.connect(func() -> void:
		_einsatz = 0
		_aktualisieren())
	%Austeilen.pressed.connect(_austeilen)
	%Karte.pressed.connect(func() -> void: _aktion(1))
	%Halten.pressed.connect(func() -> void: _aktion(2))
	%Verdoppeln.pressed.connect(func() -> void: _aktion(3))
	%Schliessen.pressed.connect(beenden)

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
	_tisch_leeren()
	_phase_wette()

func eingabe(event: InputEvent) -> void:
	if _t > 0.25 and event.is_action_pressed("ui_cancel"):
		beenden()

func beenden() -> void:
	if not aktiv or _runde or _gesperrt:
		return
	aktiv = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()

func _process(delta: float) -> void:
	if not aktiv:
		return
	_t += delta
	%Kasse.text = tr("ROULETTE_KASSE") % Texte.euro(Game.money)
	if _gesperrt:
		_warte -= delta
		if _warte <= 0.0:
			# der Server hat die Runde abgelehnt (zu wenig Geld, Tür zu …)
			_gesperrt = false
			%Ergebnis.text = tr("ROULETTE_ABGELEHNT")
			_phase_wette()

# ---------------------------------------------------------------- Wetten
func _phase_wette() -> void:
	_runde = false
	%Aktionen.visible = false
	for n in ["JetonTitel", "Einsatz", "Leeren", "Austeilen"]:
		(get_node("%" + n) as CanvasItem).visible = true
	for j in JETONS:
		(get_node("%%jeton_%d" % j) as CanvasItem).visible = true
	%Regel.visible = true
	%BannerPlatte.visible = false
	%Ergebnis.text = ""
	if not _welt()._afford(_einsatz):
		_einsatz = 0
	_aktualisieren()

func _aktualisieren() -> void:
	%Einsatz.text = tr("ROULETTE_EINSATZ") % Texte.euro(_einsatz)
	%Austeilen.disabled = _einsatz <= 0 or _gesperrt
	%Leeren.disabled = _einsatz <= 0 or _gesperrt
	%Schliessen.disabled = _runde or _gesperrt
	%Kasse.text = tr("ROULETTE_KASSE") % Texte.euro(Game.money)

func _jeton_gedrueckt(wert: int) -> void:
	if _runde or _gesperrt:
		return
	if not _welt()._afford(_einsatz + wert) or _einsatz + wert > _welt().KASINO_MAX_EINSATZ:
		_klang("honk", -14.0)
		return
	_einsatz += wert
	_klang("pop")
	_aktualisieren()

func _austeilen() -> void:
	if _einsatz <= 0 or _gesperrt or _runde:
		return
	_gesperrt = true
	_warte = 3.0
	_tisch_leeren()
	_aktualisieren()
	_welt().net_blackjack.rpc_id(1, 0, _einsatz)

func _aktion(a: int) -> void:
	if not _runde or _gesperrt:
		return
	_gesperrt = true
	_warte = 3.0
	%Aktionen.visible = false
	_welt().net_blackjack.rpc_id(1, a, 0)

# ---------------------------------------------------------------- Zustand vom Server
func stand_zeigen(daten: Dictionary) -> void:
	if not aktiv:
		return
	_warteschlange.append(daten)
	if not _verarbeitet:
		_verarbeiten()

func _verarbeiten() -> void:
	_verarbeitet = true
	while not _warteschlange.is_empty():
		var d: Dictionary = _warteschlange.pop_front()
		await _zeige(d)
	_verarbeitet = false

func _zeige(d: Dictionary) -> void:
	_gesperrt = false
	_runde = true
	%Regel.visible = false
	for n in ["JetonTitel", "Einsatz", "Leeren", "Austeilen"]:
		(get_node("%" + n) as CanvasItem).visible = false
	for j in JETONS:
		(get_node("%%jeton_%d" % j) as CanvasItem).visible = false
	%EinsatzTisch.text = tr("ROULETTE_EINSATZ") % Texte.euro(int(d.einsatz))
	var spieler: Array = d.spieler
	var bank: Array = d.bank
	if _sp.is_empty() and _bank.is_empty():
		await _geben(true, int(spieler[0]))
		await _geben(false, int(bank[0]))
		await _geben(true, int(spieler[1]))
		await _geben(false, -1)
	else:
		for i in range(_sp.size(), spieler.size()):
			await _geben(true, int(spieler[i]))
	if bool(d.vorbei):
		await get_tree().create_timer(0.35).timeout
		_bank[1].aufdecken(int(bank[1]))
		_klang("pop")
		await get_tree().create_timer(0.5).timeout
		_werte_zeigen()
		for i in range(2, bank.size()):
			await get_tree().create_timer(0.35).timeout
			await _geben(false, int(bank[i]))
		await _ergebnis(d)
		return
	%Aktionen.visible = true
	%Verdoppeln.disabled = not bool(d.kann_doppeln)
	_aktualisieren()

## Karte vom Stapel an ihren Platz in der Reihe legen (code -1 = verdeckt liegen lassen)
func _geben(fuer_spieler: bool, code: int) -> void:
	var k: TextureRect = KARTE.instantiate()
	_karten.add_child(k)
	k.position = STAPEL
	k.rotation_degrees = 14.0
	k.scale = Vector2(0.9, 0.9)
	(_sp if fuer_spieler else _bank).append(k)
	var ziel := _platz(fuer_spieler, (_sp if fuer_spieler else _bank).size() - 1, (_sp if fuer_spieler else _bank).size())
	_neu_ordnen(fuer_spieler)
	_klang("pop")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(k, "position", ziel, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(k, "rotation_degrees", randf_range(-2.5, 2.5), 0.36)
	tw.tween_property(k, "scale", Vector2.ONE, 0.36)
	await tw.finished
	if code >= 0:
		await k.aufdecken(code, 0.16)
	_werte_zeigen()
	await get_tree().create_timer(0.12).timeout

func _platz(fuer_spieler: bool, i: int, n: int) -> Vector2:
	var breite := KARTE_B + ABSTAND * (n - 1)
	return Vector2(800.0 - breite / 2.0 + ABSTAND * i, REIHE_SPIELER if fuer_spieler else REIHE_BANK)

## Reihe neu mittig verteilen (die gerade neue Karte fliegt selbst an ihren Platz)
func _neu_ordnen(fuer_spieler: bool) -> void:
	var reihe := _sp if fuer_spieler else _bank
	for i in reihe.size() - 1:
		create_tween().tween_property(reihe[i], "position", _platz(fuer_spieler, i, reihe.size()), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

static func wert(codes: Array) -> int:
	var summe := 0
	var asse := 0
	for c in codes:
		var w := mini((int(c) - 1) % 13 + 1, 10)
		if w == 1:
			asse += 1
			w = 11
		summe += w
	while summe > 21 and asse > 0:
		summe -= 10
		asse -= 1
	return summe

func _werte_zeigen() -> void:
	var s: Array = []
	for k in _sp:
		if k.code >= 0:
			s.append(k.code)
	var b: Array = []
	var verdeckt := false
	for k in _bank:
		if k.code >= 0:
			b.append(k.code)
		else:
			verdeckt = true
	%SpielerWert.text = str(wert(s)) if not s.is_empty() else ""
	%BankWert.text = ((str(wert(b)) + " + ?") if verdeckt else str(wert(b))) if not b.is_empty() else ""

func _ergebnis(d: Dictionary) -> void:
	var netto := int(d.netto)
	var key := str(d.ende)
	var einsatz := int(d.einsatz)
	var text: String = tr(key) % Texte.euro(einsatz if key == "BJ_UNENTSCHIEDEN" else absi(netto))
	%Ergebnis.text = text
	%BannerPlatte.visible = true
	%BannerPlatte.pivot_offset = %BannerPlatte.size / 2.0
	%BannerPlatte.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(%BannerPlatte, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if netto > 0:
		%Ergebnis.add_theme_color_override("font_color", Color(0.6, 1.0, 0.55))
		%Gewinnregen.restart()
		%Gewinnregen.emitting = true
		_klang("cheer")
		_klang("muenzen")
	elif netto < 0:
		%Ergebnis.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
		_klang("glug")
	else:
		%Ergebnis.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
	await get_tree().create_timer(2.6).timeout
	if not aktiv:
		return
	var tw2 := create_tween().set_parallel(true)
	for k in _sp + _bank:
		tw2.tween_property(k, "modulate:a", 0.0, 0.4)
	await tw2.finished
	_tisch_leeren()
	_einsatz = einsatz
	_phase_wette()

func _tisch_leeren() -> void:
	for k in _sp + _bank:
		if is_instance_valid(k):
			k.queue_free()
	_sp.clear()
	_bank.clear()
	%SpielerWert.text = ""
	%BankWert.text = ""
	%EinsatzTisch.text = ""
	%BannerPlatte.visible = false
