extends CanvasLayer
## Watten im Casino (Mini-Version gegen Konrads Bank): drei Karten, wer zwei Stiche holt, gewinnt den Einsatz.
## Die Bank spielt zuerst aus, der Spieler legt eine Karte dagegen, die höhere gewinnt (Gleichstand: Bank).
## Mit „Watten!“ verdoppelt der Spieler den Einsatz, die Bank kann aufgeben. Der Server mischt und rechnet
## (GameManager.net_watten), hier wird nur gezeigt: bayerisches Blatt, Karten fliegen vom Stapel, Stiche werden gelegt.
## Hält den Spieler wie ein Minispiel fest. Aufbau: scenes/ui/watten.tscn (erzeugt von tools/casino_grafik/bauen_watten_tscn.py).

const Texte := preload("res://scripts/ui/texte.gd")
const KARTE := preload("res://scenes/ui/casino_karte.tscn")
const KARTE_SKRIPT := preload("res://scripts/ui/casino_karte.gd")
const JETONS := [10, 50, 100, 500, 1000]
const STAPEL := Vector2(1288, 134)
const HAND_Y := 500.0
const BANK_PLATZ := Vector2(640, 262)
const SPIELER_PLATZ := Vector2(812, 282)
const B_FARBEN := ["eichel", "laub", "herz", "schellen"]
const B_RAENGE := ["7", "8", "9", "10", "unter", "ober", "koenig", "ass"]

var aktiv := false
var _spieler: Node = null
var _t := 0.0
var _einsatz := 50
var _gesperrt := false          # Anfrage unterwegs
var _warte := 0.0
var _runde := false
var _hand: Array[int] = []      # Kartencodes (Farbe * 8 + Rang) der Handkarten, gleiche Reihenfolge wie beim Server
var _gespielt := -1             # Index der gerade gelegten Handkarte
var _gelegt: Array[TextureRect] = []   # Karten auf dem Tisch (Stich)
var _bank_ruecken: Array[TextureRect] = []
var _alt := {}                  # letzter angezeigter Serverstand
var _warteschlange: Array = []
var _verarbeitet := false

@onready var _karten: Control = %Karten
@onready var _haende: Array[TextureButton] = [%Hand0, %Hand1, %Hand2]

func _ready() -> void:
	add_to_group("watten_ui")
	visible = false
	for h in _haende:
		h.pressed.connect(_hand_gedrueckt.bind(h))
		h.mouse_entered.connect(func() -> void: h.modulate = Color(1.15, 1.12, 0.95) if not h.disabled else Color.WHITE)
		h.mouse_exited.connect(func() -> void: h.modulate = Color.WHITE)
	for j in JETONS:
		(get_node("%%jeton_%d" % j) as TextureButton).pressed.connect(_jeton_gedrueckt.bind(j))
	%Leeren.pressed.connect(func() -> void:
		_einsatz = 0
		_aktualisieren())
	%Austeilen.pressed.connect(_austeilen)
	%Watten.pressed.connect(_watten)
	%Neu.pressed.connect(func() -> void:
		_tisch_leeren()
		_phase_wette())
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
			_gesperrt = false
			%Ergebnis.text = tr("ROULETTE_ABGELEHNT")
			if not _runde:
				_phase_wette()
			else:
				_haende_freigeben(true)

# ---------------------------------------------------------------- Einsatz
func _phase_wette() -> void:
	_runde = false
	_alt = {}
	%Aktionen.visible = false
	for n in ["JetonTitel", "Einsatz", "Leeren", "Austeilen"]:
		(get_node("%" + n) as CanvasItem).visible = true
	for j in JETONS:
		(get_node("%%jeton_%d" % j) as CanvasItem).visible = true
	%Regel.visible = true
	%BannerPlatte.visible = false
	%Ergebnis.text = ""
	if not _welt()._afford(_einsatz * 2):
		_einsatz = 0
	_aktualisieren()

func _aktualisieren() -> void:
	%Einsatz.text = tr("ROULETTE_EINSATZ") % Texte.euro(_einsatz)
	%Austeilen.disabled = _einsatz <= 0 or _gesperrt
	%Leeren.disabled = _einsatz <= 0 or _gesperrt
	%Schliessen.disabled = _runde or _gesperrt

func _jeton_gedrueckt(wert: int) -> void:
	if _runde or _gesperrt:
		return
	# Watten verdoppelt den Einsatz, dafür muss Geld da sein
	if not _welt()._afford((_einsatz + wert) * 2) or _einsatz + wert > _welt().KASINO_MAX_EINSATZ:
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
	_welt().net_watten.rpc_id(1, 0, 0, _einsatz)

