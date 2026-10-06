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
const MAX_CODE := 1000   # auch in scripts/game_manager.gd (net_look_setzen)

## Hauttöne zur Auswahl (so sieht die Haut aus). Die Hauttextur hat den Ton BASIS_HAUT; gefärbt wird mit
## dem Verhältnis der gewählten Farbe dazu.
const HAUTFARBEN := [
	Color(0.93, 0.74, 0.62), Color(0.80, 0.58, 0.45), Color(0.66, 0.43, 0.32),
	Color(0.52, 0.34, 0.25), Color(0.40, 0.26, 0.19), Color(0.28, 0.19, 0.14),
]
const BASIS_HAUT := Color(0.66, 0.43, 0.32)

const FARB_SCHLUESSEL := ["haut", "haar", "hut_farbe", "brille_farbe", "hemd_farbe", "hemd_muster", "jacke_farbe", "jacke_muster", "hose_farbe", "hose_muster", "schuhe_farbe", "schuhe_muster"]
const KLEIDUNG_SHADER := preload("res://assets/shader/kleidung.gdshader")

## Reihenfolge, in der die Bausteine am Kopf hängen — danach richtet sich auch das Einfärben
const ARTEN := ["augen", "emotion", "frisur", "bart", "hut", "brille"]
## Teile am Skelett statt am Kopf (Hemd, Jacke, Hose)
const KLEIDER := ["hemd", "jacke", "hose", "schuhe"]
## Hut über Frisur: (Breite, Höhe, Anheben in m) um die Kopfmitte
const HUT_UEBER_HAAR := Vector3(1.40, 1.15, 0.06)
## Tiefenvorrang je Schicht in Metern (siehe assets/shader/kleidung.gdshader): Haut < Hemd < Hose < Jacke. Die Abstände
## müssen größer sein als das, was Animationen die Schichten ineinanderschieben (tools/test_clipping.tscn misst das).
## Haar liegt vor allen Kleidungsschichten (assets/shader/haar.gdshader)
const TIEFE_HAAR := 0.07
const HAAR_SHADER := preload("res://assets/shader/haar.gdshader")
const TIEFE := {"hemd": 0.038, "schuhe": 0.050, "hose": 0.060, "jacke": 0.096}

static func standard(geschlecht := "m") -> Dictionary:
	var l := {
		"geschlecht": geschlecht,
		"haut": HAUTFARBEN[2].to_html(false),
		"augen": "gross",
		"emotion": "freundlich",
		"frisur": "ohne",
		"bart": "ohne",
		"hut": "ohne",
		"brille": "ohne",
		"hemd": "ohne",
		"jacke": "ohne",
		"hose": "ohne",
		"schuhe": "ohne",
		"haar": Assets.HAARFARBEN[2].to_html(false),
		"hut_farbe": Assets.HUETE[1]["farbe"].to_html(false),
		"brille_farbe": Assets.BRILLEN[1]["farbe"].to_html(false),
	}
	if geschlecht == "w":
		l["augen"] = "gross_w"
		l["emotion"] = "freundlich_w"
		l["frisur"] = "bob"
		dirndl_setzen(l, Assets.DIRNDLE.front() if not Assets.DIRNDLE.is_empty() else {})
		_kleid_setzen(l, "schuhe", "schuh_ballerina")
	else:
		for art: String in KLEIDER:
			_kleid_setzen(l, art, str(liste(art, "m")[1]["id"]))
	return l

## Ein Stück (hemd/jacke/hose) mit seinen Farben setzen
static func _kleid_setzen(l: Dictionary, art: String, id: String) -> void:
	var e := _eintrag(art, id)
	l[art] = e["id"]
	l[art + "_farbe"] = (e["farbe"] as Color).to_html(false)
	l[art + "_muster"] = (e["muster"] as Color).to_html(false)

