extends CanvasLayer
## Gemeinsame Grundlage der Wett-Fenster im Casino (Roulette, Würfel): Jetons wählen, Wettfelder anklicken, Zurück/Leeren/Wiederholen,
## Wette abschicken und auf die Antwort des Servers warten. Hält den Spieler wie ein Minispiel fest. Die Fenster-Szenen haben dafür die
## Knoten %Wettfelder (Buttons, deren Name die Wette beschreibt), %jeton_<wert>, %JetonAuswahl, %Kasse, %Einsatz, %Ergebnis,
## %Zurueck, %Leeren, %Wiederholen, %Drehen, %Schliessen. Unterklassen: _gruppe(), _feld_zu_wette(), _senden(), _beim_zeigen().

const Texte := preload("res://scripts/ui/texte.gd")
const CHIP_SZENE := preload("res://scenes/ui/casino_chip.tscn")
const JETONS := [10, 50, 100, 500, 1000]

var aktiv := false
var _spieler: Node = null
var _t := 0.0
var _jeton := 50
var _wetten: Array = []              # {typ, wert, einsatz, feld}
var _stapel: Array = []              # Reihenfolge der Jetons für „Zurück“
var _letzte: Array = []
var _chips := {}                     # Feldname -> Chip-Knoten
var _gesperrt := false               # Wette abgeschickt, Runde läuft
var _warte := 0.0                    # Wartezeit auf die Antwort des Servers

@onready var _felder: Control = %Wettfelder

func _ready() -> void:
	add_to_group(_gruppe())
	visible = false
	for k in _felder.get_children():
		if k is Button:
			(k as Button).pressed.connect(_feld_geklickt.bind(k as Button))
	for j in JETONS:
		(get_node("%%jeton_%d" % j) as TextureButton).pressed.connect(_jeton_waehlen.bind(j))
	%Zurueck.pressed.connect(_zurueck)
	%Leeren.pressed.connect(_leeren)
	%Wiederholen.pressed.connect(_wiederholen)
	%Drehen.pressed.connect(_drehen)
	%Schliessen.pressed.connect(beenden)
	_jeton_waehlen(50, false)

## Gruppe, in der der Server das Fenster findet
func _gruppe() -> String:
	return ""

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
	_beim_zeigen()
	_aktualisieren()

func _beim_zeigen() -> void:
	pass

func eingabe(event: InputEvent) -> void:
	if _t > 0.25 and event.is_action_pressed("ui_cancel"):
		beenden()

func beenden() -> void:
	if not aktiv or _gesperrt:
		return
	aktiv = false
	visible = false
	_leeren()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _spieler and is_instance_valid(_spieler):
		_spieler.minispiel_beendet()

func _summe() -> int:
	var s := 0
	for w in _wetten:
		s += int(w.einsatz)
	return s

func _aktualisieren() -> void:
	%Kasse.text = tr("ROULETTE_KASSE") % Texte.euro(Game.money)
	%Einsatz.text = tr("ROULETTE_EINSATZ") % Texte.euro(_summe())
	%Drehen.disabled = _gesperrt or _wetten.is_empty()
	%Zurueck.disabled = _gesperrt or _stapel.is_empty()
	%Leeren.disabled = _gesperrt or _stapel.is_empty()
	%Wiederholen.disabled = _gesperrt or _letzte.is_empty() or not _wetten.is_empty()
	%Schliessen.disabled = _gesperrt

func _jeton_waehlen(wert: int, klang := true) -> void:
	_jeton = wert
	var knopf := get_node("%%jeton_%d" % wert) as Control
	%JetonAuswahl.position = knopf.position - Vector2(10, 10)
	if klang:
		_klang("pop")

## Wette, für die ein Feld steht: {"typ", "wert"}
func _feld_zu_wette(name: String) -> Dictionary:
	var teile := name.split("_")
	if teile.size() == 2:
		return {"typ": teile[0], "wert": int(teile[1])}
	return {"typ": name, "wert": 0}

