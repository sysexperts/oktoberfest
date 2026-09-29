extends Node3D
## Trailer: eine Horde, die aufs Ziel zurennt. Die Figuren erscheinen verteilt
## im Kasten „bereich“ (um diesen Knoten, im Editor als Kasten zu sehen) und
## rennen los, sobald die Aufnahme beginnt. Wer das Ziel erreicht, läuft noch
## ein Stück weiter und verschwindet dann (durchs Zelttor).
## Optional folgt das Blickziel der Kamera der Spitze der Horde.

const Figuren := preload("res://scripts/figuren.gd")

@export var anzahl := 120
## Größe des Startbereichs (x = Breite, z = Tiefe) um diesen Knoten
@export var bereich := Vector3(6, 0, 26)
## Dorthin rennen sie
@export var ziel: Node3D
## Laufgeschwindigkeit in m/s (zufällig je Figur zwischen beiden Werten)
@export var tempo_min := 3.8
@export var tempo_max := 5.2
## Blickziel der Kamera auf die Horde setzen
@export var blickziel: Node3D
## false: auf die Spitze schauen, true: auf die Mitte der Horde (verliert sie nie)
@export var blick_auf_mitte := true
## So weit vor der Spitze liegt das Blickziel (Richtung Ziel)
@export var blick_vorlauf := 2.0

var _laeufer: Array = []   # [Figur, tempo, versatz_x]
var _aktiv := false

## Figuren hinstellen (im Vorlauf), noch stehend
func aufstellen() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	for i in anzahl:
		var f := Figuren.ALLE[rng.randi() % Figuren.ALLE.size()].instantiate() as Figur
		add_child(f)
		f.position = Vector3(rng.randf_range(-0.5, 0.5) * bereich.x, 0.0, rng.randf_range(-0.5, 0.5) * bereich.z)
		_laeufer.append([f, rng.randf_range(tempo_min, tempo_max), f.position.x])
		for mi: MeshInstance3D in f.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_ausrichten()

## Für die nächste Runde der Vorschau: alle zurück an den Start
func zuruecksetzen() -> void:
	_aktiv = false
	for l in _laeufer:
		(l[0] as Node).free()
	_laeufer.clear()
	aufstellen()

## Los!
func starten() -> void:
	_aktiv = true
	for l in _laeufer:
		var f: Figur = l[0]
		f.rennen(float(l[1]) / 4.0)
		if f.anim:
			f.anim.seek(randf() * 0.8, true)

func _ausrichten() -> void:
	if ziel == null:
		return
	for l in _laeufer:
		var f: Figur = l[0]
		var z := ziel.global_position
		z.y = f.global_position.y
		var d := z - f.global_position
		if d.length() > 0.1:
			# Modelle sind um 180° gebacken: nach +z schauen heißt vorwärts
			f.rotation.y = atan2(d.x, d.z)

func _process(delta: float) -> void:
	if not _aktiv or ziel == null:
		return
	var spitze := Vector3.ZERO
	var beste := INF
	var summe := Vector3.ZERO
	var zahl := 0
	for l in _laeufer:
		var f: Figur = l[0]
		if not f.visible:
			continue
		var z := ziel.global_position
		# jeder behält ungefähr seine Spur, sonst laufen alle auf einen Punkt
		z.x += float(l[2]) * 0.6
		z.y = f.global_position.y
		var d := z - f.global_position
		var weit := d.length()
		if weit < 0.5:
			f.visible = false
			continue
		var richtung := d / weit
		f.global_position += richtung * float(l[1]) * delta
		f.rotation.y = lerp_angle(f.rotation.y, atan2(richtung.x, richtung.z), clampf(delta * 8.0, 0.0, 1.0))
		summe += f.global_position
		zahl += 1
		if weit < beste:
			beste = weit
			spitze = f.global_position
	if blickziel and beste < INF:
		var zu := (ziel.global_position - spitze)
		zu.y = 0.0
		var soll := spitze + zu.normalized() * blick_vorlauf + Vector3(0, 1.2, 0)
		if blick_auf_mitte and zahl > 0:
			# Mitte, leicht zur Spitze hin — die Spitze bleibt im Bild
			soll = (summe / zahl).lerp(spitze, 0.35) + Vector3(0, 1.0, 0)
		blickziel.global_position = blickziel.global_position.lerp(soll, clampf(delta * 3.0, 0.0, 1.0))
