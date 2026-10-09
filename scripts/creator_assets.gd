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
	{"id": "kochmuetze", "name": "CREATOR_HUT_KOCH", "szene": "res://scenes/creator/huete/kochmuetze.tscn", "farbe": Color(0.97, 0.97, 0.95)},
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
	# Scherzbrille der Casino-Tarnung (Gustav): nur über Figuren.tarnung(), nie im Creator wählbar ("versteckt")
	{"id": "tarnbrille", "name": "CREATOR_BRILLE_TARN", "szene": "res://scenes/creator/brillen/tarnbrille.tscn", "farbe": Color(0.03, 0.03, 0.035), "versteckt": true},
	{"id": "security_brille", "name": "CREATOR_BRILLE_SECURITY", "szene": "res://scenes/creator/brillen/security_brille.tscn", "farbe": Color(0.08, 0.08, 0.09)},
]

## Augenformen (Augenfarbe bleibt schwarz). Brauen und Mund gehören zum Basiskörper (scenes/figuren/basis.tscn),
## die Augen kommen als Baustein. Teile mit "_haut" im Namen (Lider) werden in der Hautfarbe eingefärbt.
const AUGEN := [
	{"id": "gross", "name": "CREATOR_AUGE_GROSS", "szene": "res://scenes/creator/augen/gross.tscn", "g": "m"},
	{"id": "klein", "name": "CREATOR_AUGE_KLEIN", "szene": "res://scenes/creator/augen/klein.tscn", "g": "m"},
	{"id": "oval_hoch", "name": "CREATOR_AUGE_OVAL_HOCH", "szene": "res://scenes/creator/augen/oval_hoch.tscn", "g": "m"},
	{"id": "oval_breit", "name": "CREATOR_AUGE_OVAL_BREIT", "szene": "res://scenes/creator/augen/oval_breit.tscn", "g": "m"},
	{"id": "muede", "name": "CREATOR_AUGE_MUEDE", "szene": "res://scenes/creator/augen/muede.tscn", "g": "m"},
	{"id": "wuetend", "name": "CREATOR_AUGE_WUETEND", "szene": "res://scenes/creator/augen/wuetend.tscn", "g": "m"},
	{"id": "schielend", "name": "CREATOR_AUGE_SCHIELEND", "szene": "res://scenes/creator/augen/schielend.tscn", "g": "m"},
	{"id": "punkte", "name": "CREATOR_AUGE_PUNKTE", "szene": "res://scenes/creator/augen/punkte.tscn", "g": "m"},
	{"id": "grosse_pupillen", "name": "CREATOR_AUGE_PUPILLEN", "szene": "res://scenes/creator/augen/grosse_pupillen.tscn", "g": "m"},
	{"id": "zwinkernd", "name": "CREATOR_AUGE_ZWINKERND", "szene": "res://scenes/creator/augen/zwinkernd.tscn", "g": "m"},
	{"id": "gross_w", "name": "CREATOR_AUGE_GROSS", "szene": "res://scenes/creator/augen/gross_w.tscn", "g": "w"},
	{"id": "klein_w", "name": "CREATOR_AUGE_KLEIN", "szene": "res://scenes/creator/augen/klein_w.tscn", "g": "w"},
	{"id": "oval_hoch_w", "name": "CREATOR_AUGE_OVAL_HOCH", "szene": "res://scenes/creator/augen/oval_hoch_w.tscn", "g": "w"},
	{"id": "muede_w", "name": "CREATOR_AUGE_MUEDE", "szene": "res://scenes/creator/augen/muede_w.tscn", "g": "w"},
	{"id": "grosse_pupillen_w", "name": "CREATOR_AUGE_PUPILLEN", "szene": "res://scenes/creator/augen/grosse_pupillen_w.tscn", "g": "w"},
	{"id": "zwinkernd_w", "name": "CREATOR_AUGE_ZWINKERND", "szene": "res://scenes/creator/augen/zwinkernd_w.tscn", "g": "w"},
]

