extends TextureRect
## Eine Spielkarte im Casino-Fenster (scenes/ui/casino_karte.tscn).
## Französisches Blatt (Blackjack): Code = Farbe * 13 + Rang (Rang 1 = Ass, 11 Bube, 12 Dame, 13 König; Farbe 0 Herz, 1 Karo, 2 Pik, 3 Kreuz),
## wie im Server (GameManager._bj_karte). Bayerisches Blatt (Watten, bayrisch = true): Code = Farbe * 8 + Rang (0 Sieben bis 7 Ass;
## Farbe 0 Eichel, 1 Laub, 2 Herz, 3 Schellen). Aufdecken dreht die Karte um die senkrechte Achse.

const FARBEN := ["herz", "karo", "pik", "kreuz"]
const RAENGE := ["", "ass", "2", "3", "4", "5", "6", "7", "8", "9", "10", "bube", "dame", "koenig"]
const B_FARBEN := ["eichel", "laub", "herz", "schellen"]
const B_RAENGE := ["7", "8", "9", "10", "unter", "ober", "koenig", "ass"]
const RUECKEN := preload("res://assets/casino/karte_ruecken.png")

var code := -1
var bayrisch := false

static func pfad(c: int) -> String:
	return "res://assets/casino/karte_%s_%s.png" % [FARBEN[(c - 1) / 13], RAENGE[(c - 1) % 13 + 1]]

static func b_pfad(c: int) -> String:
	return "res://assets/casino/bkarte_%s_%s.png" % [B_FARBEN[c / 8], B_RAENGE[c % 8]]

func _bild(c: int) -> Texture2D:
	return load(b_pfad(c) if bayrisch else pfad(c))

func verdeckt() -> void:
	code = -1
	texture = RUECKEN

func offen(c: int) -> void:
	code = c
	texture = _bild(c)

## Karte umdrehen (Verdeckte wird zur gezeigten)
func aufdecken(c: int, dauer := 0.22) -> void:
	code = c
	var tw := create_tween()
	tw.tween_property(self, "scale:x", 0.0, dauer).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: texture = _bild(c))
	tw.tween_property(self, "scale:x", 1.0, dauer).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
