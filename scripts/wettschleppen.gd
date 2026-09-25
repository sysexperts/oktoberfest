extends Node3D
## Finale gegen Huber: Maß-Wettschleppen um Sepps Ehre (letzter Festtag).
## Der Herausforderer trägt 10 volle Maß durch die Tore (Tore/T1 … T6, dann
## zurück durchs Start-Tor), Huber läuft seine Runde gleichzeitig daneben.
## Rennen oder scharfes Lenken bringt die Krüge zum Schwappen (Balken oben);
## läuft er über, ist eine Maß verschüttet: +STRAF_SEKUNDEN auf die Zeit.
##
## Start und Ergebnis gehen über den Server (GameManager.net_duell_start /
## net_duell_ende), der Lauf selbst läuft beim Herausforderer lokal, Huber bei
## allen gleich (feste Zeit vom Server). Aufbau: scenes/wettschleppen/.

const KRUEGE := 10
const STRAF_SEKUNDEN := 2.5
const TOR_RADIUS := 1.9
const COUNTDOWN := 3.0
## Tempo beim Tragen von 10 Maß (Anteil der normalen Laufgeschwindigkeit)
const TRAG_TEMPO := 0.85
## Schwappen: Rennen und schnelles Drehen füllen den Balken, ruhiges Gehen leert ihn
const SCHWAPP_RENNEN := 0.3   # ~3 s Sprint gehen gut, dann ruhig gehen
const SCHWAPP_DREHEN := 0.09
const SCHWAPP_RUHE := 0.4

@onready var _tore: Array[Node3D] = []
@onready var _kruege: Node3D = $Kruege
@onready var _anzeige: CanvasLayer = $Anzeige

var aktiv := false
var ich_laufe := false
var _t := -COUNTDOWN
var _huber_zeit := 17.0
var _naechstes := 1
var _verschuettet := 0
var _schwapp := 0.0
var _spieler: Node3D = null
var _huber: Node3D = null
var _huber_weg: Array[Vector3] = []
var _huber_start := Transform3D()
var _letzter_yaw := 0.0
var _gezaehlt := -1

func _ready() -> void:
	add_to_group("wettschleppen")
	for t in $Tore.get_children():
		_tore.append(t as Node3D)
	# Tore quer zur Strecke drehen und nummerieren
	for i in _tore.size():
		var vor := _tore[(i - 1 + _tore.size()) % _tore.size()].global_position
		var nach := _tore[(i + 1) % _tore.size()].global_position
		var richtung := (nach - vor)
		richtung.y = 0.0
		_tore[i].rotation.y = atan2(richtung.x, richtung.z)
		var text := tr("DUELL_START_ZIEL") if i == 0 else str(i)
		for l in ["Nummer", "NummerHinten"]:
			var label := _tore[i].get_node_or_null(l) as Label3D
			if label:
				label.text = text
				if i == 0:
					label.font_size = 56

## Tore sieht man am letzten Festtag und während des Duells
func _process(delta: float) -> void:
	var gm := get_tree().current_scene
	if not aktiv:
		visible = gm != null and gm.has_method("ist_finale") and gm.ist_finale()
		return
	_t += delta
	if _t < 0.0:
		var sek := ceili(-_t)
		if sek != _gezaehlt:
			_gezaehlt = sek
			_gross(str(sek))
		return
	if _gezaehlt != 0:
		_gezaehlt = 0
		_gross("DUELL_LOS")
		if ich_laufe and _spieler:
			_spieler.minispiel_beendet()
	_huber_laufen()
	if ich_laufe:
		_lauf(delta)

func _gross(text: String) -> void:
	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("grosser_text"):
		hud.grosser_text(text)

## Vom Server bei allen: Duell beginnt. duellant = Peer-ID des Herausforderers.
func starten(duellant: int, huber_zeit: float) -> void:
	var gm := get_tree().current_scene
	aktiv = true
	visible = true
	_t = -COUNTDOWN
	_gezaehlt = -1
	_huber_zeit = huber_zeit
	_naechstes = 1
	_verschuettet = 0
	_schwapp = 0.0
	ich_laufe = duellant == multiplayer.get_unique_id()
	# Huber läuft auf seiner Bahn einen Meter neben der Torlinie
	_huber = get_tree().get_first_node_in_group("huber") as Node3D
	_huber_weg.clear()
	for i in range(1, _tore.size() + 1):
		var tor := _tore[i % _tore.size()]
		_huber_weg.append(tor.global_position + tor.global_transform.basis.x * 0.8)
	if _huber:
		_huber_start = _huber.global_transform
		_huber.global_position = _tore[0].global_position + _tore[0].global_transform.basis.x * 0.8
		if _huber.has_method("rennen"):
			_huber.rennen(true)
	_spieler = gm._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in gm else null
	if not ich_laufe:
		return
	# Herausforderer an die Startlinie, Blick zum ersten Tor, 10 Maß in die Hände
	var start := _tore[0]
	_spieler.global_position = start.global_position - start.global_transform.basis.x * 0.8 + Vector3(0, 0.1, 0)
	var zu := _tore[1].global_position - _spieler.global_position
	_spieler.rotation.y = atan2(-zu.x, -zu.z)
	_letzter_yaw = _spieler.rotation.y
	_spieler.minispiel = self   # während des Countdowns stillhalten
	_spieler.set("tempo_faktor", TRAG_TEMPO)
	var hand := _spieler.get_node_or_null("Head/HoldPoint")
	if hand:
		_kruege.reparent(hand, false)
		_kruege.transform = Transform3D(Basis().scaled(Vector3.ONE * 0.75), Vector3(-0.35, -0.32, -0.05))
	for k in _kruege.get_children():
		(k as Node3D).visible = true
	_kruege.visible = true
	_anzeige.visible = true
	_anzeige_aktualisieren()

