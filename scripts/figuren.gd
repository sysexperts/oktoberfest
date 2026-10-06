extends RefCounted
## Alle NPC-Figuren und wer welche bekommt.
## Neue Figur: Szene unter scenes/figuren/ anlegen (siehe scripts/figur.gd) und
## hier in ALLE eintragen — Besucher, Gäste, Personal und Künstler wählen daraus.
## Ohne class_name (neue Klassennamen brauchen auf dem Server eine Neuindizierung),
## einbinden per preload.
const Look := preload("res://scripts/charakter_look.gd")
const Assets := preload("res://scripts/creator_assets.gd")

const ALLE: Array[PackedScene] = [
	preload("res://scenes/figuren/bean.tscn"),
	preload("res://scenes/figuren/charakter2.tscn"),
	preload("res://scenes/figuren/charakter3.tscn"),
	preload("res://scenes/figuren/alex.tscn"),
	# Varianten: andere Kleidung, Hut, Bart, Brille
	preload("res://scenes/figuren/wilhelm_hut_bart.tscn"),
	preload("res://scenes/figuren/wilhelm_schwarz.tscn"),
	preload("res://scenes/figuren/wilhelm_brille_bart.tscn"),
	preload("res://scenes/figuren/alex_rot_brille.tscn"),
	preload("res://scenes/figuren/alex_gruen_sonnenbrille.tscn"),
	preload("res://scenes/figuren/alex_grau_hut.tscn"),
	# Weitere Frauen: Lisa mit anderem Dirndl (Farbe per tools/bake_kleidung.gd)
	preload("res://scenes/figuren/lisa_blau.tscn"),
	preload("res://scenes/figuren/lisa_gruen.tscn"),
	preload("res://scenes/figuren/lisa_lila.tscn"),
	# Gleicher Körper und gleiches Skelett wie Bean (tools/blender/standardkoerper.py, OUTFIT=franz)
	preload("res://scenes/figuren/franz.tscn"),
]
## Figuren, die auf der Bank sitzen. Lisa (charakter3) sitzt mit einer
## Sitzkorrektur gegen den Rock (assets/sitz_lisa.tres, scenes/werkzeuge/sitz_haltung.tscn).
const GAESTE: Array[PackedScene] = [
	preload("res://scenes/figuren/bean.tscn"),
	preload("res://scenes/figuren/charakter2.tscn"),
	preload("res://scenes/figuren/charakter3.tscn"),
	preload("res://scenes/figuren/alex.tscn"),
	# Varianten: andere Kleidung, Hut, Bart, Brille
	preload("res://scenes/figuren/wilhelm_hut_bart.tscn"),
	preload("res://scenes/figuren/wilhelm_schwarz.tscn"),
	preload("res://scenes/figuren/wilhelm_brille_bart.tscn"),
	preload("res://scenes/figuren/alex_rot_brille.tscn"),
	preload("res://scenes/figuren/alex_gruen_sonnenbrille.tscn"),
	preload("res://scenes/figuren/alex_grau_hut.tscn"),
	# Weitere Frauen: Lisa mit anderem Dirndl (Farbe per tools/bake_kleidung.gd)
	preload("res://scenes/figuren/lisa_blau.tscn"),
	preload("res://scenes/figuren/lisa_gruen.tscn"),
	preload("res://scenes/figuren/lisa_lila.tscn"),
	preload("res://scenes/figuren/franz.tscn"),
]
## Stehende Gäste: stehen hinter der Bank am Tisch statt zu sitzen, bestellen,
## trinken und tanzen sonst wie alle.
const STEHGAESTE: Array[PackedScene] = [
	preload("res://scenes/figuren/charakter3.tscn"),
]
## Steht dieser Gast? Etwa jeder dritte. Aus der ID, damit Server (Platz hinter
## der Bank) und alle Mitspieler (Figur, kein Hinsetzen) dasselbe entscheiden.
static func ist_stehgast(id: int) -> bool:
	return posmod(id * 5 + 1, 3) == 0
## Gäste: Stehgäste aus STEHGAESTE, alle anderen sitzen und kommen aus GAESTE.
static func fuer_gast(id: int) -> PackedScene:
	if ist_stehgast(id):
		return STEHGAESTE[posmod(int(id / 3), STEHGAESTE.size())]
	# Sitzende Gäste lückenlos durchzählen (Stehgäste sind die IDs mit id % 3 == 1),
	# damit jede Figur in GAESTE drankommt, egal wie viele es sind
	return GAESTE[posmod(id - int((id + 1) / 3), GAESTE.size())]
