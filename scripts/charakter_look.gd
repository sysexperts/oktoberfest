extends RefCounted
## Der selbst gebaute Charakter: Basiskörper (scenes/figuren/basis.tscn) plus Bausteine aus
## scripts/creator_assets.gd (Augen, Gesichtsausdruck, Bart, Hut, Brille) und Farben.
## Ein Look ist ein Dictionary, im Netz als kurzer JSON-Text unterwegs (zu_code / aus_code).
## Gespeichert wird er in user://charakter.cfg. Ohne class_name (neue Klassennamen brauchen auf dem
## Server eine Neuindizierung), per preload einbinden.
##
## Ablauf: bauen(look) → Figur (Bausteine hängen am Kopfknochen); nach dem Einhängen in den Baum
## einmal faerben(figur, look) (Haut, Hut-, Brillen-, Haarfarbe).

const Assets := preload("res://scripts/creator_assets.gd")
const BASIS := preload("res://scenes/figuren/basis.tscn")
const DATEI := "user://charakter.cfg"
const MAX_CODE := 400

## Hauttöne zur Auswahl (so sieht die Haut aus). Die Hauttextur hat den Ton BASIS_HAUT; gefärbt wird mit
## dem Verhältnis der gewählten Farbe dazu.
const HAUTFARBEN := [
	Color(0.93, 0.74, 0.62), Color(0.80, 0.58, 0.45), Color(0.66, 0.43, 0.32),
	Color(0.52, 0.34, 0.25), Color(0.40, 0.26, 0.19), Color(0.28, 0.19, 0.14),
]
const BASIS_HAUT := Color(0.66, 0.43, 0.32)

## Reihenfolge, in der die Bausteine am Kopf hängen — danach richtet sich auch das Einfärben
const ARTEN := ["augen", "emotion", "bart", "hut", "brille"]

static func standard() -> Dictionary:
	return {
		"geschlecht": "m",
		"haut": HAUTFARBEN[2].to_html(false),
		"augen": "gross",
		"emotion": "freundlich",
		"bart": "ohne",
		"hut": "ohne",
		"brille": "ohne",
		"haar": Assets.HAARFARBEN[2].to_html(false),
		"hut_farbe": Assets.HUETE[1]["farbe"].to_html(false),
		"brille_farbe": Assets.BRILLEN[1]["farbe"].to_html(false),
	}

static func liste(art: String) -> Array:
	match art:
		"augen": return Assets.AUGEN
		"emotion": return Assets.EMOTIONEN
		"bart": return Assets.BAERTE
		"hut": return Assets.HUETE
		"brille": return Assets.BRILLEN
	return []

static func _eintrag(art: String, id: String) -> Dictionary:
	for e: Dictionary in liste(art):
		if e["id"] == id:
			return e
	return liste(art)[0]

## Unbekanntes und Kaputtes durch Standardwerte ersetzen (Netz- und Dateidaten sind nicht vertrauenswürdig)
static func pruefen(roh: Dictionary) -> Dictionary:
	var l := standard()
	for art: String in ARTEN:
		var id := str(roh.get(art, l[art]))
		l[art] = _eintrag(art, id)["id"]
	for schluessel: String in ["haut", "haar", "hut_farbe", "brille_farbe"]:
		var t := str(roh.get(schluessel, l[schluessel]))
		if t.length() <= 8 and Color.html_is_valid(t):
			l[schluessel] = t
	l["geschlecht"] = "m"
	return l

static func zu_code(l: Dictionary) -> String:
	return JSON.stringify(l)

static func aus_code(code: String) -> Dictionary:
	if code.length() > MAX_CODE:
		return standard()
	# JSON.new().parse statt JSON.parse_string: kaputte Netz-Daten sollen nichts ins Log schreiben
	var json := JSON.new()
	if json.parse(code) != OK or not json.data is Dictionary:
		return standard()
	return pruefen(json.data)

static func gespeichert() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(DATEI) == OK and cfg.has_section_key("look", "code")

static func laden() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(DATEI) == OK:
		return aus_code(str(cfg.get_value("look", "code", "")))
	return standard()

static func speichern(l: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.load(DATEI)
	cfg.set_value("look", "code", zu_code(l))
	cfg.save(DATEI)

static func zufall() -> Dictionary:
	var l := standard()
	for art: String in ARTEN:
		var eintraege := liste(art)
		l[art] = eintraege[randi() % eintraege.size()]["id"]
	l["haut"] = HAUTFARBEN[randi() % HAUTFARBEN.size()].to_html(false)
	l["haar"] = Assets.HAARFARBEN[randi() % Assets.HAARFARBEN.size()].to_html(false)
	l["hut_farbe"] = Color.from_hsv(randf(), randf_range(0.3, 0.8), randf_range(0.35, 0.9)).to_html(false)
	l["brille_farbe"] = Color.from_hsv(randf(), randf_range(0.0, 0.8), randf_range(0.2, 0.9)).to_html(false)
	return l

## Figur aus dem Basiskörper mit allen gewählten Bausteinen. Die Farben folgen in faerben(),
## sobald die Figur im Baum hängt (erst dann gibt es die Materialien).
static func bauen(l: Dictionary) -> Figur:
	var f := BASIS.instantiate() as Figur
	var z: Array[PackedScene] = []
	for art: String in ARTEN:
		var e := _eintrag(art, str(l.get(art, "ohne")))
		if e["szene"] != null:
			z.append(Assets.laden(e))
	f.zubehoer = z
	return f

static func faerben(f: Figur, l: Dictionary) -> void:
	var haut_wahl := Color.html(str(l.get("haut", BASIS_HAUT.to_html(false))))
	var haut := Color(minf(haut_wahl.r / BASIS_HAUT.r, 1.8), minf(haut_wahl.g / BASIS_HAUT.g, 1.8), minf(haut_wahl.b / BASIS_HAUT.b, 1.8))
	var haar := Color.html(str(l.get("haar", "5a3a24")))
	# Haut: Körper und Hände mit dem Hautton einfärben (eigene Materialkopie je Netz)
	if f.skelett:
		for mi: MeshInstance3D in f.skelett.find_children("*", "MeshInstance3D", false, false):
			if mi.name in ["Koerper", "HandLeft", "HandRight"]:
				_tonen(mi, haut)
	var halter := f.skelett.get_node_or_null("Zubehoer") if f.skelett else null
	if halter == null:
		return
	# Die Teile hängen in der Reihenfolge von ARTEN am Kopf (nur die gewählten, nicht "ohne")
	var teile := halter.get_children()
	var i := 0
	for art: String in ARTEN:
		if _eintrag(art, str(l.get(art, "ohne")))["szene"] == null:
			continue
		if i >= teile.size():
			break
		var teil := teile[i]
		i += 1
		match art:
			"hut": Assets.faerben(teil, Color.html(str(l.get("hut_farbe", "ffffff"))))
			"brille": Assets.faerben(teil, Color.html(str(l.get("brille_farbe", "ffffff"))))
			"bart", "emotion": Assets.faerben(teil, haar)
			"augen": Assets.faerben(teil, haut_wahl, "*_haut*")

static func _tonen(mi: MeshInstance3D, farbe: Color) -> void:
	for s in mi.mesh.get_surface_count():
		var m := mi.get_active_material(s) as BaseMaterial3D
		if m == null:
			continue
		var k := m.duplicate() as BaseMaterial3D
		k.albedo_color = farbe
		if k.emission_enabled:
			k.emission = farbe
		mi.set_surface_override_material(s, k)
