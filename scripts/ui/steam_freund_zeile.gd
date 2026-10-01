extends PanelContainer
## Eine Karte der Freundesliste im Steam-Warteraum: Profilbild im leuchtenden
## Rahmen (Farbe und Tempo zeigen den Status), Name, Status, „Einladen". Die
## Karte blendet sich ein, hebt sich beim Darüberfahren und hakt nach dem Einladen ab.
## Aufbau: scenes/ui/steam_freund_zeile.tscn.

signal einladen(steam_id: int)

const STATUS_TEXT := {"spielt": "SW_ST_PLAYING", "online": "SW_ST_ONLINE", "abwesend": "SW_ST_AWAY"}
## Statusfarbe und Rahmen: [Text, Rahmen A, Rahmen B, Tempo, Strahl, Leuchten]
const STATUS_LOOK := {
	"spielt": [Color(0.55, 0.85, 0.3), Color(0.4, 0.9, 0.4), Color(0.95, 0.95, 0.4), 0.55, 0.7, 0.9],
	"online": [Color(0.34, 0.8, 0.87), Color(0.34, 0.8, 0.87), Color(0.5, 0.6, 0.95), 0.25, 0.45, 0.6],
	"abwesend": [Color(0.6, 0.58, 0.55), Color(0.45, 0.43, 0.4), Color(0.55, 0.52, 0.48), 0.0, 0.0, 0.15],
}

@export var stil_ruhe: StyleBox
@export var stil_hover: StyleBox
## Wartezeit vor dem Einblenden (die Liste staffelt ihre Zeilen)
@export var verzoegerung := 0.0

var _id := 0

func _ready() -> void:
	mouse_entered.connect(func() -> void: add_theme_stylebox_override("panel", stil_hover))
	mouse_exited.connect(func() -> void: add_theme_stylebox_override("panel", stil_ruhe))
	%Einladen.pressed.connect(_gedrueckt)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35).set_delay(verzoegerung)

## d: id, name, status ("spielt", "online", "abwesend"), textur (oder null)
func zeige(d: Dictionary) -> void:
	_id = int(d.get("id", 0))
	var name_text := str(d.get("name", ""))
	%Name.text = name_text
	%Anfangsbuchstabe.text = name_text.substr(0, 1).to_upper()
	var textur: Texture2D = d.get("textur")
	%Profilbild.texture = textur
	%Anfangsbuchstabe.visible = textur == null
	var status := str(d.get("status", "online"))
	var look: Array = STATUS_LOOK[status]
	%Status.text = tr(STATUS_TEXT[status])
	%Status.add_theme_color_override("font_color", look[0])
	var mat := %Glow.material as ShaderMaterial
	mat.set_shader_parameter("farbe_a", look[1])
	mat.set_shader_parameter("farbe_b", look[2])
	mat.set_shader_parameter("tempo", look[3])
	mat.set_shader_parameter("strahl", look[4])
	mat.set_shader_parameter("leuchten", look[5])
	%Einladen.text = tr("SW_INVITE")
	%Einladen.disabled = false

func als_eingeladen() -> void:
	%Einladen.text = "✓ " + tr("SW_INVITED")
	%Einladen.disabled = true

func _gedrueckt() -> void:
	einladen.emit(_id)
	als_eingeladen()
	%Einladen.pivot_offset = %Einladen.size / 2.0
	%Einladen.scale = Vector2(1.15, 1.15)
	create_tween().tween_property(%Einladen, "scale", Vector2.ONE, 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