## Gäste, Personal, Künstler: aus der ID — so sieht jeder Mitspieler dieselbe Figur,
## ohne dass die Wahl übers Netz geschickt werden muss.
static func fuer_id(id: int) -> PackedScene:
	# Streuen, damit aufeinanderfolgende IDs nicht streng abwechseln
	return ALLE[posmod(id * 5 + 3, ALLE.size())]
## Besucher draußen laufen nur lokal — dort reicht Zufall.
static func zufaellig() -> PackedScene:
	return ALLE.pick_random()
## Ersetzt den Knoten "Model" von besitzer durch die gewählte Figur, mit gleicher
## Lage und gleichem Platz in der Szene. Gibt die Figur zurück.
static func einsetzen(besitzer: Node3D, szene: PackedScene) -> Figur:
	var alt := besitzer.get_node("Model") as Node3D
	if alt.scene_file_path == szene.resource_path and alt is Figur:
		return alt as Figur
	var neu := szene.instantiate() as Figur
	neu.transform = alt.transform
	var platz := alt.get_index()
	alt.name = "ModelAlt"
	besitzer.remove_child(alt)
	alt.queue_free()
	neu.name = "Model"
	besitzer.add_child(neu)
	besitzer.move_child(neu, platz)
	return neu

## Wie einsetzen(), aber mit einer fertig gebauten Figur (selbst erstellter Charakter, scripts/charakter_look.gd)
static func einsetzen_figur(besitzer: Node3D, neu: Figur) -> Figur:
	var alt := besitzer.get_node("Model") as Node3D
	neu.transform = alt.transform
	var platz := alt.get_index()
	alt.name = "ModelAlt"
	besitzer.remove_child(alt)
	alt.queue_free()
	neu.name = "Model"
	besitzer.add_child(neu)
	besitzer.move_child(neu, platz)
	return neu


# --------------------------------------------------------------------- Zufalls-NPCs aus dem Creator
## Gäste, Personal und Besucher sind keine festen Figuren mehr, sondern werden aus der ID zusammengewürfelt (gleiche ID = gleiche
## Figur, damit im Koop jeder dasselbe sieht): Mann oder Frau, Frisur, Bart, Hut, Brille, Tracht in gedeckten Farben.
## Regeln: nie nackt (Männer: Hemd und Hose, Frauen: immer ein Dirndl), keine grellen Farben, nur natürliche Haarfarben.
## Die Hauptfiguren der Geschichte (Huber, Festleiter, Budenbesitzer, Stammgäste) bleiben eigene Figuren.
const NPC_AUGEN := {
	"m": ["gross", "klein", "oval_hoch", "oval_breit", "muede", "grosse_pupillen"],
	"w": ["gross_w", "klein_w", "oval_hoch_w", "muede_w", "grosse_pupillen_w"],
}
const NPC_AUSDRUECKE := ["freundlich", "freundlich", "froehlich", "skeptisch", "genervt"]
const NPC_HUETE_M := ["filzhut", "tirolerhut", "tirolerhut", "schiebermuetze", "strohhut"]
const NPC_HUETE_W := ["tirolerhut", "filzhut"]
const NPC_BRILLEN := ["rund", "eckig", "lesebrille", "oval"]
const NPC_HEMDEN := ["hemd_karo", "hemd_karo_kurz", "hemd_leinen"]
const NPC_JACKEN := ["jacke_janker", "jacke_weste"]
const NPC_HOSEN := ["hose_leder", "hose_kniebund"]
## Farbtöne für Karo, Besatz und Kleider (HSV-Farbton 0..1): Rot, Grün, Blaugrau, Braun, Blaugrün, Weinrot, Senf
const NPC_TOENE := [0.99, 0.33, 0.58, 0.08, 0.46, 0.93, 0.13]

## Gedeckte Farbe: wenig Sättigung, mittlere Helligkeit
static func _gedeckt(rng: RandomNumberGenerator, ton: float, s_von := 0.28, s_bis := 0.5, v_von := 0.32, v_bis := 0.6) -> Color:
	return Color.from_hsv(ton, rng.randf_range(s_von, s_bis), rng.randf_range(v_von, v_bis))

static func _wahl(rng: RandomNumberGenerator, liste: Array) -> Variant:
	return liste[rng.randi() % liste.size()]