## Ein Dirndl einsetzen: Bluse, Kleid und Schürze mit den Farben des Eintrags
static func dirndl_setzen(l: Dictionary, d: Dictionary) -> void:
	l["dirndl"] = str(d.get("id", ""))
	for art: String in KLEIDER:
		if art == "schuhe":
			continue   # Schuhe gehören nicht zum Dirndl
		if d.is_empty():
			l[art] = "ohne"
			l[art + "_farbe"] = "ffffff"
			l[art + "_muster"] = "ffffff"
		else:
			_kleid_setzen(l, art, str(d[art]))
			var farben: Variant = d.get("farben", {}).get(art)
			if farben != null:
				l[art + "_farbe"] = (farben[0] as Color).to_html(false)
				l[art + "_muster"] = (farben[1] as Color).to_html(false)

## Auswahl für ein Geschlecht ("" = alle): Einträge mit "g" gelten nur für dieses Geschlecht
static func liste(art: String, geschlecht := "") -> Array:
	var alle: Array
	match art:
		"augen": alle = Assets.AUGEN
		"emotion": alle = Assets.EMOTIONEN
		"frisur": alle = Assets.FRISUREN
		"bart": alle = Assets.BAERTE
		"hut": alle = Assets.HUETE
		"brille": alle = Assets.BRILLEN
		"hemd": alle = Assets.HEMDEN
		"jacke": alle = Assets.JACKEN
		"hose": alle = Assets.HOSEN
		"schuhe": alle = Assets.SCHUHE
		"dirndl": alle = Assets.DIRNDLE
		_: return []
	if geschlecht == "":
		return alle
	return alle.filter(func(e: Dictionary) -> bool: return not e.has("g") or e["g"] == geschlecht)

static func _eintrag(art: String, id: String) -> Dictionary:
	for e: Dictionary in liste(art):
		if e["id"] == id:
			return e
	return liste(art)[0]

## Unbekanntes und Kaputtes durch Standardwerte ersetzen (Netz- und Dateidaten sind nicht vertrauenswürdig)
static func pruefen(roh: Dictionary) -> Dictionary:
	var g := "w" if str(roh.get("geschlecht", "m")) == "w" else "m"
	var l := standard(g)
	for art: String in ARTEN:
		var id := str(roh.get(art, l[art]))
		if liste(art, g).any(func(e: Dictionary) -> bool: return e["id"] == id):
			l[art] = id
	for schluessel: String in FARB_SCHLUESSEL:
		var t := str(roh.get(schluessel, l[schluessel]))
		if t.length() <= 8 and Color.html_is_valid(t):
			l[schluessel] = t
	if g == "w" and bool(roh.get("uniform", false)):
		# Berufskleidung (Koch, Security …): Frauen tragen dieselben Stücke wie Männer, solange sie für Frauen erlaubt sind
		for art: String in KLEIDER:
			var id := str(roh.get(art, "ohne"))
			l[art] = id if liste(art, "w").any(func(e: Dictionary) -> bool: return e["id"] == id) else "ohne"
		l["uniform"] = true
	elif g == "w":
		# Frauen tragen ein Dirndl: Stücke und Auswahl müssen zusammenpassen
		var d := {}
		for e: Dictionary in Assets.DIRNDLE:
			if e["id"] == str(roh.get("dirndl", "")):
				d = e
		if d.is_empty() and not Assets.DIRNDLE.is_empty():
			d = Assets.DIRNDLE.front()
		var eigene := {}
		var schuh := str(roh.get("schuhe", l["schuhe"]))
		if liste("schuhe", "w").any(func(e: Dictionary) -> bool: return e["id"] == schuh):
			l["schuhe"] = schuh
		for k: String in ["hemd_farbe", "hemd_muster", "jacke_farbe", "jacke_muster", "hose_farbe", "hose_muster"]:
			var t := str(roh.get(k, ""))
			if t.length() <= 8 and Color.html_is_valid(t):
				eigene[k] = t
		var gewaehlt: bool = not d.is_empty() and str(roh.get("dirndl", "")) == d["id"]
		dirndl_setzen(l, d)
		if gewaehlt:
			for k: String in eigene:
				l[k] = eigene[k]
	else:
		for art: String in KLEIDER:
			var id := str(roh.get(art, l[art]))
			if liste(art, "m").any(func(e: Dictionary) -> bool: return e["id"] == id):
				l[art] = id
	l["geschlecht"] = g
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

