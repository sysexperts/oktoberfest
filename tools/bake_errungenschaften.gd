extends SceneTree
## Steam-Errungenschaften: 256×256-Abzeichen aus den eigenen Symbolen
## (assets/ui/symbole, selbst gezeichnet — keine Fremdlizenz).
## Aufruf: godot --headless --path . -s tools/bake_errungenschaften.gd
## Ausgabe: build/errungenschaften/<API_NAME>.png und <API_NAME>_grau.png

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

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AUS))
	for api: String in LISTE:
		var sym: String = LISTE[api][0]
		var stufe: int = LISTE[api][1]
		var img := Image.new()
		if img.load_svg_from_string(_abzeichen(sym, stufe), 1.0) != OK:
			push_error("SVG kaputt: " + api)
			continue
		img.save_png(AUS + api + ".png")
		_grau(img).save_png(AUS + api + "_grau.png")
		print("  ", api)
	print("FERTIG")
	quit()

func _innen(sym: String) -> String:
	var t := FileAccess.get_file_as_string("res://assets/ui/symbole/%s.svg" % sym)
	var a := t.find(">", t.find("<svg")) + 1
	return t.substr(a, t.rfind("</svg>") - a)

func _stern(x: float, y: float, r: float, farbe: String) -> String:
	var p := PackedStringArray()
	for i in 10:
		var w := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		p.append("%.1f,%.1f" % [x + cos(w) * rr, y + sin(w) * rr])
	return '<polygon points="%s" fill="%s"/>' % [" ".join(p), farbe]

func _abzeichen(sym: String, stufe: int) -> String:
	var r: Array = RING[stufe]
	var sterne := ""
	for i in stufe:
		sterne += _stern(128.0 + (i - (stufe - 1) / 2.0) * 26.0, 204.0, 10.0, r[0])
	return """<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
<defs>
<linearGradient id="ring" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>
<radialGradient id="grund" cx="0.5" cy="0.38" r="0.7"><stop offset="0" stop-color="#3a5a9c"/><stop offset="1" stop-color="#16244a"/></radialGradient>
<pattern id="raute" width="22" height="22" patternUnits="userSpaceOnUse" patternTransform="rotate(45 128 128)"><rect width="22" height="22" fill="none"/><rect width="11" height="11" fill="#ffffff" opacity="0.05"/></pattern>
</defs>
<circle cx="128" cy="128" r="122" fill="url(#ring)"/>
<circle cx="128" cy="128" r="106" fill="url(#grund)"/>
<circle cx="128" cy="128" r="106" fill="url(#raute)"/>
<circle cx="128" cy="128" r="106" fill="none" stroke="#0c1530" stroke-width="3" opacity="0.6"/>
<g transform="translate(128 116) scale(5.6) translate(-12 -12)" fill="none" stroke="#fff3d1" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">%s</g>
%s
</svg>""" % [r[0], r[1], _innen(sym), sterne]

func _grau(img: Image) -> Image:
	var g := img.duplicate() as Image
	for y in g.get_height():
		for x in g.get_width():
			var c := g.get_pixel(x, y)
			var l := (c.r * 0.3 + c.g * 0.59 + c.b * 0.11) * 0.55 + 0.08
			g.set_pixel(x, y, Color(l, l, l, c.a))
	return g
