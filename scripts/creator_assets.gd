extends RefCounted
## Bausteine des Charakter-Creators: Hüte und Brillen (später Bärte, Kleidung …). Frisuren gibt es bei Männern nicht. Jeder Baustein ist eine
## Szene unter scenes/creator/<art>/, gebaut mit tools/blender/standardkoerper.py (OUTFIT=huete).
## Alle sitzen auf dem einen Standardkörper (scenes/figuren/standard.tscn) und werden über Figur.zubehoer
## an den Kopfknochen gehängt. Teile, deren Name auf "_farbe" endet, werden im Creator eingefärbt,
## alles andere (Band, Feder …) behält seine Festfarbe.
## Die Szenen stehen als Pfad da und werden erst mit laden() geholt: so lädt der Menüstart (und der Server)
## nicht alle Hüte, Brillen und Bärte mit. Ohne class_name (neue Klassennamen brauchen auf dem Server eine Neuindizierung), per preload einbinden.

const HUETE := [
	# Kein Hut: Glatze (der Körper ist kahl, Frisuren kommen als eigene Bausteine)
	{"id": "ohne", "name": "CREATOR_HUT_OHNE", "szene": null, "farbe": Color.WHITE},
	{"id": "filzhut", "name": "CREATOR_HUT_FILZHUT", "szene": "res://scenes/creator/huete/filzhut.tscn", "farbe": Color(0.30, 0.38, 0.22)},
	{"id": "tirolerhut", "name": "CREATOR_HUT_TIROLER", "szene": "res://scenes/creator/huete/tirolerhut.tscn", "farbe": Color(0.30, 0.20, 0.13)},
	{"id": "schiebermuetze", "name": "CREATOR_HUT_SCHIEBER", "szene": "res://scenes/creator/huete/schiebermuetze.tscn", "farbe": Color(0.35, 0.35, 0.38)},
	{"id": "strohhut", "name": "CREATOR_HUT_STROH", "szene": "res://scenes/creator/huete/strohhut.tscn", "farbe": Color(0.92, 0.80, 0.50)},
	{"id": "zylinder", "name": "CREATOR_HUT_ZYLINDER", "szene": "res://scenes/creator/huete/zylinder.tscn", "farbe": Color(0.12, 0.12, 0.13)},
	{"id": "wollmuetze", "name": "CREATOR_HUT_WOLLMUETZE", "szene": "res://scenes/creator/huete/wollmuetze.tscn", "farbe": Color(0.75, 0.15, 0.15)},
	{"id": "melone", "name": "CREATOR_HUT_MELONE", "szene": "res://scenes/creator/huete/melone.tscn", "farbe": Color(0.18, 0.18, 0.20)},
	{"id": "baseballcap", "name": "CREATOR_HUT_CAP", "szene": "res://scenes/creator/huete/baseballcap.tscn", "farbe": Color(0.15, 0.30, 0.65)},
	{"id": "fischerhut", "name": "CREATOR_HUT_FISCHER", "szene": "res://scenes/creator/huete/fischerhut.tscn", "farbe": Color(0.55, 0.60, 0.40)},
	{"id": "cowboyhut", "name": "CREATOR_HUT_COWBOY", "szene": "res://scenes/creator/huete/cowboyhut.tscn", "farbe": Color(0.60, 0.42, 0.24)},
	{"id": "stirnband", "name": "CREATOR_HUT_STIRNBAND", "szene": "res://scenes/creator/huete/stirnband.tscn", "farbe": Color(0.85, 0.20, 0.20)},
]

