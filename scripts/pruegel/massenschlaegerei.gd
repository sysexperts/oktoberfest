extends Node3D
## Massenschlägerei: ein Knäuel aus 10–30 Gästen, das etwa DAUER Sekunden tobt.
## Fängt mit ein paar Streithähnen an, reißt dann nach und nach die Umstehenden mit.
## Alle drängen zur Mitte, mehrere prügeln auf einen ein, wer seinen Gegner verliert,
## sucht sich den nächsten; Umgehauene stehen schnell wieder auf und mischen weiter mit.
## Über dem Knäuel hängt Staub, ständig knallt es irgendwo. Danach rappeln sich alle
## auf und hauen ab.
##
## Aufbau: scenes/pruegel/massenschlaegerei.tscn (Staubteppich, Knall-Spieler).
## Benutzt von der Testszene und später vom GameManager-Ereignis im Zelt.

signal vorbei

const SchlagTon := preload("res://scripts/effekte/schlag_ton.gd")

## Sekunden, bis die Schlägerei vorbei ist
@export var dauer := 30.0
## Wie schnell weitere Gäste dazukommen (Sekunden je Gast)
@export var zulauf_takt := 0.3
## Mindestabstand im Knäuel — sonst stecken die Figuren ineinander
@export var abstand := 0.55

var mitte := Vector3.ZERO
var teilnehmer: Array[Node3D] = []
var _warteschlange: Array[Node3D] = []
var _t := 0.0
var _zulauf_t := 0.0
var _knall_t := 0.0
var _laeuft := false

## kandidaten: Gäste (Raufbolde) in der Nähe; anzahl: wie viele mitmachen sollen.
func starten(kandidaten: Array, ort: Vector3, anzahl: int) -> void:
	mitte = ort
	global_position = Vector3(ort.x, 0.0, ort.z)
	var sortiert := kandidaten.filter(func(k: Node3D) -> bool: return k.has_method("ist_frei") and k.ist_frei())
	sortiert.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(ort) < b.global_position.distance_squared_to(ort))
	for k in sortiert.slice(0, anzahl):
		_warteschlange.append(k)
	_laeuft = true
	%Staubteppich.emitting = true
	# Die ersten vier fangen sofort an
	for i in mini(4, _warteschlange.size()):
		_mitmachen(_warteschlange.pop_front())

func laeuft() -> bool:
	return _laeuft

func _mitmachen(r: Node3D) -> void:
	if r == null or not is_instance_valid(r) or not r.ist_frei():
		return
	r.schlaegerei = self
	r.ausdauer = randi_range(4, 7)
	teilnehmer.append(r)
	# Jeder Neue stürzt sich sofort rein — auch ohne Gegner läuft er zur Mitte
	r.gegner = neuer_gegner(r)
	r._setze(r.Zustand.HINGEHEN)

## Gegner im Knäuel: einer der nächsten Beteiligten, der noch auf den Beinen ist,
## etwas zufällig — so gehen auch mal zwei auf einen los. Steht der Angegriffene
## noch herum, geht er gleich auf den Angreifer los.
func neuer_gegner(r: Node3D) -> Node3D:
	var kandidaten: Array = teilnehmer.filter(func(k: Node3D) -> bool:
		return k != r and is_instance_valid(k) and k.schlaegerei == self and (k.kaempft() or k.ist_frei()))
	if kandidaten.is_empty():
		return null
	kandidaten.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(r.global_position) < b.global_position.distance_squared_to(r.global_position))
	var gewaehlt: Node3D = kandidaten[randi() % mini(3, kandidaten.size())]
	if gewaehlt.ist_frei():
		gewaehlt.gegner = r
		gewaehlt._setze(gewaehlt.Zustand.HINGEHEN)
	return gewaehlt

## Knall nur alle paar Hundertstel — sonst wird es bei 30 Leuten Brei.
func darf_knallen() -> bool:
	if _knall_t > 0.0:
		return false
	_knall_t = randf_range(0.08, 0.18)
	return true

func _process(delta: float) -> void:
	if not _laeuft:
		return
	_t += delta
	_knall_t -= delta
	# Zulauf: nach und nach kommen die Umstehenden dazu
	_zulauf_t -= delta
	if _zulauf_t <= 0.0 and not _warteschlange.is_empty():
		_zulauf_t = zulauf_takt
		_mitmachen(_warteschlange.pop_front())
	# Abstoßen im Knäuel und Mitte nachführen
	var aktiv: Array[Node3D] = []
	var summe := Vector3.ZERO
	for r in teilnehmer:
		if is_instance_valid(r) and r.schlaegerei == self:
			aktiv.append(r)
			summe += r.global_position
	if not aktiv.is_empty():
		mitte = mitte.lerp(summe / float(aktiv.size()), clampf(delta * 0.5, 0.0, 1.0))
		global_position = Vector3(mitte.x, 0.0, mitte.z)
	for i in aktiv.size():
		for j in range(i + 1, aktiv.size()):
			var a := aktiv[i]
			var b := aktiv[j]
			var d := b.global_position - a.global_position
			d.y = 0.0
			var l := d.length()
			if l < abstand and l > 0.001:
				var schub := d / l * (abstand - l) * 0.5
				a.global_position -= schub
				b.global_position += schub
	# Staub dichter, je mehr gerade prügeln
	var kaempfend := aktiv.filter(func(r: Node3D) -> bool: return r.kaempft()).size()
	%Staubteppich.amount_ratio = clampf(float(kaempfend) / 20.0, 0.25, 1.0)
	# Hintergrund-Tumult: dumpfe Schläge irgendwo im Knäuel
	if kaempfend > 2 and randf() < delta * 6.0:
		var knall: AudioStreamPlayer3D = %Tumult
		knall.stream = SchlagTon.hol("schlag")
		knall.pitch_scale = randf_range(0.7, 1.2)
		knall.volume_db = randf_range(-12.0, -4.0)
		knall.global_position = aktiv.pick_random().global_position
		knall.play()
	if _t >= dauer:
		beenden()

func beenden() -> void:
	if not _laeuft:
		return
	_laeuft = false
	%Staubteppich.emitting = false
	for r in teilnehmer:
		if not is_instance_valid(r) or r.schlaegerei != self:
			continue
		r.schlaegerei = null
		if r.kaempft():
			r.gegner = null
			r._setze(r.Zustand.FLUCHT if r.flucht_ziel != Vector3.INF else r.Zustand.RUHIG)
	vorbei.emit()
	get_tree().create_timer(3.0).timeout.connect(queue_free)