## Die sichtbaren Handkarten in Reihenfolge (so liegen sie auch beim Server in der Hand)
func _sichtbare() -> Array[TextureButton]:
	var r: Array[TextureButton] = []
	for h in _haende:
		if h.visible:
			r.append(h)
	return r

func _hand_gedrueckt(h: TextureButton) -> void:
	_karte_gelegt(_sichtbare().find(h))

func _karte_gelegt(i: int) -> void:
	if not _runde or _gesperrt or i >= _hand.size():
		return
	_gesperrt = true
	_warte = 3.0
	_gespielt = i
	_haende_freigeben(false)
	%Aktionen.visible = false
	_welt().net_watten.rpc_id(1, 1, i)

func _watten() -> void:
	if not _runde or _gesperrt:
		return
	_gesperrt = true
	_warte = 3.0
	_haende_freigeben(false)
	%Watten.visible = false
	_klang("honk", -8.0)
	_welt().net_watten.rpc_id(1, 2, 0)

func _haende_freigeben(an: bool) -> void:
	for h in _haende:
		h.disabled = not an

# ---------------------------------------------------------------- Stand vom Server
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
	var hand: Array = d.get("hand", [])
	%Regel.visible = false
	for n in ["JetonTitel", "Einsatz", "Leeren", "Austeilen"]:
		(get_node("%" + n) as CanvasItem).visible = false
	for j in JETONS:
		(get_node("%%jeton_%d" % j) as CanvasItem).visible = false
	%EinsatzTisch.text = tr("ROULETTE_EINSATZ") % Texte.euro(int(d.get("einsatz", 0)))
	var neu := not _runde
	_runde = true
	if neu:
		await _austeilen_zeigen(d)
	elif _gespielt >= 0:
		await _stich_zeigen(d)
	elif bool(d.get("gewattet", false)) and not bool(_alt.get("gewattet", false)):
		%BankMeldung.text = str(d.get("meldung", ""))
		_klang("ding")
	_alt = d
	_stiche_zeigen(d)
	if bool(d.get("vorbei", false)):
		await _ende_zeigen(d)
		return
	var bank := int(d.get("bank_karte", -1))
	if bank >= 0 and _gelegt.is_empty():
		await _bank_legt(bank)
	%Aktionen.visible = true
	%Watten.visible = not bool(d.get("gewattet", false))
	%Neu.visible = false
	_haende_freigeben(true)
	_aktualisieren()

func _stiche_zeigen(d: Dictionary) -> void:
	%StichSpieler.text = _punkte(int(d.get("stich_spieler", 0)))
	%StichBank.text = _punkte(int(d.get("stich_bank", 0)))

func _punkte(n: int) -> String:
	return ("● " if n >= 1 else "○ ") + ("●" if n >= 2 else "○")

# ---------------------------------------------------------------- Karten
func _neue_karte(pos: Vector2, drehung := 0.0) -> TextureRect:
	var k: TextureRect = KARTE.instantiate()
	k.bayrisch = true
	_karten.add_child(k)
	k.position = pos
	k.rotation_degrees = drehung
	return k

func _hand_platz(i: int, n: int) -> Vector2:
	var breite := 150.0 * n + 20.0 * (n - 1)
	return Vector2(800.0 - breite / 2.0 + 170.0 * i, HAND_Y)

func _zufalls_farbe(rang: int) -> int:
	return randi() % 4 * 8 + rang