## Gesichtsausdrücke (Brauen + Mund, z. B. Wut). Der Basiskörper hat weder Augen noch Brauen noch Mund,
## alles drei kommt als Baustein. Brauen heißen "*_farbe" (Haarfarbe).
const EMOTIONEN := [
	{"id": "freundlich", "name": "CREATOR_EMO_FREUNDLICH", "szene": "res://scenes/creator/emotionen/freundlich.tscn", "g": "m"},
	{"id": "wuetend", "name": "CREATOR_EMO_WUETEND", "szene": "res://scenes/creator/emotionen/wuetend.tscn", "g": "m"},
	{"id": "froehlich", "name": "CREATOR_EMO_FROEHLICH", "szene": "res://scenes/creator/emotionen/froehlich.tscn", "g": "m"},
	{"id": "traurig", "name": "CREATOR_EMO_TRAURIG", "szene": "res://scenes/creator/emotionen/traurig.tscn", "g": "m"},
	{"id": "ueberrascht", "name": "CREATOR_EMO_UEBERRASCHT", "szene": "res://scenes/creator/emotionen/ueberrascht.tscn", "g": "m"},
	{"id": "skeptisch", "name": "CREATOR_EMO_SKEPTISCH", "szene": "res://scenes/creator/emotionen/skeptisch.tscn", "g": "m"},
	{"id": "genervt", "name": "CREATOR_EMO_GENERVT", "szene": "res://scenes/creator/emotionen/genervt.tscn", "g": "m"},
	{"id": "grinsend", "name": "CREATOR_EMO_GRINSEND", "szene": "res://scenes/creator/emotionen/grinsend.tscn", "g": "m"},
	{"id": "freundlich_w", "name": "CREATOR_EMO_FREUNDLICH", "szene": "res://scenes/creator/emotionen/freundlich_w.tscn", "g": "w"},
	{"id": "wuetend_w", "name": "CREATOR_EMO_WUETEND", "szene": "res://scenes/creator/emotionen/wuetend_w.tscn", "g": "w"},
	{"id": "froehlich_w", "name": "CREATOR_EMO_FROEHLICH", "szene": "res://scenes/creator/emotionen/froehlich_w.tscn", "g": "w"},
	{"id": "traurig_w", "name": "CREATOR_EMO_TRAURIG", "szene": "res://scenes/creator/emotionen/traurig_w.tscn", "g": "w"},
	{"id": "ueberrascht_w", "name": "CREATOR_EMO_UEBERRASCHT", "szene": "res://scenes/creator/emotionen/ueberrascht_w.tscn", "g": "w"},
	{"id": "skeptisch_w", "name": "CREATOR_EMO_SKEPTISCH", "szene": "res://scenes/creator/emotionen/skeptisch_w.tscn", "g": "w"},
	{"id": "genervt_w", "name": "CREATOR_EMO_GENERVT", "szene": "res://scenes/creator/emotionen/genervt_w.tscn", "g": "w"},
	{"id": "grinsend_w", "name": "CREATOR_EMO_GRINSEND", "szene": "res://scenes/creator/emotionen/grinsend_w.tscn", "g": "w"},
]

## Bärte. "ohne" = glatt rasiert. Bart-Teile heißen "*_farbe" und werden in der Haarfarbe eingefärbt.
const BAERTE := [
	{"id": "ohne", "name": "CREATOR_BART_OHNE", "szene": null, "farbe": Color.WHITE},
	{"id": "schnauzer", "name": "CREATOR_BART_SCHNAUZER", "szene": "res://scenes/creator/baerte/schnauzer.tscn", "g": "m", "farbe": Color(0.35, 0.22, 0.12)},
	{"id": "walross", "name": "CREATOR_BART_WALROSS", "szene": "res://scenes/creator/baerte/walross.tscn", "g": "m", "farbe": Color(0.45, 0.30, 0.18)},
	{"id": "fumanchu", "name": "CREATOR_BART_FUMANCHU", "szene": "res://scenes/creator/baerte/fumanchu.tscn", "g": "m", "farbe": Color(0.12, 0.09, 0.07)},
	{"id": "kinnbart", "name": "CREATOR_BART_KINN", "szene": "res://scenes/creator/baerte/kinnbart.tscn", "g": "m", "farbe": Color(0.30, 0.18, 0.10)},
	{"id": "backenbart", "name": "CREATOR_BART_BACKEN", "szene": "res://scenes/creator/baerte/backenbart.tscn", "g": "m", "farbe": Color(0.55, 0.55, 0.57)},
	{"id": "vollbart", "name": "CREATOR_BART_VOLL", "szene": "res://scenes/creator/baerte/vollbart.tscn", "g": "m", "farbe": Color(0.38, 0.24, 0.14)},
	{"id": "stoppeln", "name": "CREATOR_BART_STOPPELN", "szene": "res://scenes/creator/baerte/stoppeln.tscn", "g": "m", "farbe": Color(0.20, 0.15, 0.12)},
	{"id": "zotteln", "name": "CREATOR_BART_ZOTTELN", "szene": "res://scenes/creator/baerte/zotteln.tscn", "g": "m", "farbe": Color(0.93, 0.93, 0.94)},
	{"id": "kinnband", "name": "CREATOR_BART_KINNBAND", "szene": "res://scenes/creator/baerte/kinnband.tscn", "g": "m", "farbe": Color(0.12, 0.09, 0.07)},
	{"id": "hufeisen", "name": "CREATOR_BART_HUFEISEN", "szene": "res://scenes/creator/baerte/hufeisen.tscn", "g": "m", "farbe": Color(0.25, 0.20, 0.15)},
]