static func npc_look(id: int, salz := 0, geschlecht := "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("npc|%d|%d" % [id, salz])
	var g := "w" if rng.randf() < 0.5 else "m"
	if geschlecht != "":
		g = geschlecht
	var l := Look.standard(g)
	# Hautton: überwiegend die mittleren Töne, selten ganz hell oder ganz dunkel
	var hw := rng.randf()
	var hi := 0 if hw < 0.12 else (1 if hw < 0.4 else (2 if hw < 0.68 else (3 if hw < 0.86 else (4 if hw < 0.96 else 5))))
	l["haut"] = Look.HAUTFARBEN[hi].to_html(false)
	l["haar"] = Assets.HAARFARBEN[rng.randi() % Assets.HAARFARBEN_NATUERLICH].to_html(false)
	l["augen"] = _wahl(rng, NPC_AUGEN[g])
	l["emotion"] = str(_wahl(rng, NPC_AUSDRUECKE)) + ("_w" if g == "w" else "")
	if rng.randf() < 0.14:
		l["brille"] = _wahl(rng, NPC_BRILLEN)
		l["brille_farbe"] = _gedeckt(rng, _wahl(rng, [0.08, 0.1, 0.6, 0.0]), 0.0, 0.35, 0.12, 0.4).to_html(false)
	if g == "m":
		if rng.randf() < 0.33:
			var baerte := Look.liste("bart", "m").filter(func(e: Dictionary) -> bool: return e["id"] != "ohne")
			l["bart"] = (_wahl(rng, baerte) as Dictionary)["id"]
		if rng.randf() < 0.3:
			l["hut"] = _wahl(rng, NPC_HUETE_M)
			l["hut_farbe"] = _gedeckt(rng, _wahl(rng, [0.08, 0.28, 0.0, 0.58]), 0.05, 0.4, 0.2, 0.45).to_html(false)
		_maenner_tracht(rng, l)
	else:
		var frisuren := Look.liste("frisur", "w").filter(func(e: Dictionary) -> bool: return e["id"] != "ohne")
		l["frisur"] = (_wahl(rng, frisuren) as Dictionary)["id"]
		if rng.randf() < 0.18:
			l["hut"] = _wahl(rng, NPC_HUETE_W)
			l["hut_farbe"] = _gedeckt(rng, _wahl(rng, [0.08, 0.28, 0.58]), 0.05, 0.4, 0.25, 0.5).to_html(false)
		_dirndl_waehlen(rng, l)
	_schuhe_waehlen(rng, l, g)
	return Look.pruefen(l)

## Schuhe: Männer Haferl, Halbschuhe, Turnschuhe oder Stiefel; Frauen Ballerinas, Spangenschuhe oder Haferl. Dunkle, gedeckte Farben.
static func _schuhe_waehlen(rng: RandomNumberGenerator, l: Dictionary, g: String) -> void:
	var wahl: String
	var r := rng.randf()
	if g == "m":
		wahl = "schuh_haferl" if r < 0.4 else ("schuh_halb" if r < 0.75 else ("schuh_sneaker" if r < 0.9 else "schuh_stiefel"))
	else:
		wahl = "schuh_ballerina" if r < 0.4 else ("schuh_spangen" if r < 0.8 else "schuh_haferl")
	Look._kleid_setzen(l, "schuhe", wahl)
	if wahl != "schuh_sneaker":
		l["schuhe_farbe"] = Color.from_hsv(0.07, rng.randf_range(0.3, 0.7), rng.randf_range(0.14, 0.36)).to_html(false)
		l["schuhe_muster"] = Color.from_hsv(0.08, rng.randf_range(0.2, 0.5), rng.randf_range(0.2, 0.42)).to_html(false)

static func _maenner_tracht(rng: RandomNumberGenerator, l: Dictionary) -> void:
	# Hemd und Hose immer, die Jacke meist
	Look._kleid_setzen(l, "hemd", str(_wahl(rng, NPC_HEMDEN)))
	l["hemd_farbe"] = Color.from_hsv(0.1, rng.randf_range(0.02, 0.1), rng.randf_range(0.88, 0.97)).to_html(false)
	l["hemd_muster"] = _gedeckt(rng, _wahl(rng, NPC_TOENE), 0.3, 0.55, 0.36, 0.6).to_html(false)
	if rng.randf() < 0.78:
		Look._kleid_setzen(l, "jacke", str(_wahl(rng, NPC_JACKEN)))
		var farbe: Color
		match rng.randi() % 4:
			0: farbe = Color.from_hsv(0.0, 0.0, rng.randf_range(0.42, 0.6))                          # Grau
			1: farbe = _gedeckt(rng, rng.randf_range(0.27, 0.36), 0.25, 0.4, 0.3, 0.45)              # Loden
			2: farbe = _gedeckt(rng, 0.07, 0.35, 0.5, 0.25, 0.42)                                    # Braun
			_: farbe = _gedeckt(rng, 0.6, 0.3, 0.5, 0.22, 0.38)                                      # Dunkelblau
		l["jacke_farbe"] = farbe.to_html(false)
		l["jacke_muster"] = _gedeckt(rng, rng.randf_range(0.28, 0.4), 0.5, 0.7, 0.2, 0.32).to_html(false)
	else:
		l["jacke"] = "ohne"
	Look._kleid_setzen(l, "hose", str(_wahl(rng, NPC_HOSEN)))
	var hose: Color = Color.from_hsv(0.07, rng.randf_range(0.45, 0.65), rng.randf_range(0.15, 0.28)) if rng.randf() < 0.8 else Color.from_hsv(0.0, 0.0, rng.randf_range(0.12, 0.2))
	l["hose_farbe"] = hose.to_html(false)
	l["hose_muster"] = Color.from_hsv(0.12, rng.randf_range(0.3, 0.45), rng.randf_range(0.6, 0.74)).to_html(false)

static func _dirndl_waehlen(rng: RandomNumberGenerator, l: Dictionary) -> void:
	Look.dirndl_setzen(l, _wahl(rng, Assets.DIRNDLE) as Dictionary)
	var ton: float = _wahl(rng, NPC_TOENE)
	var kleid := _gedeckt(rng, ton, 0.35, 0.58, 0.3, 0.55)
	# hose = Kleid, jacke = Schürze, hemd = Bluse (scripts/creator_assets.gd, DIRNDLE)
	l["hose_farbe"] = kleid.to_html(false)
	l["hose_muster"] = Color.from_hsv(0.12, rng.randf_range(0.2, 0.35), rng.randf_range(0.72, 0.86)).to_html(false)
	l["hemd_farbe"] = Color.from_hsv(0.1, rng.randf_range(0.02, 0.1), rng.randf_range(0.9, 0.98)).to_html(false)
	l["hemd_muster"] = Color.from_hsv(0.1, rng.randf_range(0.1, 0.2), rng.randf_range(0.8, 0.9)).to_html(false)
	if l["jacke"] != "ohne":
		l["jacke_farbe"] = Color.from_hsv(ton, rng.randf_range(0.04, 0.16), rng.randf_range(0.88, 0.96)).to_html(false)
		l["jacke_muster"] = kleid.to_html(false)

## Wie einsetzen(), aber mit einer aus der ID zusammengewürfelten Figur (npc_look)
static func einsetzen_npc(besitzer: Node3D, id: int, salz := 0) -> Figur:
	var l := npc_look(id, salz)
	var f := einsetzen_figur(besitzer, Look.bauen(l))
	Look.faerben(f, l)
	return f


## Benannte Stammgäste (GameManager.STAMMGAESTE): feste Figur je Name, Geschlecht passend zum Namen
const STAMM_GESCHLECHT := {"alois": "m", "vroni": "w", "kathi": "w", "franz": "m", "giulia": "w", "wiggerl": "m"}

static func einsetzen_stamm(besitzer: Node3D, name: String) -> Figur:
	var l := npc_look(hash(name), 7, str(STAMM_GESCHLECHT.get(name, "")))
	if name == "alois":
		# Opa Alois: weißer Backenbart unterm Filzhut (der Walross-Schnauzer gehört Horst)
		l["haar"] = Color.from_hsv(0.0, 0.0, 0.85).to_html(false)
		l["bart"] = "backenbart"
		l["hut"] = "filzhut"
		l["hut_farbe"] = Color(0.3, 0.27, 0.22).to_html(false)
	var f := einsetzen_figur(besitzer, Look.bauen(Look.pruefen(l)))
	Look.faerben(f, l)
	return f

## Eine feste Figur aus einem Look zusammenbauen (Huber, Festleiter)
static func einsetzen_look(besitzer: Node3D, roh: Dictionary) -> Figur:
	var l := Look.pruefen(roh)
	var f := einsetzen_figur(besitzer, Look.bauen(l))
	Look.faerben(f, l)
	return f

## Alois Huber, der Bösewicht: Zylinder, Monokel, gezwirbelter Bart, finsterer Blick, weinroter Janker
static func look_huber() -> Dictionary:
	var l := Look.standard("m")
	l["haut"] = Look.HAUTFARBEN[1].to_html(false)
	l["haar"] = Color.from_hsv(0.0, 0.0, 0.1).to_html(false)
	l["augen"] = "wuetend"
	l["emotion"] = "skeptisch"
	l["bart"] = "fumanchu"
	l["hut"] = "zylinder"
	l["hut_farbe"] = Color(0.09, 0.08, 0.09).to_html(false)
	l["brille"] = "monokel"
	l["brille_farbe"] = Color(0.75, 0.6, 0.2).to_html(false)
	Look._kleid_setzen(l, "hemd", "hemd_leinen")
	l["hemd_farbe"] = Color(0.93, 0.92, 0.9).to_html(false)
	l["hemd_muster"] = Color(0.8, 0.78, 0.76).to_html(false)
	Look._kleid_setzen(l, "jacke", "jacke_janker")
	l["jacke_farbe"] = Color(0.42, 0.06, 0.12).to_html(false)
	l["jacke_muster"] = Color(0.18, 0.03, 0.06).to_html(false)
	Look._kleid_setzen(l, "schuhe", "schuh_halb")
	l["schuhe_farbe"] = Color(0.05, 0.05, 0.06).to_html(false)
	l["schuhe_muster"] = Color(0.15, 0.15, 0.16).to_html(false)
	Look._kleid_setzen(l, "hose", "hose_kniebund")
	l["hose_farbe"] = Color(0.12, 0.11, 0.12).to_html(false)
	l["hose_muster"] = Color(0.3, 0.28, 0.28).to_html(false)
	return l

## Festbetreiber Horst: Glatze, grauer Walross-Schnauzer, blaue Weste, Lederhose (das Aussehen, das früher Opa Alois hatte)
static func look_festleiter() -> Dictionary:
	var l := npc_look(hash("alois"), 7, "m")
	l["haar"] = Color.from_hsv(0.0, 0.0, 0.78).to_html(false)
	l["bart"] = "walross"
	Look._kleid_setzen(l, "schuhe", "schuh_haferl")
	return l


# --------------------------------------------------------------------- Berufe
## Berufskleidung: Gesicht, Haare und Geschlecht kommen wie bei jedem Zufalls-NPC aus der ID, Kleidung und Hut richten sich
## nach dem Beruf. Berufe: koch, kellner, zapfer, reinigung, security, bude (Budenbesitzer), kuenstler
## Frauen und Männer tragen im selben Beruf dieselbe Kleidung (uniform), nur Gesicht und Frisur unterscheiden sich.
const BERUF_ROLLE := {1: "koch", 2: "kellner", 3: "reinigung", 4: "zapfer"}

static func _stueck(l: Dictionary, art: String, id: String, farbe: Color, muster: Color) -> void:
	l[art] = id
	l[art + "_farbe"] = farbe.to_html(false)
	l[art + "_muster"] = muster.to_html(false)

static func npc_look_beruf(id: int, beruf: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("beruf|%s|%d" % [beruf, id])
	var l := npc_look(id, 11 + beruf.length())
	var frau: bool = l["geschlecht"] == "w"
	match beruf:
		"kellner":
			_stueck(l, "schuhe", "schuh_halb", Color(0.08, 0.08, 0.09), Color(0.2, 0.2, 0.22))
			l["uniform"] = true
			if true:
				_stueck(l, "hemd", "hemd_leinen", Color(0.95, 0.94, 0.9), Color(0.82, 0.78, 0.66))
				_stueck(l, "jacke", "jacke_weste", Color(0.1, 0.1, 0.12), Color(0.8, 0.7, 0.4))
				_stueck(l, "hose", "hose_leder", Color(0.16, 0.11, 0.08), Color(0.6, 0.5, 0.35))
				l["hut"] = "ohne"
		"koch":
			_stueck(l, "schuhe", "schuh_clog", Color(0.96, 0.96, 0.94), Color(0.7, 0.74, 0.8))
			l["uniform"] = true
			_stueck(l, "hemd", "hemd_leinen", Color(0.95, 0.95, 0.93), Color(0.9, 0.9, 0.88))
			_stueck(l, "jacke", "jacke_kochjacke", Color(0.97, 0.97, 0.95), Color(0.2, 0.3, 0.55))
			_stueck(l, "hose", "hose_kniebund", Color(0.2, 0.2, 0.22), Color(0.35, 0.35, 0.38))
			l["hut"] = "kochmuetze"
			l["hut_farbe"] = Color(0.97, 0.97, 0.95).to_html(false)
			l["frisur"] = "ohne" if not frau else l["frisur"]
		"zapfer":
			_stueck(l, "schuhe", "schuh_haferl", Color(0.32, 0.2, 0.12), Color(0.18, 0.11, 0.07))
			l["uniform"] = true
			_stueck(l, "hemd", "hemd_karo_kurz", Color(0.95, 0.95, 0.92), Color(0.2, 0.4, 0.7))
			_stueck(l, "jacke", "schuerze_arbeit", Color(0.3, 0.2, 0.12), Color(0.15, 0.1, 0.07))
			_stueck(l, "hose", "hose_leder", Color(0.22, 0.15, 0.1), Color(0.7, 0.6, 0.42))
			l["hut"] = "ohne"
		"reinigung":
			_stueck(l, "schuhe", "schuh_stiefel", Color(0.16, 0.2, 0.26), Color(0.26, 0.3, 0.36))
			l["uniform"] = true
			_stueck(l, "hemd", "hemd_karo_kurz", Color(0.78, 0.82, 0.86), Color(0.78, 0.82, 0.86))
			_stueck(l, "jacke", "schuerze_arbeit", Color(0.22, 0.34, 0.5), Color(0.14, 0.22, 0.34))
			_stueck(l, "hose", "hose_kniebund", Color(0.3, 0.32, 0.36), Color(0.4, 0.42, 0.46))
			l["hut"] = "ohne"
		"security":
			_stueck(l, "schuhe", "schuh_stiefel", Color(0.07, 0.07, 0.08), Color(0.18, 0.18, 0.2))
			l["uniform"] = true
			l["geschlecht"] = l["geschlecht"]
			_stueck(l, "hemd", "hemd_karo_kurz", Color(0.1, 0.1, 0.11), Color(0.1, 0.1, 0.11))
			_stueck(l, "jacke", "jacke_warnweste", Color(0.95, 0.8, 0.08), Color(0.85, 0.87, 0.88))
			_stueck(l, "hose", "hose_kniebund", Color(0.1, 0.1, 0.12), Color(0.2, 0.2, 0.22))
			l["hut"] = "baseballcap"
			l["hut_farbe"] = Color(0.08, 0.08, 0.09).to_html(false)
			l["brille"] = "security_brille"
			l["brille_farbe"] = Color(0.08, 0.08, 0.09).to_html(false)
			l["emotion"] = "skeptisch" + ("_w" if frau else "")
			if not frau:
				l["bart"] = "stoppeln"
		"bude":
			l["uniform"] = true
			if true:
				_stueck(l, "hemd", "hemd_karo_kurz", Color(0.95, 0.93, 0.88), Color(0.7, 0.2, 0.18))
				_stueck(l, "jacke", "jacke_weste", Color(0.3, 0.22, 0.14), Color(0.8, 0.7, 0.45))
				_stueck(l, "hose", "hose_kniebund", Color(0.25, 0.2, 0.15), Color(0.7, 0.6, 0.4))
				l["hut"] = "strohhut" if rng.randf() < 0.5 else "schiebermuetze"
				l["hut_farbe"] = (Color(0.92, 0.8, 0.5) if l["hut"] == "strohhut" else Color(0.35, 0.3, 0.25)).to_html(false)
		"kuenstler":
			_stueck(l, "schuhe", "schuh_haferl", Color(0.3, 0.19, 0.11), Color(0.17, 0.1, 0.06))
			l["uniform"] = true
			if true:
				l["hut"] = "tirolerhut"
				l["hut_farbe"] = Color(0.3, 0.2, 0.13).to_html(false)
				_stueck(l, "jacke", "jacke_janker", Color(0.24, 0.38, 0.22), Color(0.12, 0.2, 0.1))
				_stueck(l, "hemd", "hemd_leinen", Color(0.95, 0.94, 0.9), Color(0.82, 0.78, 0.66))
				_stueck(l, "hose", "hose_leder", Color(0.2, 0.14, 0.09), Color(0.7, 0.6, 0.42))
	return l

static func einsetzen_beruf(besitzer: Node3D, id: int, beruf: String) -> Figur:
	var l := Look.pruefen(npc_look_beruf(id, beruf))
	var f := einsetzen_figur(besitzer, Look.bauen(l))
	Look.faerben(f, l)
	return f
