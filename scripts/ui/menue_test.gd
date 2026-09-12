extends Control
## TEST fürs neue Hauptmenü aus den gelieferten Bildern (assets/ui/menue_vorlage.png,
## ui_bogen.png). Noch nicht im Spiel eingebunden — nur zum Anschauen.
## Die „Leinwand" hat die Größe der Vorlage (1607×979) und wird bildschirmfüllend
## skaliert; Logo und Knöpfe liegen genau über den gemalten.
##
## Logo und Knöpfe sind in die Vorlage mitgemalt. Deshalb werden sie nie kleiner,
## gekippt oder verschoben (sonst blitzt das gemalte Original hervor) — alle
## Bewegungen skalieren nur ≥ 1 um die Mitte:
## Hover: Schild wabbelt wie Wackelpudding, wird größer und heller.
## Klick: Knopf wird kurz dunkler, ein Spruch fliegt hoch. Logo „atmet".

const VORLAGE := Vector2(1607, 979)
## Knopf -> Spruch beim Klick
const SPRUECHE := {
	"NeuesSpiel": "O'zapft is!", "SpielLaden": "Weiter geht's!", "Einstellungen": "Zefix!",
	"Credits": "Servus!", "Beenden": "Pfiat di!", "Zahnrad": "Zefix!",
}

@onready var _leinwand: Control = $Leinwand
@onready var _logo: TextureRect = $Leinwand/Logo
var _t := 0.0
var _tweens := {}

func _ready() -> void:
	for knopf: TextureButton in $Leinwand/Knoepfe.get_children():
		knopf.pivot_offset = knopf.size * 0.5
		knopf.mouse_entered.connect(hover_an.bind(knopf))
		knopf.mouse_exited.connect(hover_aus.bind(knopf))
		knopf.button_down.connect(_gedrueckt.bind(knopf))
		knopf.pressed.connect(klick.bind(knopf))
	_logo.pivot_offset = _logo.size * 0.5
	get_viewport().size_changed.connect(_anpassen)
	_anpassen()

## Vorlage bildschirmfüllend (wie „cover") — Ränder dürfen abgeschnitten werden.
func _anpassen() -> void:
	var vp := get_viewport_rect().size
	var s := maxf(vp.x / VORLAGE.x, vp.y / VORLAGE.y)
	_leinwand.scale = Vector2(s, s)
	_leinwand.position = (vp - VORLAGE * s) * 0.5

func _process(delta: float) -> void:
	_t += delta
	# Atmen: nur größer als das gemalte Logo, nie kleiner
	var atem := 1.0 + (sin(_t * 1.6) * 0.5 + 0.5) * 0.02
	_logo.scale = Vector2(atem, atem)

func hover_an(knopf: TextureButton) -> void:
	_neuer_tween(knopf)
	var tw: Tween = _tweens[knopf]
	knopf.modulate = Color(1.18, 1.14, 1.05)
	# Wackelpudding: abwechselnd breiter und höher, jede Achse bleibt ≥ 1.04
	for s in [Vector2(1.12, 1.04), Vector2(1.05, 1.13), Vector2(1.09, 1.05), Vector2(1.06, 1.08), Vector2(1.07, 1.07)]:
		tw.tween_property(knopf, "scale", s, 0.08).set_trans(Tween.TRANS_SINE)

func hover_aus(knopf: TextureButton) -> void:
	_neuer_tween(knopf)
	var tw: Tween = _tweens[knopf]
	tw.set_parallel(true)
	tw.tween_property(knopf, "scale", Vector2.ONE, 0.15)
	tw.tween_property(knopf, "modulate", Color.WHITE, 0.15)

func _gedrueckt(knopf: TextureButton) -> void:
	_neuer_tween(knopf)
	# Drücken = dunkler statt kleiner (kleiner würde das gemalte Original zeigen)
	_tweens[knopf].tween_property(knopf, "modulate", Color(0.75, 0.72, 0.68), 0.05)

func klick(knopf: TextureButton) -> void:
	_neuer_tween(knopf)
	var tw: Tween = _tweens[knopf]
	tw.set_parallel(true)
	tw.tween_property(knopf, "modulate", Color(1.18, 1.14, 1.05), 0.15)
	tw.tween_property(knopf, "scale", Vector2(1.14, 1.14), 0.08)
	tw.chain().tween_property(knopf, "scale", Vector2(1.07, 1.07), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var spruch := $Spruch.duplicate() as Label
	spruch.visible = true
	spruch.text = SPRUECHE.get(String(knopf.name), "Prost!")
	add_child(spruch)
	var mitte := knopf.get_global_rect().get_center()
	spruch.position = mitte - spruch.size * 0.5 + Vector2(randf_range(-60, 60), -30)
	spruch.pivot_offset = spruch.size * 0.5
	spruch.rotation = randf_range(-0.15, 0.15)
	var flug := create_tween().set_parallel(true)
	flug.tween_property(spruch, "position:y", spruch.position.y - 90.0, 0.9).set_ease(Tween.EASE_OUT)
	flug.tween_property(spruch, "scale", Vector2(1.3, 1.3), 0.9)
	flug.tween_property(spruch, "modulate:a", 0.0, 0.9).set_delay(0.3)
	flug.chain().tween_callback(spruch.queue_free)

func _neuer_tween(knopf: TextureButton) -> void:
	if _tweens.has(knopf) and (_tweens[knopf] as Tween).is_valid():
		(_tweens[knopf] as Tween).kill()
	_tweens[knopf] = create_tween()