func _feld_geklickt(knopf: Button) -> void:
	if _gesperrt:
		return
	if not _welt()._afford(_summe() + _jeton):
		_klang("honk", -14.0)
		%Ergebnis.text = tr("ROULETTE_ZU_WENIG")
		return
	var w := _feld_zu_wette(knopf.name)
	var gefunden := false
	for e in _wetten:
		if e.typ == w.typ and e.wert == w.wert:
			e.einsatz = int(e.einsatz) + _jeton
			gefunden = true
	if not gefunden:
		w["einsatz"] = _jeton
		w["feld"] = knopf.name
		_wetten.append(w)
	_stapel.append([str(knopf.name), _jeton])
	_chip_zeigen(knopf)
	_klang("pop")
	%Ergebnis.text = tr("ROULETTE_SETZEN")
	_aktualisieren()

func _chip_zeigen(knopf: Button) -> void:
	var betrag := 0
	for e in _wetten:
		if str(e.feld) == str(knopf.name):
			betrag = int(e.einsatz)
	if betrag <= 0:
		if _chips.has(knopf.name):
			(_chips[knopf.name] as Node).queue_free()
			_chips.erase(knopf.name)
		return
	var chip: Control
	if _chips.has(knopf.name):
		chip = _chips[knopf.name]
	else:
		chip = CHIP_SZENE.instantiate()
		_felder.add_child(chip)
		_chips[knopf.name] = chip
		chip.position = _chip_ort(knopf) + Vector2(randf_range(-6, 6), randf_range(-6, 6))
	chip.setze(betrag)
	chip.scale = Vector2(1.5, 1.5)
	chip.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(chip, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(chip, "modulate:a", 1.0, 0.1)

## Wo der Jeton auf einem Feld liegt (Mitte); breite Felder legen ihn an die Seite
func _chip_ort(knopf: Button) -> Vector2:
	return knopf.position + knopf.size / 2.0 - Vector2(26, 26)

func _zurueck() -> void:
	if _gesperrt or _stapel.is_empty():
		return
	var s: Array = _stapel.pop_back()
	for e in _wetten:
		if str(e.feld) == s[0]:
			e.einsatz = int(e.einsatz) - int(s[1])
			if int(e.einsatz) <= 0:
				_wetten.erase(e)
			break
	_chip_zeigen(_felder.get_node(str(s[0])) as Button)
	_klang("pop")
	_aktualisieren()

func _leeren() -> void:
	_leeren_still()
	_aktualisieren()

func _wiederholen() -> void:
	for w in _letzte:
		var knopf := _felder.get_node(str(w.feld)) as Button
		if not _welt()._afford(_summe() + int(w.einsatz)):
			break
		_wetten.append(w.duplicate())
		_stapel.append([str(w.feld), int(w.einsatz)])
		_chip_zeigen(knopf)
	_klang("pop")
	_aktualisieren()

func _drehen() -> void:
	if _gesperrt or _wetten.is_empty():
		return
	_gesperrt = true
	_warte = 3.0
	_letzte = _wetten.duplicate(true)
	var senden: Array = []
	for w in _wetten:
		var e := {"typ": w.typ, "einsatz": int(w.einsatz)}
		if str(w.typ) in ["zahl", "dutzend", "spalte"]:
			e["wert"] = int(w.wert)
		senden.append(e)
	_beim_senden()
	_klang("ding")
	_aktualisieren()
	_senden(senden)

func _beim_senden() -> void:
	pass

## An den Server schicken (Unterklasse)
func _senden(_liste: Array) -> void:
	pass

## Jetons nach der Runde wegräumen, aber die Wetten für „Wiederholen“ behalten
func _leeren_still() -> void:
	for c in _chips.values():
		if is_instance_valid(c):
			(c as Node).queue_free()
	_chips.clear()
	_wetten.clear()
	_stapel.clear()

## Pro Frame aufrufen: Kasse anzeigen; kommt keine Antwort vom Server, wird die Wette als abgelehnt entsperrt.
func _basis_process(delta: float) -> void:
	_t += delta
	%Kasse.text = tr("ROULETTE_KASSE") % Texte.euro(Game.money)
	if _gesperrt and _warte > 0.0:
		_warte -= delta
		if _warte <= 0.0:
			_gesperrt = false
			%Ergebnis.text = tr("ROULETTE_ABGELEHNT")
			_aktualisieren()
