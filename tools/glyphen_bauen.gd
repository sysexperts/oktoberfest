extends SceneTree
## Controller-Glyphen fuer die Hinweise im Spiel bauen.
##
##   Godot.exe --headless --path . --script res://tools/glyphen_bauen.gd
##
## Ergebnis: assets/ui/glyphen/*.png (je 64x64, mit Alpha)
##
## Warum gezeichnet und nicht als SVG abgelegt: Godots SVG-Import (ThorVG) setzt
## keinen Text. Die Buchstaben muessten als Pfade vorliegen — von Hand gebaut
## sehen die nie gleich aus. Hier zeichnet die Engine Kreis und Buchstabe selbst,
## mit derselben Schrift wie das uebrige Spiel.
##
## Farben: die vier Knoepfe tragen die Farben, die auf jedem Xbox-Controller
## stehen (gruen, rot, blau, gelb) — daran erkennt man sie ohne nachzudenken.
## Rand und Schultertasten bleiben im Goldton der Oberflaeche.

const ZIEL := "res://assets/ui/glyphen"
const GROESSE := 64
const GOLD := Color("f2c14a")
const DUNKEL := Color("1b1410")

## name -> {text, farbe, form}
## form: "rund" (A/B/X/Y), "breit" (LB/RB), "kreuz" (Steuerkreuz), "stick"
const GLYPHEN := {
	"pad_a": {"text": "A", "farbe": Color("3a9d23"), "form": "rund"},
	"pad_b": {"text": "B", "farbe": Color("c1272d"), "form": "rund"},
	"pad_x": {"text": "X", "farbe": Color("0e6fb8"), "form": "rund"},
	"pad_y": {"text": "Y", "farbe": Color("e0a400"), "form": "rund"},
	"pad_lb": {"text": "LB", "farbe": DUNKEL, "form": "breit"},
	"pad_rb": {"text": "RB", "farbe": DUNKEL, "form": "breit"},
	"pad_lt": {"text": "LT", "farbe": DUNKEL, "form": "breit"},
	"pad_rt": {"text": "RT", "farbe": DUNKEL, "form": "breit"},
	"pad_hoch": {"text": "", "farbe": DUNKEL, "form": "kreuz", "richtung": 0},
	"pad_runter": {"text": "", "farbe": DUNKEL, "form": "kreuz", "richtung": 1},
	"pad_links": {"text": "", "farbe": DUNKEL, "form": "kreuz", "richtung": 2},
	"pad_rechts": {"text": "", "farbe": DUNKEL, "form": "kreuz", "richtung": 3},
	"pad_stick_links": {"text": "L", "farbe": DUNKEL, "form": "stick"},
	"pad_stick_rechts": {"text": "R", "farbe": DUNKEL, "form": "stick"},
	"pad_menue": {"text": "≡", "farbe": DUNKEL, "form": "rund"},
}

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZIEL))
	var vp := SubViewport.new()
	vp.size = Vector2i(GROESSE, GROESSE)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var gebaut := 0
	for name: String in GLYPHEN:
		var d: Dictionary = GLYPHEN[name]
		var zeichnung := Zeichnung.new()
		zeichnung.form = str(d.form)
		zeichnung.farbe = d.farbe
		zeichnung.beschriftung = str(d.text)
		zeichnung.richtung = int(d.get("richtung", -1))
		zeichnung.size = Vector2(GROESSE, GROESSE)
		vp.add_child(zeichnung)
		await process_frame
		await process_frame
		var bild := vp.get_texture().get_image()
		if bild == null:
			push_error("Kein Bild — laeuft das hier headless ohne Grafik?")
			quit(1)
			return
		bild.save_png("%s/%s.png" % [ZIEL, name])
		zeichnung.queue_free()
		gebaut += 1
	print("GLYPHEN: %d Stueck in %s" % [gebaut, ZIEL])
	quit()

## Zeichnet einen Knopf. Alles per Hand, damit die Glyphen zueinander passen.
class Zeichnung extends Control:
	var form := "rund"
	var farbe := Color.WHITE
	var beschriftung := ""
	var richtung := -1

	func _draw() -> void:
		var mitte := size * 0.5
		var rand := Color("f2c14a")
		match form:
			"rund":
				draw_circle(mitte, size.x * 0.44, Color("1b1410"))
				draw_circle(mitte, size.x * 0.40, farbe)
				draw_arc(mitte, size.x * 0.42, 0.0, TAU, 48, rand, 2.5, true)
			"breit":
				var r := Rect2(size.x * 0.06, size.y * 0.24, size.x * 0.88, size.y * 0.52)
				draw_rect(r, farbe, true)
				draw_rect(r, rand, false, 2.5)
			"stick":
				draw_circle(mitte, size.x * 0.42, farbe)
				draw_arc(mitte, size.x * 0.42, 0.0, TAU, 48, rand, 2.5, true)
				draw_arc(mitte, size.x * 0.20, 0.0, TAU, 32, rand, 2.0, true)
			"kreuz":
				_kreuz(mitte, rand)
		if beschriftung != "":
			_text(mitte)

	## Steuerkreuz: alle vier Arme, der gemeinte ausgefuellt.
	func _kreuz(mitte: Vector2, rand: Color) -> void:
		var arm := size.x * 0.17
		var lang := size.x * 0.42
		var arme := [
			Rect2(mitte.x - arm, mitte.y - lang, arm * 2.0, lang),          # hoch
			Rect2(mitte.x - arm, mitte.y, arm * 2.0, lang),                  # runter
			Rect2(mitte.x - lang, mitte.y - arm, lang, arm * 2.0),           # links
			Rect2(mitte.x, mitte.y - arm, lang, arm * 2.0),                  # rechts
		]
		for i in arme.size():
			draw_rect(arme[i], farbe if i != richtung else rand, true)
		for i in arme.size():
			draw_rect(arme[i], rand, false, 2.0)

	func _text(mitte: Vector2) -> void:
		var schrift := ThemeDB.fallback_font
		var groesse := int(size.y * (0.52 if beschriftung.length() == 1 else 0.34))
		var breite := schrift.get_string_size(beschriftung, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x
		var hoehe := schrift.get_ascent(groesse) - schrift.get_descent(groesse)
		var wo := Vector2(mitte.x - breite * 0.5, mitte.y + hoehe * 0.5)
		draw_string(schrift, wo + Vector2(0, 1.5), beschriftung, HORIZONTAL_ALIGNMENT_LEFT, -1,
			groesse, Color(0, 0, 0, 0.55))
		draw_string(schrift, wo, beschriftung, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, Color.WHITE)