## Brillen. "ohne" = keine Brille. Gestell (Teil "*_farbe") ist einfärbbar, Gläser haben Festfarbe.
const BRILLEN := [
	{"id": "ohne", "name": "CREATOR_BRILLE_OHNE", "szene": null, "farbe": Color.WHITE},
	{"id": "rund", "name": "CREATOR_BRILLE_RUND", "szene": "res://scenes/creator/brillen/rund.tscn", "farbe": Color(0.75, 0.62, 0.25)},
	{"id": "eckig", "name": "CREATOR_BRILLE_ECKIG", "szene": "res://scenes/creator/brillen/eckig.tscn", "farbe": Color(0.10, 0.10, 0.12)},
	{"id": "pilot", "name": "CREATOR_BRILLE_PILOT", "szene": "res://scenes/creator/brillen/pilot.tscn", "farbe": Color(0.78, 0.70, 0.35)},
	{"id": "wayfarer", "name": "CREATOR_BRILLE_WAYFARER", "szene": "res://scenes/creator/brillen/wayfarer.tscn", "farbe": Color(0.08, 0.08, 0.09)},
	{"id": "lesebrille", "name": "CREATOR_BRILLE_LESE", "szene": "res://scenes/creator/brillen/lesebrille.tscn", "farbe": Color(0.45, 0.28, 0.16)},
	{"id": "oval", "name": "CREATOR_BRILLE_OVAL", "szene": "res://scenes/creator/brillen/oval.tscn", "farbe": Color(0.55, 0.55, 0.58)},
	{"id": "sonnenbrille_rund", "name": "CREATOR_BRILLE_SONNE_RUND", "szene": "res://scenes/creator/brillen/sonnenbrille_rund.tscn", "farbe": Color(0.07, 0.07, 0.08)},
	{"id": "sonnenbrille_eckig", "name": "CREATOR_BRILLE_SONNE_ECKIG", "szene": "res://scenes/creator/brillen/sonnenbrille_eckig.tscn", "farbe": Color(0.72, 0.60, 0.22)},
	{"id": "monokel", "name": "CREATOR_BRILLE_MONOKEL", "szene": "res://scenes/creator/brillen/monokel.tscn", "farbe": Color(0.72, 0.60, 0.22)},
	{"id": "herzbrille", "name": "CREATOR_BRILLE_HERZ", "szene": "res://scenes/creator/brillen/herzbrille.tscn", "farbe": Color(0.95, 0.30, 0.50)},
]

## Augenformen (Augenfarbe bleibt schwarz). Brauen und Mund gehören zum Basiskörper (scenes/figuren/basis.tscn),
## die Augen kommen als Baustein. Teile mit "_haut" im Namen (Lider) werden in der Hautfarbe eingefärbt.
const AUGEN := [
	{"id": "gross", "name": "CREATOR_AUGE_GROSS", "szene": "res://scenes/creator/augen/gross.tscn"},
	{"id": "klein", "name": "CREATOR_AUGE_KLEIN", "szene": "res://scenes/creator/augen/klein.tscn"},
	{"id": "oval_hoch", "name": "CREATOR_AUGE_OVAL_HOCH", "szene": "res://scenes/creator/augen/oval_hoch.tscn"},
	{"id": "oval_breit", "name": "CREATOR_AUGE_OVAL_BREIT", "szene": "res://scenes/creator/augen/oval_breit.tscn"},
	{"id": "muede", "name": "CREATOR_AUGE_MUEDE", "szene": "res://scenes/creator/augen/muede.tscn"},
	{"id": "wuetend", "name": "CREATOR_AUGE_WUETEND", "szene": "res://scenes/creator/augen/wuetend.tscn"},
	{"id": "schielend", "name": "CREATOR_AUGE_SCHIELEND", "szene": "res://scenes/creator/augen/schielend.tscn"},
	{"id": "punkte", "name": "CREATOR_AUGE_PUNKTE", "szene": "res://scenes/creator/augen/punkte.tscn"},
	{"id": "grosse_pupillen", "name": "CREATOR_AUGE_PUPILLEN", "szene": "res://scenes/creator/augen/grosse_pupillen.tscn"},
	{"id": "zwinkernd", "name": "CREATOR_AUGE_ZWINKERND", "szene": "res://scenes/creator/augen/zwinkernd.tscn"},
]