static func zufall(geschlecht := "") -> Dictionary:
	var g := geschlecht if geschlecht != "" else ("w" if randf() < 0.5 else "m")
	var l := standard(g)
	for art: String in ARTEN:
		var eintraege := liste(art, g)
		l[art] = eintraege[randi() % eintraege.size()]["id"]
	l["haut"] = HAUTFARBEN[randi() % HAUTFARBEN.size()].to_html(false)
	l["haar"] = Assets.HAARFARBEN[randi() % (Assets.HAARFARBEN.size() if g == "w" else Assets.HAARFARBEN_NATUERLICH)].to_html(false)
	l["hut_farbe"] = Color.from_hsv(randf(), randf_range(0.3, 0.8), randf_range(0.35, 0.9)).to_html(false)
	l["brille_farbe"] = Color.from_hsv(randf(), randf_range(0.0, 0.8), randf_range(0.2, 0.9)).to_html(false)
	if g == "w":
		if not Assets.DIRNDLE.is_empty():
			dirndl_setzen(l, Assets.DIRNDLE.pick_random())
		return l
	# Kleidung: meist die zusammenpassenden Farben des Stücks, manchmal ganz andere
	for art: String in KLEIDER:
		var eintraege := liste(art, "m")
		var e: Dictionary = eintraege[randi() % eintraege.size()]
		l[art] = e["id"]
		if e["szene"] != null and randf() < 0.6:
			l[art + "_farbe"] = (e["farbe"] as Color).to_html(false)
			l[art + "_muster"] = (e["muster"] as Color).to_html(false)
		else:
			l[art + "_farbe"] = Color.from_hsv(randf(), randf_range(0.2, 0.8), randf_range(0.3, 0.95)).to_html(false)
			l[art + "_muster"] = Color.from_hsv(randf(), randf_range(0.2, 0.8), randf_range(0.3, 0.95)).to_html(false)
	return l

## Figur aus dem Basiskörper mit allen gewählten Bausteinen. Die Farben folgen in faerben(),
## sobald die Figur im Baum hängt (erst dann gibt es die Materialien).
static func bauen(l: Dictionary) -> Figur:
	var f := BASIS.instantiate() as Figur
	var z: Array[PackedScene] = []
	var hat_nr := -1
	for art: String in ARTEN:
		var e := _eintrag(art, str(l.get(art, "ohne")))
		if e["szene"] != null:
			if art == "hut":
				hat_nr = z.size()
			z.append(Assets.laden(e))
	f.zubehoer = z
	f.set_meta("geschlecht", str(l.get("geschlecht", "m")))
	# Hut über einer Frisur: größer und etwas höher, sonst steckt er im Haar (Hut um die Kopfmitte vergrößern)
	if hat_nr >= 0 and str(l.get("frisur", "ohne")) != "ohne":
		var mitte := Vector3(0, 1.5, 0)
		var t := Transform3D(Basis.from_scale(Vector3(HUT_UEBER_HAAR.x, HUT_UEBER_HAAR.y, HUT_UEBER_HAAR.x)), Vector3(0, HUT_UEBER_HAAR.z, 0))
		f.zubehoer_extra[hat_nr] = Transform3D(Basis(), mitte) * t * Transform3D(Basis(), -mitte)
	return f

