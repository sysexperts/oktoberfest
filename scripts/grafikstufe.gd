extends Node
## Grafikstufe (Plan 4.4) — schaltet die teuren Dinge je nach Einstellung:
##   Niedrig: 120 Besucher, jedes dritte Kirmeslicht, kein Glow, Nebel, SSAO,
##            keine Farbkorrektur
##   Mittel:  250 Besucher, zwei von drei Lichtern, Glow und Nebel, kein SSAO
##   Hoch:    alles, wie gebaut
## Lichter blenden auf Niedrig/Mittel in der Ferne aus. Die Zeltbeleuchtung
## bleibt immer an — dort wird gespielt.
## Werte messen: tools/grafik_messen.tscn. Liegt als Knoten in main.tscn.

const BESUCHER := [120, 250, 400]
## Ab dieser Entfernung blenden Kirmeslichter aus (0 = nie)
const LICHT_AUSBLENDEN := [25.0, 45.0, 0.0]

@export var welt: NodePath = ^"../WorldEnvironment"
@export var menge: NodePath = ^"../Crowd"
## Nur Lichter unterhalb dieses Knotens werden reduziert.
@export var kirmes: NodePath = ^"../Kirmes"

var _lichter: Array[OmniLight3D] = []

func _ready() -> void:
	var wurzel := get_node_or_null(kirmes)
	if wurzel:
		for l in wurzel.find_children("*", "OmniLight3D", true, false):
			_lichter.append(l as OmniLight3D)
	Einstellungen.geaendert.connect(anwenden)
	anwenden()

func anwenden() -> void:
	var stufe := clampi(Einstellungen.grafik, 0, 2)
	var we := get_node_or_null(welt) as WorldEnvironment
	if we and we.environment:
		we.environment.ssao_enabled = stufe >= 2
		we.environment.glow_enabled = stufe >= 1
		we.environment.fog_enabled = stufe >= 1
		# Farbkorrektur kostet einen ganzen Nachbearbeitungsschritt — gemessen
		# ~13 ms pro Bild auf integrierter Grafik, mehr als Glow und Nebel zusammen
		we.environment.adjustment_enabled = stufe >= 1
	var m := get_node_or_null(menge)
	if m and "max_visitors" in m:
		m.max_visitors = BESUCHER[stufe]
	for i in _lichter.size():
		var l := _lichter[i]
		# Fest nach Position in der Liste, damit immer dieselben an bleiben
		l.visible = stufe == 2 or (stufe == 1 and i % 3 != 2) or (stufe == 0 and i % 3 == 0)
		l.distance_fade_enabled = LICHT_AUSBLENDEN[stufe] > 0.0
		l.distance_fade_begin = LICHT_AUSBLENDEN[stufe]
		l.distance_fade_length = 10.0

func lichter_gesamt() -> int:
	return _lichter.size()

func sichtbare_lichter() -> int:
	return _lichter.filter(func(l: OmniLight3D) -> bool: return l.visible).size()
