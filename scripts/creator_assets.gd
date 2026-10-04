extends RefCounted
## Bausteine des Charakter-Creators: Hüte (später Brillen, Bärte, Haare …). Jeder Baustein ist eine
## Szene unter scenes/creator/<art>/, gebaut mit tools/blender/standardkoerper.py (OUTFIT=huete).
## Alle sitzen auf dem einen Standardkörper (scenes/figuren/standard.tscn) und werden über Figur.zubehoer
## an den Kopfknochen gehängt. Teile, deren Name auf "_farbe" endet, werden im Creator eingefärbt,
## alles andere (Band, Feder …) behält seine Festfarbe.
## Ohne class_name (neue Klassennamen brauchen auf dem Server eine Neuindizierung), per preload einbinden.

const HUETE := [
	# Kein Hut: Glatze (der Körper ist kahl, Frisuren kommen als eigene Bausteine)
	{"id": "ohne", "name": "CREATOR_HUT_OHNE", "szene": null, "farbe": Color.WHITE},
	{"id": "filzhut", "name": "CREATOR_HUT_FILZHUT", "szene": preload("res://scenes/creator/huete/filzhut.tscn"), "farbe": Color(0.30, 0.38, 0.22)},
	{"id": "tirolerhut", "name": "CREATOR_HUT_TIROLER", "szene": preload("res://scenes/creator/huete/tirolerhut.tscn"), "farbe": Color(0.30, 0.20, 0.13)},
	{"id": "schiebermuetze", "name": "CREATOR_HUT_SCHIEBER", "szene": preload("res://scenes/creator/huete/schiebermuetze.tscn"), "farbe": Color(0.35, 0.35, 0.38)},
	{"id": "strohhut", "name": "CREATOR_HUT_STROH", "szene": preload("res://scenes/creator/huete/strohhut.tscn"), "farbe": Color(0.92, 0.80, 0.50)},
	{"id": "zylinder", "name": "CREATOR_HUT_ZYLINDER", "szene": preload("res://scenes/creator/huete/zylinder.tscn"), "farbe": Color(0.12, 0.12, 0.13)},
	{"id": "wollmuetze", "name": "CREATOR_HUT_WOLLMUETZE", "szene": preload("res://scenes/creator/huete/wollmuetze.tscn"), "farbe": Color(0.75, 0.15, 0.15)},
	{"id": "melone", "name": "CREATOR_HUT_MELONE", "szene": preload("res://scenes/creator/huete/melone.tscn"), "farbe": Color(0.18, 0.18, 0.20)},
	{"id": "baseballcap", "name": "CREATOR_HUT_CAP", "szene": preload("res://scenes/creator/huete/baseballcap.tscn"), "farbe": Color(0.15, 0.30, 0.65)},
	{"id": "fischerhut", "name": "CREATOR_HUT_FISCHER", "szene": preload("res://scenes/creator/huete/fischerhut.tscn"), "farbe": Color(0.55, 0.60, 0.40)},
	{"id": "cowboyhut", "name": "CREATOR_HUT_COWBOY", "szene": preload("res://scenes/creator/huete/cowboyhut.tscn"), "farbe": Color(0.60, 0.42, 0.24)},
	{"id": "stirnband", "name": "CREATOR_HUT_STIRNBAND", "szene": preload("res://scenes/creator/huete/stirnband.tscn"), "farbe": Color(0.85, 0.20, 0.20)},
]

## Frisuren (männlich). "ohne" = Glatze, der Körper ist kahl. Die Haarfarbe kommt aus HAARFARBEN.
const FRISUREN := [
	{"id": "ohne", "name": "CREATOR_HAAR_OHNE", "szene": null},
	{"id": "kurzhaar", "name": "CREATOR_HAAR_KURZ", "szene": preload("res://scenes/creator/frisuren/kurzhaar.tscn")},
	{"id": "seitenscheitel", "name": "CREATOR_HAAR_SCHEITEL", "szene": preload("res://scenes/creator/frisuren/seitenscheitel.tscn")},
	{"id": "tolle", "name": "CREATOR_HAAR_TOLLE", "szene": preload("res://scenes/creator/frisuren/tolle.tscn")},
	{"id": "igel", "name": "CREATOR_HAAR_IGEL", "szene": preload("res://scenes/creator/frisuren/igel.tscn")},
	{"id": "langhaar", "name": "CREATOR_HAAR_LANG", "szene": preload("res://scenes/creator/frisuren/langhaar.tscn")},
	{"id": "dutt", "name": "CREATOR_HAAR_DUTT", "szene": preload("res://scenes/creator/frisuren/dutt.tscn")},
	{"id": "irokese", "name": "CREATOR_HAAR_IROKESE", "szene": preload("res://scenes/creator/frisuren/irokese.tscn")},
	{"id": "locken", "name": "CREATOR_HAAR_LOCKEN", "szene": preload("res://scenes/creator/frisuren/locken.tscn")},
	{"id": "topfschnitt", "name": "CREATOR_HAAR_TOPF", "szene": preload("res://scenes/creator/frisuren/topfschnitt.tscn")},
	{"id": "haarkranz", "name": "CREATOR_HAAR_KRANZ", "szene": preload("res://scenes/creator/frisuren/haarkranz.tscn")},
]

## Auswahl der Haarfarben im Creator (die Frisuren sind neutral grau gemalt und werden damit eingefärbt)
const HAARFARBEN := [
	Color(0.93, 0.78, 0.45),   # blond
	Color(0.78, 0.60, 0.30),   # dunkelblond
	Color(0.38, 0.24, 0.14),   # braun
	Color(0.13, 0.09, 0.07),   # schwarz
	Color(0.62, 0.25, 0.12),   # rotbraun
	Color(0.80, 0.34, 0.10),   # rot
	Color(0.62, 0.62, 0.64),   # grau
	Color(0.95, 0.95, 0.95),   # weiß
]

## Alle Teile von `wurzel`, deren Name auf "_farbe" endet, in `farbe` färben
static func faerben(wurzel: Node, farbe: Color) -> void:
	for n in wurzel.find_children("*_farbe*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s) as BaseMaterial3D
			if m == null:
				continue
			var k := m.duplicate() as BaseMaterial3D
			k.albedo_color = farbe
			mi.set_surface_override_material(s, k)