## Hemd, Jacke und Hose: die Netze aus dem Baustein an das Skelett der Figur hängen (einmal je Figur).
## Der Hauptteil ("*_farbe") bekommt den Kleidungs-Shader mit zwei Farben, Knöpfe und Gürtel ("*_fest")
## behalten ihre Farbe.
static func kleiden(f: Figur, l: Dictionary) -> void:
	if f.skelett == null or f.has_meta("kleidung_da"):
		return
	f.set_meta("kleidung_da", true)
	for art: String in KLEIDER:
		var szene := Assets.laden(_eintrag(art, str(l.get(art, "ohne"))))
		if szene == null:
			continue
		var quelle := szene.instantiate()
		var fest_nr := 0
		for mi: MeshInstance3D in quelle.find_children("*", "MeshInstance3D", true, false):
			var haupt := mi.name.contains("_farbe")
			var alt := mi.get_active_material(0) as BaseMaterial3D
			mi.get_parent().remove_child(mi)
			mi.owner = null
			f.skelett.add_child(mi)
			mi.skeleton = NodePath("..")
			if haupt:
				mi.name = art + "_farbe"
				var sm := ShaderMaterial.new()
				sm.shader = KLEIDUNG_SHADER
				if alt:
					sm.set_shader_parameter("tex", alt.albedo_texture)
				sm.set_shader_parameter("leuchten", maxf(f.eigenleuchten, 0.0))
				sm.set_shader_parameter("tiefe", TIEFE[art])
				sm.set_shader_parameter("skala", float(_eintrag(art, str(l.get(art, "ohne"))).get("tiefe_skala", 1.0)))
				mi.set_surface_override_material(0, sm)
			else:
				fest_nr += 1
				mi.name = "%s_fest%d" % [art, fest_nr]
				f.material_nachruesten(mi)
				var bm := mi.get_active_material(0) as BaseMaterial3D
				if bm:
					var fm := ShaderMaterial.new()
					fm.shader = KLEIDUNG_SHADER
					fm.set_shader_parameter("einfarbig", true)
					fm.set_shader_parameter("haupt", bm.albedo_color)
					fm.set_shader_parameter("rauheit", bm.roughness)
					fm.set_shader_parameter("leuchten", maxf(f.eigenleuchten, 0.0))
					fm.set_shader_parameter("tiefe", TIEFE[art])
					mi.set_surface_override_material(0, fm)
		quelle.free()

static func faerben(f: Figur, l: Dictionary) -> void:
	kleiden(f, l)
	for art: String in KLEIDER:
		var mi := f.skelett.get_node_or_null(art + "_farbe") as MeshInstance3D if f.skelett else null
		if mi:
			var sm := mi.get_surface_override_material(0) as ShaderMaterial
			if sm:
				sm.set_shader_parameter("haupt", Color.html(str(l.get(art + "_farbe", "ffffff"))))
				sm.set_shader_parameter("muster", Color.html(str(l.get(art + "_muster", "ffffff"))))
	_faerben_rest(f, l)

## Haut und Bausteine am Kopf
static func _faerben_rest(f: Figur, l: Dictionary) -> void:
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
			"frisur": _haar_faerben(teil, haar, f.eigenleuchten, str(l.get("hut", "ohne")) != "ohne")
			"augen": Assets.faerben(teil, haut_wahl, "*_haut*")

## Frisur: Teile "*_farbe" bekommen den Haar-Shader (Haarfarbe + Tiefenvorrang), alles andere (Haargummi) den
## Einfarb-Modus des Kleidungs-Shaders mit demselben Vorrang
static func _haar_faerben(wurzel: Node, farbe: Color, leuchten: float, mit_hut: bool) -> void:
	for mi: MeshInstance3D in wurzel.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s) as BaseMaterial3D
			if m == null:
				continue
			var sm := ShaderMaterial.new()
			if String(mi.name).contains("_farbe"):
				sm.shader = HAAR_SHADER
				sm.set_shader_parameter("tex", m.albedo_texture)
				sm.set_shader_parameter("farbe", farbe)
			else:
				sm.shader = KLEIDUNG_SHADER
				sm.set_shader_parameter("einfarbig", true)
				sm.set_shader_parameter("haupt", m.albedo_color)
			sm.set_shader_parameter("rauheit", m.roughness)
			sm.set_shader_parameter("leuchten", maxf(leuchten, 0.0))
			sm.set_shader_parameter("tiefe", 0.0 if mit_hut else TIEFE_HAAR)   # unter einem Hut darf das Haar nicht über den Hut ragen
			mi.set_surface_override_material(s, sm)

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