## Neue Runde: drei Karten kommen vom Stapel in die Hand, die Bank spielt aus
func _austeilen_zeigen(d: Dictionary) -> void:
	_hand.clear()
	for r in d.hand:
		_hand.append(_zufalls_farbe(int(r)))
	# Rücken der Bankhand
	for i in 3:
		var k := _neue_karte(STAPEL)
		k.verdeckt()
		k.scale = Vector2(0.55, 0.55)
		_bank_ruecken.append(k)
		var ziel := Vector2(800.0 - 100.0 + i * 70.0 - 41.0, 112.0)
		create_tween().tween_property(k, "position", ziel, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_klang("pop")
		await get_tree().create_timer(0.1).timeout
	for i in _hand.size():
		var h := _haende[i]
		h.visible = true
		h.disabled = true
		h.texture_normal = load("res://assets/casino/karte_ruecken.png")
		h.position = STAPEL
		h.scale = Vector2(0.9, 0.9)
		h.rotation_degrees = 14.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(h, "position", _hand_platz(i, 3), 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(h, "rotation_degrees", 0.0, 0.36)
		tw.tween_property(h, "scale", Vector2.ONE, 0.36)
		_klang("pop")
		await tw.finished
		_hand_aufdecken(i, _hand[i])
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(0.3).timeout

func _hand_aufdecken(i: int, code: int) -> void:
	var h := _haende[i]
	var tw := create_tween()
	tw.tween_property(h, "scale:x", 0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: h.texture_normal = load(KARTE_SKRIPT.b_pfad(code)))
	tw.tween_property(h, "scale:x", 1.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Die Bank spielt eine Karte aus (liegt aufgedeckt auf dem Tisch)
func _bank_legt(rang: int) -> void:
	if not _bank_ruecken.is_empty():
		var r: TextureRect = _bank_ruecken.pop_back()
		r.queue_free()
	var k := _neue_karte(Vector2(700, 112), 0.0)
	k.verdeckt()
	k.scale = Vector2(0.55, 0.55)
	_gelegt.append(k)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(k, "position", BANK_PLATZ, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(k, "scale", Vector2(0.95, 0.95), 0.4)
	tw.tween_property(k, "rotation_degrees", -4.0, 0.4)
	_klang("pop")
	await tw.finished
	await k.aufdecken(_zufalls_farbe(rang), 0.18)

## Meine Karte liegt gegen die der Bank: Stich auswerten
func _stich_zeigen(d: Dictionary) -> void:
	var i := _gespielt
	_gespielt = -1
	var code: int = _hand[i]
	_hand.remove_at(i)
	# Karte von der Hand auf den Tisch
	var h := _sichtbare()[i]
	var k := _neue_karte(h.position, 0.0)
	k.offen(code)
	_gelegt.append(k)
	h.visible = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(k, "position", SPIELER_PLATZ, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(k, "scale", Vector2(0.95, 0.95), 0.35)
	tw.tween_property(k, "rotation_degrees", 3.0, 0.35)
	_klang("pop")
	await tw.finished
	await get_tree().create_timer(0.5).timeout
	var gewonnen := int(d.get("stich_spieler", 0)) > int(_alt.get("stich_spieler", 0))
	var sieger: TextureRect = _gelegt[1] if gewonnen else _gelegt[0]
	var pt := create_tween().set_loops(2)
	pt.tween_property(sieger, "scale", Vector2(1.08, 1.08), 0.15)
	pt.tween_property(sieger, "scale", Vector2(0.95, 0.95), 0.15)
	_klang("ding" if gewonnen else "glug")
	%BankMeldung.text = tr("WATTEN_STICH_DU") if gewonnen else tr("WATTEN_STICH_BANK")
	await get_tree().create_timer(0.9).timeout
	%BankMeldung.text = ""
	var weg := create_tween().set_parallel(true)
	for g in _gelegt:
		weg.tween_property(g, "modulate:a", 0.0, 0.3)
	await weg.finished
	for g in _gelegt:
		g.queue_free()
	_gelegt.clear()
	# übrige Handkarten zusammenrücken
	var rest := _sichtbare()
	for n in rest.size():
		create_tween().tween_property(rest[n], "position", _hand_platz(n, rest.size()), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _ende_zeigen(d: Dictionary) -> void:
	_haende_freigeben(false)
	var key := str(d.get("ende", ""))
	var betrag := int(d.get("betrag", 0))
	var gewonnen := key == "WATTEN_GEWONNEN" or key == "WATTEN_BANK_GIBT_AUF"
	%Ergebnis.text = tr(key) % betrag
	%BannerPlatte.visible = true
	%BannerPlatte.pivot_offset = %BannerPlatte.size / 2.0
	%BannerPlatte.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(%BannerPlatte, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if gewonnen:
		%Ergebnis.add_theme_color_override("font_color", Color(0.6, 1.0, 0.55))
		%Gewinnregen.restart()
		%Gewinnregen.emitting = true
		_klang("cheer")
		_klang("muenzen")
	else:
		%Ergebnis.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
		_klang("glug")
	await get_tree().create_timer(1.2).timeout
	_runde = false
	%Aktionen.visible = true
	%Watten.visible = false
	%Neu.visible = true
	_aktualisieren()

func _tisch_leeren() -> void:
	for k in _gelegt + _bank_ruecken:
		if is_instance_valid(k):
			k.queue_free()
	_gelegt.clear()
	_bank_ruecken.clear()
	_hand.clear()
	_gespielt = -1
	for h in _haende:
		h.visible = false
		h.scale = Vector2.ONE
		h.rotation_degrees = 0.0
		h.modulate = Color.WHITE
	%StichSpieler.text = ""
	%StichBank.text = ""
	%EinsatzTisch.text = ""
	%BankMeldung.text = ""
	%BannerPlatte.visible = false
	%Ergebnis.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
