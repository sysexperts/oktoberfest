extends RefCounted
## Bausteine des Charakter-Creators: Hüte und Brillen (später Bärte, Kleidung …). Frisuren gibt es bei Männern nicht. Jeder Baustein ist eine
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

## Brillen. "ohne" = keine Brille. Gestell (Teil "*_farbe") ist einfärbbar, Gläser haben Festfarbe.
const BRILLEN := [
	{"id": "ohne", "name": "CREATOR_BRILLE_OHNE", "szene": null, "farbe": Color.WHITE},
	{"id": "rund", "name": "CREATOR_BRILLE_RUND", "szene": preload("res://scenes/creator/brillen/rund.tscn"), "farbe": Color(0.75, 0.62, 0.25)},
	{"id": "eckig", "name": "CREATOR_BRILLE_ECKIG", "szene": preload("res://scenes/creator/brillen/eckig.tscn"), "farbe": Color(0.10, 0.10, 0.12)},
	{"id": "pilot", "name": "CREATOR_BRILLE_PILOT", "szene": preload("res://scenes/creator/brillen/pilot.tscn"), "farbe": Color(0.78, 0.70, 0.35)},
	{"id": "wayfarer", "name": "CREATOR_BRILLE_WAYFARER", "szene": preload("res://scenes/creator/brillen/wayfarer.tscn"), "farbe": Color(0.08, 0.08, 0.09)},
	{"id": "lesebrille", "name": "CREATOR_BRILLE_LESE", "szene": preload("res://scenes/creator/brillen/lesebrille.tscn"), "farbe": Color(0.45, 0.28, 0.16)},
	{"id": "oval", "name": "CREATOR_BRILLE_OVAL", "szene": preload("res://scenes/creator/brillen/oval.tscn"), "farbe": Color(0.55, 0.55, 0.58)},
	{"id": "sonnenbrille_rund", "name": "CREATOR_BRILLE_SONNE_RUND", "szene": preload("res://scenes/creator/brillen/sonnenbrille_rund.tscn"), "farbe": Color(0.07, 0.07, 0.08)},
	{"id": "sonnenbrille_eckig", "name": "CREATOR_BRILLE_SONNE_ECKIG", "szene": preload("res://scenes/creator/brillen/sonnenbrille_eckig.tscn"), "farbe": Color(0.72, 0.60, 0.22)},
	{"id": "monokel", "name": "CREATOR_BRILLE_MONOKEL", "szene": preload("res://scenes/creator/brillen/monokel.tscn"), "farbe": Color(0.72, 0.60, 0.22)},
	{"id": "herzbrille", "name": "CREATOR_BRILLE_HERZ", "szene": preload("res://scenes/creator/brillen/herzbrille.tscn"), "farbe": Color(0.95, 0.30, 0.50)},
]

## Augenformen (Augenfarbe bleibt schwarz). Brauen und Mund gehören zum Basiskörper (scenes/figuren/basis.tscn),
## die Augen kommen als Baustein. Teile mit "_haut" im Namen (Lider) werden in der Hautfarbe eingefärbt.
const AUGEN := [
	{"id": "gross", "name": "CREATOR_AUGE_GROSS", "szene": preload("res://scenes/creator/augen/gross.tscn")},
	{"id": "klein", "name": "CREATOR_AUGE_KLEIN", "szene": preload("res://scenes/creator/augen/klein.tscn")},
	{"id": "oval_hoch", "name": "CREATOR_AUGE_OVAL_HOCH", "szene": preload("res://scenes/creator/augen/oval_hoch.tscn")},
	{"id": "oval_breit", "name": "CREATOR_AUGE_OVAL_BREIT", "szene": preload("res://scenes/creator/augen/oval_breit.tscn")},
	{"id": "muede", "name": "CREATOR_AUGE_MUEDE", "szene": preload("res://scenes/creator/augen/muede.tscn")},
	{"id": "wuetend", "name": "CREATOR_AUGE_WUETEND", "szene": preload("res://scenes/creator/augen/wuetend.tscn")},
	{"id": "schielend", "name": "CREATOR_AUGE_SCHIELEND", "szene": preload("res://scenes/creator/augen/schielend.tscn")},
	{"id": "punkte", "name": "CREATOR_AUGE_PUNKTE", "szene": preload("res://scenes/creator/augen/punkte.tscn")},
	{"id": "grosse_pupillen", "name": "CREATOR_AUGE_PUPILLEN", "szene": preload("res://scenes/creator/augen/grosse_pupillen.tscn")},
	{"id": "zwinkernd", "name": "CREATOR_AUGE_ZWINKERND", "szene": preload("res://scenes/creator/augen/zwinkernd.tscn")},
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
