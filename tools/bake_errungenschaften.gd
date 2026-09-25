extends SceneTree
## Steam-Errungenschaften: 256×256-Abzeichen aus den eigenen Symbolen
## (assets/ui/symbole, selbst gezeichnet — keine Fremdlizenz).
## Aufruf: godot --headless --path . -s tools/bake_errungenschaften.gd
## Ausgabe: build/errungenschaften/<API_NAME>.png und <API_NAME>_OFF.png

## API-Name: [Symbol, Stufe 1–3 (Bronze/Silber/Gold)]
const LISTE := {
	"ERSTE_MASS": ["bier", 1], "UMSATZ_1000": ["geld", 1], "TAG_7": ["kalender", 1],
	"MASS_100": ["bier", 2], "ZELT_2": ["zelt", 1], "PUTZ_50": ["besen", 1],
	"ALLE_LIZENZEN": ["papier", 2], "UMSATZ_10000": ["geld", 2], "KELLNER_5": ["person", 2],
	"TAG_30": ["kalender", 3], "MASS_1000": ["bier", 3], "ZELT_3": ["zelt", 2],
	"UMSATZ_100000": ["geld", 3], "SAISON_1": ["pokal", 2], "FEST_WIRT_5": ["stern", 2],
	"TANZ_50": ["tanzen", 2], "KOTZE_100": ["kotzen", 2], "KOMBO_10": ["jubel", 2],
	"SAUBER_5": ["haken", 2], "DEKO_10": ["deko", 2], "EREIGNIS_10": ["megafon", 2],
	"PERSONAL_8": ["leute", 3], "SAISON_3": ["pokal", 3],
}
## Ring je Stufe: [hell, dunkel]
const RING := {1: ["#e0a86a", "#8a5226"], 2: ["#eef2f6", "#8c98a6"], 3: ["#ffe27a", "#b07a12"]}
const AUS := "res://build/errungenschaften/"

const BRETT := "res://assets/ui/logo/brett.png"
const CREME := "#f6e4b8"
const TINTE := "#1b2f5c"
const R_HOLZ := 92.0
const R_RAUTE := 109.0
const R_METALL := 124.0

var _holz: Image

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AUS))
	# Holz aus dem Logo-Brett (Mitte, ohne Schriftzug-freie Ränder)
	var brett := (load(BRETT) as Texture2D).get_image()
	brett.convert(Image.FORMAT_RGBA8)
	# nur der volle Mittelstreifen — oben/unten ist das Brett geschwungen und durchsichtig
	var b := int(brett.get_height() * 0.5)
	_holz = brett.get_region(Rect2i(brett.get_width() / 2 - b / 2, brett.get_height() / 2 - b / 2, b, b))
	_holz.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	for api: String in LISTE:
		var img := _abzeichen(LISTE[api][0], LISTE[api][1])
		img.save_png(AUS + api + ".png")
		_grau(img).save_png(AUS + api + "_OFF.png")
		print("  ", api)
	print("FERTIG")
	quit()

func _svg(inhalt: String) -> Image:
	var img := Image.new()
	img.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">%s</svg>' % inhalt, 1.0)
	img.convert(Image.FORMAT_RGBA8)
	return img

func _abzeichen(sym: String, stufe: int) -> Image:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var r: Array = RING[stufe]
	var hell := Color(r[0])
	var dunkel := Color(r[1])
	for y in 256:
		for x in 256:
			var d := Vector2(x + 0.5 - 128.0, y + 0.5 - 128.0)
			var l := d.length()
			var c := Color(0, 0, 0, 0)
			if l <= R_HOLZ:
				c = _holz.get_pixel(x, y)
				# leichte Wölbung: Mitte heller, Rand dunkler
				c = c.darkened(clampf((l / R_HOLZ) * 0.35 - 0.05, 0.0, 0.4))
			elif l <= R_RAUTE:
				# weiß-blaue Rauten, schräg wie auf der Fahne
				var u := (d.x + d.y) / 17.0
				var v := (d.x - d.y) / 17.0
				var blau := (int(floor(u)) + int(floor(v))) % 2 == 0
				c = Color("#2f6fc0") if blau else Color("#f2f4f8")
				c = c.darkened(0.12 * absf(l - (R_HOLZ + R_RAUTE) / 2.0) / 9.0)
			elif l <= R_METALL:
				c = hell.lerp(dunkel, clampf((d.y + 124.0) / 248.0, 0.0, 1.0))
				# Glanzkante oben links
				c = c.lightened(0.35 * clampf(-(d.x + d.y) / 170.0, 0.0, 1.0))
			# dunkle Trennlinien zwischen den Ringen
			if absf(l - R_HOLZ) < 1.6 or absf(l - R_RAUTE) < 1.4 or (l > R_METALL - 1.5 and l <= R_METALL):
				c = Color(TINTE)
			# weiche Kante außen
			if l > R_METALL - 1.0 and l <= R_METALL + 0.5:
				c.a *= clampf(R_METALL + 0.5 - l, 0.0, 1.0)
			img.set_pixel(x, y, c)
	# Symbol wie der Schriftzug im Logo: dicker blauer Umriss, Creme darüber, Schatten
	var gruppe := '<g transform="translate(%s) scale(5.0) translate(-12 -12)" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke="%s" stroke-width="%s">%s</g>'
	var innen := _innen(sym)
	var sterne_u := ""
	var sterne_o := ""
	for i in stufe:
		var sx := 128.0 + (i - (stufe - 1) / 2.0) * 24.0
		sterne_u += _stern(sx, 193.0, 11.5, TINTE)
		sterne_o += _stern(sx, 191.0, 8.5, r[0])
	var schatten := _svg((gruppe % ["131 121", "#000000", "4.4", innen]))
	var ebene := _svg((gruppe % ["128 118", TINTE, "4.2", innen]) + (gruppe % ["128 118", CREME, "1.9", innen]) + sterne_u + sterne_o)
	for y in 256:
		for x in 256:
			var sch := schatten.get_pixel(x, y)
			if sch.a > 0.0:
				img.set_pixel(x, y, img.get_pixel(x, y).blend(Color(0, 0, 0, sch.a * 0.35)))
			var e := ebene.get_pixel(x, y)
			if e.a > 0.0:
				img.set_pixel(x, y, img.get_pixel(x, y).blend(e))
	return img

func _innen(sym: String) -> String:
	var t := FileAccess.get_file_as_string("res://assets/ui/symbole/%s.svg" % sym)
	var a := t.find(">", t.find("<svg")) + 1
	var s := t.substr(a, t.rfind("</svg>") - a)
	# Farben der Vorlage entfernen, sonst gewinnt sie gegen Umriss/Creme
	var re := RegEx.create_from_string('(stroke|fill)="#[0-9a-fA-F]+"')
	return re.sub(s, "", true)

func _stern(x: float, y: float, r: float, farbe: String) -> String:
	var p := PackedStringArray()
	for i in 10:
		var w := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		p.append("%.1f,%.1f" % [x + cos(w) * rr, y + sin(w) * rr])
	return '<polygon points="%s" fill="%s" stroke="%s" stroke-width="1" stroke-linejoin="round"/>' % [" ".join(p), farbe, farbe]

func _grau(img: Image) -> Image:
	var g := img.duplicate() as Image
	for y in g.get_height():
		for x in g.get_width():
			var c := g.get_pixel(x, y)
			var l := (c.r * 0.3 + c.g * 0.59 + c.b * 0.11) * 0.55 + 0.08
			g.set_pixel(x, y, Color(l, l, l, c.a))
	return g
