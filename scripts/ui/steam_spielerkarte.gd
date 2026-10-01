extends PanelContainer
## Ein Platz im Steam-Warteraum: Steam-Profilbild, Name, Figur — oder ein leerer
## Platz mit „Freund einladen". Befüllt wird sie von steam_warteraum.gd.
## Aufbau: scenes/ui/steam_spielerkarte.tscn.

const AVATAR := "res://assets/ui/avatare/figur_%d.png"

signal figur_waehlen
signal einladen

@export var stil_normal: StyleBox
@export var stil_ich: StyleBox
@export var stil_leer: StyleBox

func _ready() -> void:
	%Waehlen.pressed.connect(func() -> void: figur_waehlen.emit())
	%Einladen.pressed.connect(func() -> void: einladen.emit())

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
	%Marke.visible = d.get("bereit", false)

func leer() -> void:
	%Spieler.visible = false
	%Leer.visible = true
	add_theme_stylebox_override("panel", stil_leer)