## Frisuren (nur Frauen; Männer haben keine). Sie werden in der Haarfarbe eingefärbt, Haargummis behalten ihre Farbe.
## "g" in einem Eintrag beschränkt ihn auf ein Geschlecht ("m" / "w"); ohne "g" gilt er für beide.
const FRISUREN := [
	{"id": "ohne", "name": "CREATOR_FRISUR_OHNE", "szene": null, "farbe": Color.WHITE},
	{"id": "bob", "name": "CREATOR_FRISUR_BOB", "szene": "res://scenes/creator/frisuren/bob.tscn", "g": "w"},
	{"id": "lang", "name": "CREATOR_FRISUR_LANG", "szene": "res://scenes/creator/frisuren/lang.tscn", "g": "w"},
	{"id": "zoepfe", "name": "CREATOR_FRISUR_ZOEPFE", "szene": "res://scenes/creator/frisuren/zoepfe.tscn", "g": "w"},
	{"id": "dutt", "name": "CREATOR_FRISUR_DUTT", "szene": "res://scenes/creator/frisuren/dutt.tscn", "g": "w"},
	{"id": "pferdeschwanz", "name": "CREATOR_FRISUR_PFERDESCHWANZ", "szene": "res://scenes/creator/frisuren/pferdeschwanz.tscn", "g": "w"},
	{"id": "kurz", "name": "CREATOR_FRISUR_KURZ", "szene": "res://scenes/creator/frisuren/kurz.tscn", "g": "w"},
]

## Dirndl: Frauen tragen nur Kleider. Ein Dirndl besteht aus drei Schichten, die im Look als hemd (Bluse),
## hose (Kleid mit Rock) und jacke (Schürze) stehen. Jeder Eintrag nennt die drei Stücke.
## "farben": je Schicht [Stoff, Muster] statt der Standardfarben des Stücks.
const DIRNDLE := [
	{"id": "klassisch_kurz", "name": "CREATOR_DIRNDL_KLASSISCH_KURZ", "hemd": "bluse", "hose": "kleid_kurz", "jacke": "schuerze_kurz"},
	{"id": "klassisch_lang", "name": "CREATOR_DIRNDL_KLASSISCH_LANG", "hemd": "bluse", "hose": "kleid_lang", "jacke": "schuerze_lang",
		"farben": {"hose": [Color(0.40, 0.20, 0.55), Color(0.90, 0.80, 0.55)], "jacke": [Color(0.93, 0.90, 0.96), Color(0.40, 0.20, 0.55)]}},
	{"id": "tracht", "name": "CREATOR_DIRNDL_TRACHT", "hemd": "bluse_lang", "hose": "kleid_tracht", "jacke": "schuerze_tracht"},
	{"id": "landhaus", "name": "CREATOR_DIRNDL_LANDHAUS", "hemd": "bluse_kurz", "hose": "kleid_land", "jacke": "ohne"},
]

## Die ersten so viele Haarfarben sind natürlich (Zufall bei Männern nimmt nur diese)
const HAARFARBEN_NATUERLICH := 12
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
	Color(0.98, 0.93, 0.70),   # platinblond
	Color(0.70, 0.62, 0.48),   # aschblond
	Color(0.55, 0.30, 0.17),   # hellbraun
	Color(0.28, 0.14, 0.09),   # kastanie
	Color(0.45, 0.12, 0.14),   # burgunder
	Color(0.07, 0.08, 0.14),   # blauschwarz
	Color(0.95, 0.45, 0.65),   # pink
	Color(0.30, 0.50, 0.90),   # blau
	Color(0.30, 0.70, 0.45),   # grün
	Color(0.60, 0.38, 0.80),   # lila
	Color(0.20, 0.72, 0.75),   # türkis
]

## Szene eines Eintrags laden (null bei "ohne")
static func laden(e: Dictionary) -> PackedScene:
	var pfad: Variant = e.get("szene")
	return load(str(pfad)) as PackedScene if pfad != null else null

