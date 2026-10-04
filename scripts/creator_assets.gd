extends RefCounted
## Bausteine des Charakter-Creators: Hüte (später Brillen, Bärte, Haare …). Jeder Baustein ist eine
## Szene unter scenes/creator/<art>/, gebaut mit tools/blender/standardkoerper.py (OUTFIT=huete).
## Alle sitzen auf dem einen Standardkörper (scenes/figuren/standard.tscn) und werden über Figur.zubehoer
## an den Kopfknochen gehängt. Teile, deren Name auf "_farbe" endet, werden im Creator eingefärbt,
## alles andere (Band, Feder …) behält seine Festfarbe.
## Ohne class_name (neue Klassennamen brauchen auf dem Server eine Neuindizierung), per preload einbinden.

const HUETE := [
	{"id": "filzhut", "name": "CREATOR_HUT_FILZHUT", "szene": preload("res://scenes/creator/huete/filzhut.tscn"), "farbe": Color(0.30, 0.38, 0.22)},
	{"id": "tirolerhut", "name": "CREATOR_HUT_TIROLER", "szene": preload("res://scenes/creator/huete/tirolerhut.tscn"), "farbe": Color(0.30, 0.20, 0.13)},
	{"id": "schiebermuetze", "name": "CREATOR_HUT_SCHIEBER", "szene": preload("res://scenes/creator/huete/schiebermuetze.tscn"), "farbe": Color(0.35, 0.35, 0.38)},
	{"id": "strohhut", "name": "CREATOR_HUT_STROH", "szene": preload("res://scenes/creator/huete/strohhut.tscn"), "farbe": Color(0.92, 0.80, 0.50)},
	{"id": "zylinder", "name": "CREATOR_HUT_ZYLINDER", "szene": preload("res://scenes/creator/huete/zylinder.tscn"), "farbe": Color(0.12, 0.12, 0.13)},
	{"id": "wollmuetze", "name": "CREATOR_HUT_WOLLMUETZE", "szene": preload("res://scenes/creator/huete/wollmuetze.tscn"), "farbe": Color(0.75, 0.15, 0.15)},
	{"id": "melone", "name": "CREATOR_HUT_MELONE", "szene": preload("res://scenes/creator/huete/melone.tscn"), "farbe": Color(0.18, 0.18, 0.20)},
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
