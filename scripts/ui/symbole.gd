extends RefCounted
## Symbole der Oberfläche: ein Satz gleich gezeichneter Strichgrafiken aus
## assets/ui/symbole. Vorher standen überall Emoji im Text — die sehen auf jedem
## System anders aus und passen nicht zum Fest-Theme. Hier liegt die eine Stelle,
## an der ein Name (z. B. "bier") zu einem Bild wird.
##
##   const Symbole := preload("res://scripts/ui/symbole.gd")
##   %Geld.texture = Symbole.bild("geld")
##   zeile.add_child(Symbole.rechteck("bier", 22))

const ORDNER := "res://assets/ui/symbole/%s.svg"
## Ersatz für Namen, für die es (noch) kein eigenes Bild gibt
const ERSATZ := {
	"helles": "bier", "weizen": "bier", "radler": "zitrone", "festbier": "bier",
	"brezn": "brezn", "wuerstl": "wurst", "hendl": "hendl",
	"kueche": "topf", "service": "bier", "sauberkeit": "besen", "lager": "kiste",
	"kellner": "bier", "reinigung": "besen", "zapfer": "bier",
	"strassenmusiker": "musik", "blaskapelle": "musik", "staract": "stern",
}

static var _gespeichert := {}

## Bild zu einem Namen. Unbekannte Namen geben null — die Oberfläche zeigt dann
## einfach kein Symbol statt zu krachen.
static func bild(name: String) -> Texture2D:
	var n: String = ERSATZ.get(name, name)
	if _gespeichert.has(n):
		return _gespeichert[n]
	var pfad := ORDNER % n
	var t: Texture2D = load(pfad) if ResourceLoader.exists(pfad) else null
	_gespeichert[n] = t
	return t

## Fertiges TextureRect in Wunschgröße — für Zeilen, die im Code entstehen.
static func rechteck(name: String, groesse: int = 22, farbe: Color = Color(1, 1, 1)) -> TextureRect:
	var r := TextureRect.new()
	r.texture = bild(name)
	r.custom_minimum_size = Vector2(groesse, groesse)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate = farbe
	return r

## Symbol in ein vorhandenes TextureRect setzen (aus der Szene, per %Name).
static func setze(rect: TextureRect, name: String) -> void:
	if rect == null:
		return
	rect.texture = bild(name)
	rect.visible = rect.texture != null

## Für RichTextLabel: Symbol mitten im Fließtext.
static func bbcode(name: String, groesse: int = 20) -> String:
	var n: String = ERSATZ.get(name, name)
	return "[img=%d]%s[/img]" % [groesse, ORDNER % n]
