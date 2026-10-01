extends PanelContainer
## Ein Platz im Steam-Warteraum: Steam-Profilbild im leuchtenden Rahmen, Name,
## Figur — oder ein leerer Platz mit „Freund einladen". Befüllt wird sie von
## steam_warteraum.gd. Die Karte blendet sich ein, der Rahmen leuchtet und kreist
## (assets/shader/profil_rahmen.gdshader), „Bereit" springt auf.
## Aufbau: scenes/ui/steam_spielerkarte.tscn.

const AVATAR := "res://assets/ui/avatare/figur_%d.png"

## Rahmenfarben je Zustand: [Farbe A, Farbe B, Tempo]
const RAHMEN_BEREIT := [Color(0.4, 0.9, 0.5), Color(0.85, 1.0, 0.45), 0.5]
const RAHMEN_HOST := [Color(0.98, 0.78, 0.3), Color(1.0, 0.5, 0.2), 0.3]
const RAHMEN_GAST := [Color(0.34, 0.8, 0.87), Color(0.62, 0.45, 0.95), 0.25]

signal figur_waehlen
signal einladen

@export var stil_normal: StyleBox
@export var stil_ich: StyleBox
@export var stil_leer: StyleBox
## Wartezeit vor dem Einblenden (Warteraum staffelt die vier Karten)
@export var verzoegerung := 0.0

var _sichtbar_gemacht := false
var _war_bereit := false
var _tween: Tween

func _ready() -> void:
	%Waehlen.pressed.connect(func() -> void: figur_waehlen.emit())
	%Einladen.pressed.connect(func() -> void: einladen.emit())
	mouse_entered.connect(_schweben.bind(true))
	mouse_exited.connect(_schweben.bind(false))
	pivot_offset = size / 2.0
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	%Punkt.pivot_offset = %Punkt.custom_minimum_size / 2.0
	_punkt_pulsieren()

## d: name, ich, host, figur (-1 = noch keine), bereit, textur (Steam-Profilbild oder null)
func zeige(d: Dictionary) -> void:
	%Spieler.visible = true
	%Leer.visible = false
	add_theme_stylebox_override("panel", stil_ich if d.get("ich", false) else stil_normal)
	var name_text := str(d.get("name", ""))
	%Name.text = name_text
	%Anfangsbuchstabe.text = name_text.substr(0, 1).to_upper()
	var textur: Texture2D = d.get("textur")
	%Profilbild.texture = textur
	%Anfangsbuchstabe.visible = textur == null
	var rollen: Array[String] = []
	if d.get("host", false):
		rollen.append(tr("SW_HOST"))
	if d.get("ich", false):
		rollen.append(tr("SW_YOU"))
	%Rolle.text = " · ".join(rollen)
	var figur := int(d.get("figur", -1))
	if figur >= 0:
		%FigurBild.texture = load(AVATAR % figur)
		%FigurName.text = tr("KOOP_FIG_%d" % figur)
	else:
		%FigurBild.texture = null
		%FigurName.text = tr("SW_NO_FIGURE")
	%Waehlen.visible = d.get("ich", false)
	var bereit: bool = d.get("bereit", false)
	%Marke.visible = bereit
	if bereit and not _war_bereit:
		_aufspringen(%Marke)
	_war_bereit = bereit
	_rahmen_faerben(RAHMEN_BEREIT if bereit else (RAHMEN_HOST if d.get("host", false) else RAHMEN_GAST))
	_einblenden()

func leer() -> void:
	%Spieler.visible = false
	%Leer.visible = true
	_war_bereit = false
	add_theme_stylebox_override("panel", stil_leer)
	_einblenden()

func _rahmen_faerben(werte: Array) -> void:
	var mat := %Glow.material as ShaderMaterial
	mat.set_shader_parameter("farbe_a", werte[0])
	mat.set_shader_parameter("farbe_b", werte[1])
	mat.set_shader_parameter("tempo", werte[2])
	var punkt := %Punkt.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	punkt.bg_color = werte[0]
	%Punkt.add_theme_stylebox_override("panel", punkt)

## Beim ersten Zeigen: einblenden und von klein auf Größe springen
func _einblenden() -> void:
	if _sichtbar_gemacht:
		return
	_sichtbar_gemacht = true
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.35).set_delay(verzoegerung)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_delay(verzoegerung)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _aufspringen(knoten: Control) -> void:
	knoten.pivot_offset = knoten.size / 2.0
	knoten.scale = Vector2(0.3, 0.3)
	create_tween().tween_property(knoten, "scale", Vector2.ONE, 0.45)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _schweben(an: bool) -> void:
	if not _sichtbar_gemacht:
		return
	create_tween().tween_property(self, "scale", Vector2(1.03, 1.03) if an else Vector2.ONE, 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Der Online-Punkt atmet
func _punkt_pulsieren() -> void:
	var t := create_tween().set_loops()
	t.tween_property(%Punkt, "scale", Vector2(1.25, 1.25), 0.9).set_trans(Tween.TRANS_SINE)
	t.tween_property(%Punkt, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)
