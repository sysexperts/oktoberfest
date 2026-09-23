extends Control
## Entwurf für die Leiste oben links (Vorlage des Nutzers, HTML-Mockup):
## runder Avatar am Milchglas-Panel, oben Geld in Gold, Tag und Uhrzeit,
## unten eine Pille mit Lagerbestand und zwei dünne Balken.
##
## Noch ein Entwurf: die Leiste im Spiel ist scenes/ui/hud.tscn („Oben"). Diese
## Szene wird von tools/render_leiste.tscn über das laufende Spiel gelegt, damit
## man das Aussehen beurteilen kann, bevor das HUD umgebaut wird.
##
## Aufbau in scenes/ui/leiste_neu.tscn — Farben, Radien und Abstände dort.
## Das Milchglas dahinter (assets/shader/ui_glas.gdshader) braucht die Größe des
## Panels als Uniform, weil ein Canvas-Shader die Knotengröße nicht kennt; das
## hält _process nach.

const Texte := preload("res://scripts/ui/texte.gd")
const Symbole := preload("res://scripts/ui/symbole.gd")

## Wie stark das Geld pulsiert (Vorlage: „money-glow")
const PULS_DAUER := 2.5

@onready var _glas: ColorRect = %Glas
@onready var _rahmen: PanelContainer = %Rahmen
@onready var _geld: Label = %Geld
@onready var _tag: Label = %Tag
@onready var _tag_von: Label = %TagVon
@onready var _zeit: Label = %Zeit
@onready var _bier: Label = %Bier
@onready var _essen: Label = %Essen

var _puls := 0.0

func _ready() -> void:
	%GeldSymbol.texture = Symbole.bild("geld")
	%TagSymbol.texture = Symbole.bild("kalender")
	%ZeitSymbol.texture = Symbole.bild("uhr")
	%BierSymbol.texture = Symbole.bild("bier")
	%EssenSymbol.texture = Symbole.bild("hendl")
	# Ohne Kopfbild der eigenen Figur steht im Kreis das Personen-Symbol
	if %Avatar.texture == null:
		%Avatar.texture = Symbole.bild("person")
	setze_sauberkeit(100.0)
	setze_beliebtheit(35.0)

func _process(delta: float) -> void:
	# Glas genau unter das Panel legen (Größe wächst mit dem Inhalt)
	var g := _rahmen.size
	if _glas.size != g:
		_glas.size = g
		(_glas.material as ShaderMaterial).set_shader_parameter("groesse", g)
	# Gold pulsiert leicht — in der Vorlage ein Schein, hier die Helligkeit
	_puls += delta
	var t := 0.5 + 0.5 * sin(_puls * TAU / PULS_DAUER)
	_geld.modulate = Color(1, 1, 1).lerp(Color(1.25, 1.2, 1.05), t)

## Gold, im Minus rot — der Verlauf-Shader ersetzt die Schriftfarbe, die Warnung
## muss also über die Verlaufsfarben kommen.
const GELD_OBEN := Color(0.996, 0.937, 0.616)
const GELD_UNTEN := Color(0.929, 0.667, 0.094)
const MINUS_OBEN := Color(1.0, 0.72, 0.66)
const MINUS_UNTEN := Color(0.88, 0.25, 0.2)

func setze_geld(v: int) -> void:
	_geld.text = Texte.euro(v)
	var m := _geld.material as ShaderMaterial
	m.set_shader_parameter("oben", MINUS_OBEN if v < 0 else GELD_OBEN)
	m.set_shader_parameter("unten", MINUS_UNTEN if v < 0 else GELD_UNTEN)

func setze_tag(tag: int, von: int) -> void:
	_tag.text = "%s %d" % [tr("HUD_TAG"), tag]
	_tag_von.text = "/ %d" % von

## clock: Spieluhr (8.0 = 08:00). Negativ = Zelt geschlossen.
func setze_zeit(clock: float) -> void:
	if clock < 0.0:
		_zeit.text = tr("HUD_CLOSED")
		return
	_zeit.text = "%02d:%02d" % [int(clock), int(fmod(clock, 1.0) * 60.0)]

func setze_lager(bier: int, essen: int) -> void:
	_bier.text = str(bier)
	_essen.text = str(essen)

func setze_sauberkeit(prozent: float) -> void:
	_balken(%Sauberkeit, prozent)

func setze_beliebtheit(prozent: float) -> void:
	_balken(%Beliebtheit, prozent)

## Balken füllen: die Füllung ist ein Bild mit Farbverlauf, dessen Breite
## anteilig gesetzt wird — ein StyleBox-Balken kann keinen Verlauf.
func _balken(block: Control, prozent: float) -> void:
	var anteil := clampf(prozent, 0.0, 100.0) / 100.0
	var schiene: Control = block.get_node("Schiene")
	var fuellung: Control = schiene.get_node("Fuellung")
	block.get_node("Kopf/Wert").text = "%d %%" % int(round(prozent))
	fuellung.custom_minimum_size.x = maxf(2.0, schiene.size.x * anteil)

## Bild im Avatar-Kreis (z. B. ein Kopfbild der eigenen Figur)
func setze_avatar(bild: Texture2D) -> void:
	%Avatar.texture = bild