## Gesichtsausdrücke (Brauen + Mund, z. B. Wut). Der Basiskörper hat weder Augen noch Brauen noch Mund,
## alles drei kommt als Baustein. Brauen heißen "*_farbe" (Haarfarbe).
const EMOTIONEN := [
	{"id": "freundlich", "name": "CREATOR_EMO_FREUNDLICH", "szene": "res://scenes/creator/emotionen/freundlich.tscn"},
	{"id": "wuetend", "name": "CREATOR_EMO_WUETEND", "szene": "res://scenes/creator/emotionen/wuetend.tscn"},
	{"id": "froehlich", "name": "CREATOR_EMO_FROEHLICH", "szene": "res://scenes/creator/emotionen/froehlich.tscn"},
	{"id": "traurig", "name": "CREATOR_EMO_TRAURIG", "szene": "res://scenes/creator/emotionen/traurig.tscn"},
	{"id": "ueberrascht", "name": "CREATOR_EMO_UEBERRASCHT", "szene": "res://scenes/creator/emotionen/ueberrascht.tscn"},
	{"id": "skeptisch", "name": "CREATOR_EMO_SKEPTISCH", "szene": "res://scenes/creator/emotionen/skeptisch.tscn"},
	{"id": "genervt", "name": "CREATOR_EMO_GENERVT", "szene": "res://scenes/creator/emotionen/genervt.tscn"},
	{"id": "grinsend", "name": "CREATOR_EMO_GRINSEND", "szene": "res://scenes/creator/emotionen/grinsend.tscn"},
]

## Bärte. "ohne" = glatt rasiert. Bart-Teile heißen "*_farbe" und werden in der Haarfarbe eingefärbt.
const BAERTE := [
	{"id": "ohne", "name": "CREATOR_BART_OHNE", "szene": null, "farbe": Color.WHITE},
	{"id": "schnauzer", "name": "CREATOR_BART_SCHNAUZER", "szene": "res://scenes/creator/baerte/schnauzer.tscn", "farbe": Color(0.35, 0.22, 0.12)},
	{"id": "walross", "name": "CREATOR_BART_WALROSS", "szene": "res://scenes/creator/baerte/walross.tscn", "farbe": Color(0.45, 0.30, 0.18)},
	{"id": "fumanchu", "name": "CREATOR_BART_FUMANCHU", "szene": "res://scenes/creator/baerte/fumanchu.tscn", "farbe": Color(0.12, 0.09, 0.07)},
	{"id": "kinnbart", "name": "CREATOR_BART_KINN", "szene": "res://scenes/creator/baerte/kinnbart.tscn", "farbe": Color(0.30, 0.18, 0.10)},
	{"id": "backenbart", "name": "CREATOR_BART_BACKEN", "szene": "res://scenes/creator/baerte/backenbart.tscn", "farbe": Color(0.55, 0.55, 0.57)},
	{"id": "vollbart", "name": "CREATOR_BART_VOLL", "szene": "res://scenes/creator/baerte/vollbart.tscn", "farbe": Color(0.38, 0.24, 0.14)},
	{"id": "stoppeln", "name": "CREATOR_BART_STOPPELN", "szene": "res://scenes/creator/baerte/stoppeln.tscn", "farbe": Color(0.20, 0.15, 0.12)},
	{"id": "zotteln", "name": "CREATOR_BART_ZOTTELN", "szene": "res://scenes/creator/baerte/zotteln.tscn", "farbe": Color(0.93, 0.93, 0.94)},
	{"id": "kinnband", "name": "CREATOR_BART_KINNBAND", "szene": "res://scenes/creator/baerte/kinnband.tscn", "farbe": Color(0.12, 0.09, 0.07)},
	{"id": "hufeisen", "name": "CREATOR_BART_HUFEISEN", "szene": "res://scenes/creator/baerte/hufeisen.tscn", "farbe": Color(0.25, 0.20, 0.15)},
]

## Auswahl der Haarfarben im Creator (Bart und Augenbrauen werden damit eingefärbt)
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

## Szene eines Eintrags laden (null bei "ohne")
static func laden(e: Dictionary) -> PackedScene:
	var pfad: Variant = e.get("szene")
	return load(str(pfad)) as PackedScene if pfad != null else null

## Alle Teile von `wurzel`, deren Name zu `muster` passt (Standard: "_farbe"), in `farbe` färben
static func faerben(wurzel: Node, farbe: Color, muster := "*_farbe*") -> void:
	for n in wurzel.find_children(muster, "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s) as BaseMaterial3D
			if m == null:
				continue
			var k := m.duplicate() as BaseMaterial3D
			k.albedo_color = farbe
			mi.set_surface_override_material(s, k)