## player.gd leitet Eingaben während des Countdowns hierher (nichts tun)
func eingabe(_event: InputEvent) -> void:
	pass

func laeuft() -> bool:
	return aktiv and _t < 0.0

func _huber_laufen() -> void:
	if _huber == null or _huber_weg.is_empty():
		return
	# Gleichmäßig über die ganze Strecke verteilt, sodass er genau bei _huber_zeit ankommt
	var laenge := 0.0
	var punkte: Array[Vector3] = [_tore[0].global_position + _tore[0].global_transform.basis.x * 0.8]
	punkte.append_array(_huber_weg)
	for i in punkte.size() - 1:
		laenge += punkte[i].distance_to(punkte[i + 1])
	var weg := clampf(_t / _huber_zeit, 0.0, 1.0) * laenge
	for i in punkte.size() - 1:
		var s := punkte[i].distance_to(punkte[i + 1])
		if weg <= s or i == punkte.size() - 2:
			var p := punkte[i].lerp(punkte[i + 1], clampf(weg / maxf(s, 0.01), 0.0, 1.0))
			_huber.global_position = Vector3(p.x, 0.0, p.z)
			var r := punkte[i + 1] - punkte[i]
			_huber.rotation.y = atan2(r.x, r.z)
			break
		weg -= s
	if _t >= _huber_zeit and _huber.has_method("rennen"):
		_huber.rennen(false)

func _huber_tor() -> int:
	return mini(_tore.size(), int(floor(clampf(_t / _huber_zeit, 0.0, 1.0) * float(_tore.size()))) + 1)

func _lauf(delta: float) -> void:
	if _spieler == null or not is_instance_valid(_spieler):
		return
	# Schwappen: Rennen und schnelles Drehen beim Laufen
	var tempo := Vector2(_spieler.velocity.x, _spieler.velocity.z).length()
	var dreh := absf(angle_difference(_letzter_yaw, _spieler.rotation.y)) / maxf(delta, 0.001)
	_letzter_yaw = _spieler.rotation.y
	var rennt := Input.is_action_pressed("sprint") and tempo > 1.0
	var zu := 0.0
	if rennt:
		zu += SCHWAPP_RENNEN
	if tempo > 0.8:
		zu += maxf(0.0, dreh - 1.2) * SCHWAPP_DREHEN
	_schwapp = clampf(_schwapp + (zu - (SCHWAPP_RUHE if zu == 0.0 else 0.0)) * delta, 0.0, 1.0)
	if _schwapp >= 1.0:
		_verschuettet += 1
		_schwapp = 0.35
		var k := _kruege.get_child(KRUEGE - _verschuettet) as Node3D
		if k:
			k.visible = false
		if _spieler.has_method("_sfx"):
			_spieler._sfx("splash")
		if _verschuettet >= KRUEGE:
			_fertig()
			return
	# Tore der Reihe nach, zum Schluss wieder durchs Start-Tor
	var ziel := _tore[_naechstes % _tore.size()]
	var abstand := Vector2(_spieler.global_position.x - ziel.global_position.x, _spieler.global_position.z - ziel.global_position.z).length()
	if abstand < TOR_RADIUS:
		if _naechstes >= _tore.size():
			_fertig()
			return
		_naechstes += 1
		if _spieler.has_method("_sfx"):
			_spieler._sfx("ding")
	_anzeige_aktualisieren()

## Nächstes Tor für den Zielpfeil (scripts/ui/zielmarker.gd)
func naechstes_tor() -> Node3D:
	if not (aktiv and ich_laufe):
		return null
	return _tore[_naechstes % _tore.size()]

func _anzeige_aktualisieren() -> void:
	%Mass.text = "%d" % (KRUEGE - _verschuettet)
	%Zeit.text = "%.1f s" % maxf(_t, 0.0) + ("  (+%.0f s)" % (_verschuettet * STRAF_SEKUNDEN) if _verschuettet > 0 else "")
	%Huber.text = tr("DUELL_HUBER_TOR") % _huber_tor() if _t < _huber_zeit else tr("DUELL_HUBER_FERTIG") % _huber_zeit
	%Schwapp.value = _schwapp
	%Titel.text = tr("DUELL_TITEL")
	%Hinweis.text = tr("DUELL_HINWEIS") % (_tore.size() - 1)

func _fertig() -> void:
	ich_laufe = false
	var gm := get_tree().current_scene
	if gm.has_method("net_duell_ende"):
		gm.net_duell_ende.rpc_id(1, _t, _verschuettet)
	_aufraeumen_spieler()

func _aufraeumen_spieler() -> void:
	_anzeige.visible = false
	_kruege.visible = false
	if _kruege.get_parent() != self:
		_kruege.reparent(self, false)
	if _spieler and is_instance_valid(_spieler):
		_spieler.set("tempo_faktor", 1.0)
		if _spieler.minispiel == self:
			_spieler.minispiel_beendet()

## Vom Server bei allen: Duell vorbei. Huber geht zurück vor sein Zelt.
func beenden() -> void:
	aktiv = false
	if ich_laufe:
		ich_laufe = false
		_aufraeumen_spieler()
	if _huber and is_instance_valid(_huber):
		_huber.global_transform = _huber_start
		if _huber.has_method("rennen"):
			_huber.rennen(false)

## Länge der Runde (Start → alle Tore → Start), ohne die Torradien
func strecken_laenge() -> float:
	var l := 0.0
	for i in _tore.size():
		l += _tore[i].global_position.distance_to(_tore[(i + 1) % _tore.size()].global_position)
	return maxf(10.0, l - TOR_RADIUS * 2.0 * float(_tore.size()) * 0.5)