## Hemden, Jacken und Hosen: drei Schichten, die sich beliebig kombinieren lassen (Abstände in
## tools/blender/kleidung.py). Anders als Hüte & Co. hängen sie am Skelett des Körpers: Look.kleiden()
## holt das Netz aus der Szene und hängt es an das Skelett der Figur. Zwei Farben je Stück: "farbe"
## (Stoff) und "muster" (Besatz, Karo, Stickerei).
const HEMDEN := [
	{"id": "ohne", "name": "CREATOR_HEMD_OHNE", "szene": null, "farbe": Color.WHITE, "muster": Color.WHITE},
	{"id": "hemd_karo", "name": "CREATOR_HEMD_KARO", "szene": "res://scenes/creator/kleidung/hemd_karo.tscn", "farbe": Color(0.95, 0.95, 0.92), "muster": Color(0.16, 0.42, 0.26)},
	{"id": "hemd_karo_kurz", "name": "CREATOR_HEMD_KARO_KURZ", "szene": "res://scenes/creator/kleidung/hemd_karo_kurz.tscn", "farbe": Color(0.95, 0.95, 0.92), "muster": Color(0.75, 0.15, 0.15)},
	{"id": "bluse", "name": "CREATOR_BLUSE", "szene": "res://scenes/creator/kleidung/bluse.tscn", "g": "w", "tiefe_skala": 1.75, "farbe": Color(0.97, 0.96, 0.93), "muster": Color(0.90, 0.86, 0.78)},
	{"id": "bluse_lang", "name": "CREATOR_BLUSE_LANG", "szene": "res://scenes/creator/kleidung/bluse_lang.tscn", "g": "w", "tiefe_skala": 1.75, "farbe": Color(0.97, 0.96, 0.93), "muster": Color(0.85, 0.80, 0.70)},
	{"id": "bluse_kurz", "name": "CREATOR_BLUSE_KURZ", "szene": "res://scenes/creator/kleidung/bluse_kurz.tscn", "g": "w", "tiefe_skala": 1.75, "farbe": Color(0.98, 0.96, 0.90), "muster": Color(0.90, 0.60, 0.65)},
	{"id": "hemd_leinen", "name": "CREATOR_HEMD_LEINEN", "szene": "res://scenes/creator/kleidung/hemd_leinen.tscn", "farbe": Color(0.93, 0.90, 0.82), "muster": Color(0.80, 0.74, 0.60)},
]
## Schuhe: hängen wie die Kleidung am Skelett. Hauptfarbe = Leder/Stoff, Zweitfarbe = Schnürung, Riemen, Kappe, Kragen
## (Sohle und Socken haben Festfarben). Frauenschuhe ("g": "w") gibt es nur bei Frauen, alle anderen bei beiden.
const SCHUHE := [
	{"id": "ohne", "name": "CREATOR_SCHUH_OHNE", "szene": null, "farbe": Color.WHITE, "muster": Color.WHITE},
	{"id": "schuh_halb", "name": "CREATOR_SCHUH_HALB", "szene": "res://scenes/creator/kleidung/schuh_halb.tscn", "farbe": Color(0.16, 0.11, 0.08), "muster": Color(0.30, 0.22, 0.16)},
	{"id": "schuh_haferl", "name": "CREATOR_SCHUH_HAFERL", "szene": "res://scenes/creator/kleidung/schuh_haferl.tscn", "farbe": Color(0.38, 0.24, 0.14), "muster": Color(0.20, 0.12, 0.07)},
	{"id": "schuh_sneaker", "name": "CREATOR_SCHUH_SNEAKER", "szene": "res://scenes/creator/kleidung/schuh_sneaker.tscn", "farbe": Color(0.92, 0.92, 0.90), "muster": Color(0.20, 0.35, 0.65)},
	{"id": "schuh_stiefel", "name": "CREATOR_SCHUH_STIEFEL", "szene": "res://scenes/creator/kleidung/schuh_stiefel.tscn", "farbe": Color(0.10, 0.10, 0.11), "muster": Color(0.22, 0.22, 0.24)},
	{"id": "schuh_clog", "name": "CREATOR_SCHUH_CLOG", "szene": "res://scenes/creator/kleidung/schuh_clog.tscn", "farbe": Color(0.96, 0.96, 0.94), "muster": Color(0.70, 0.74, 0.80)},
	{"id": "schuh_ballerina", "name": "CREATOR_SCHUH_BALLERINA", "szene": "res://scenes/creator/kleidung/schuh_ballerina.tscn", "g": "w", "farbe": Color(0.12, 0.10, 0.10), "muster": Color(0.85, 0.75, 0.55)},
	{"id": "schuh_spangen", "name": "CREATOR_SCHUH_SPANGEN", "szene": "res://scenes/creator/kleidung/schuh_spangen.tscn", "g": "w", "farbe": Color(0.30, 0.12, 0.14), "muster": Color(0.85, 0.75, 0.55)},
]
const JACKEN := [
	{"id": "ohne", "name": "CREATOR_JACKE_OHNE", "szene": null, "farbe": Color.WHITE, "muster": Color.WHITE},
	{"id": "jacke_janker", "name": "CREATOR_JACKE_JANKER", "szene": "res://scenes/creator/kleidung/jacke_janker.tscn", "farbe": Color(0.46, 0.47, 0.49), "muster": Color(0.06, 0.30, 0.16)},
	{"id": "schuerze_kurz", "name": "CREATOR_SCHUERZE", "szene": "res://scenes/creator/kleidung/schuerze_kurz.tscn", "g": "w", "farbe": Color(0.97, 0.96, 0.94), "muster": Color(0.20, 0.35, 0.70)},
	{"id": "schuerze_lang", "name": "CREATOR_SCHUERZE", "szene": "res://scenes/creator/kleidung/schuerze_lang.tscn", "g": "w", "farbe": Color(0.97, 0.96, 0.94), "muster": Color(0.20, 0.35, 0.70)},
	{"id": "schuerze_tracht", "name": "CREATOR_SCHUERZE", "szene": "res://scenes/creator/kleidung/schuerze_tracht.tscn", "g": "w", "farbe": Color(0.15, 0.30, 0.22), "muster": Color(0.90, 0.80, 0.50)},
	{"id": "jacke_kochjacke", "name": "CREATOR_JACKE_KOCH", "szene": "res://scenes/creator/kleidung/jacke_kochjacke.tscn", "farbe": Color(0.96, 0.96, 0.94), "muster": Color(0.20, 0.30, 0.55)},
	{"id": "jacke_warnweste", "name": "CREATOR_JACKE_WARNWESTE", "szene": "res://scenes/creator/kleidung/jacke_warnweste.tscn", "farbe": Color(0.95, 0.80, 0.08), "muster": Color(0.85, 0.87, 0.88)},
	{"id": "schuerze_arbeit", "name": "CREATOR_SCHUERZE_ARBEIT", "szene": "res://scenes/creator/kleidung/schuerze_arbeit.tscn", "farbe": Color(0.30, 0.22, 0.14), "muster": Color(0.15, 0.10, 0.07)},
	{"id": "jacke_weste", "name": "CREATOR_JACKE_WESTE", "szene": "res://scenes/creator/kleidung/jacke_weste.tscn", "farbe": Color(0.14, 0.24, 0.34), "muster": Color(0.86, 0.78, 0.58)},
]
const HOSEN := [
	{"id": "ohne", "name": "CREATOR_HOSE_OHNE", "szene": null, "farbe": Color.WHITE, "muster": Color.WHITE},
	{"id": "hose_leder", "name": "CREATOR_HOSE_LEDER", "szene": "res://scenes/creator/kleidung/hose_leder.tscn", "farbe": Color(0.24, 0.16, 0.10), "muster": Color(0.74, 0.64, 0.44)},
	{"id": "kleid_kurz", "name": "CREATOR_KLEID", "szene": "res://scenes/creator/kleidung/kleid_kurz.tscn", "g": "w", "farbe": Color(0.15, 0.28, 0.65), "muster": Color(0.90, 0.85, 0.70)},
	{"id": "kleid_lang", "name": "CREATOR_KLEID", "szene": "res://scenes/creator/kleidung/kleid_lang.tscn", "g": "w", "farbe": Color(0.15, 0.28, 0.65), "muster": Color(0.90, 0.85, 0.70)},
	{"id": "kleid_tracht", "name": "CREATOR_KLEID", "szene": "res://scenes/creator/kleidung/kleid_tracht.tscn", "g": "w", "farbe": Color(0.45, 0.10, 0.16), "muster": Color(0.90, 0.80, 0.50)},
	{"id": "kleid_land", "name": "CREATOR_KLEID", "szene": "res://scenes/creator/kleidung/kleid_land.tscn", "g": "w", "farbe": Color(0.85, 0.35, 0.40), "muster": Color(0.97, 0.90, 0.80)},
	{"id": "hose_kniebund", "name": "CREATOR_HOSE_KNIEBUND", "szene": "res://scenes/creator/kleidung/hose_kniebund.tscn", "farbe": Color(0.30, 0.22, 0.14), "muster": Color(0.74, 0.64, 0.44)},
]

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
			if k.emission_enabled:
				k.emission = farbe
			mi.set_surface_override_material(s, k)
