extends HBoxContainer
## Eine Zeile der Freundesliste im Steam-Warteraum: Profilbild, Name, Status,
## „Einladen". Aufbau: scenes/ui/steam_freund_zeile.tscn.

signal einladen(steam_id: int)

const STATUS_TEXT := {"spielt": "SW_ST_PLAYING", "online": "SW_ST_ONLINE", "abwesend": "SW_ST_AWAY"}
const STATUS_FARBE := {
	"spielt": Color(0.55, 0.8, 0.3),
	"online": Color(0.34, 0.8, 0.87),
	"abwesend": Color(0.6, 0.58, 0.55),
}

var _id := 0

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
	%Status.text = tr(STATUS_TEXT[status])
	%Status.add_theme_color_override("font_color", STATUS_FARBE[status])
	%Einladen.text = tr("SW_INVITE")
	%Einladen.disabled = false
	if not %Einladen.pressed.is_connected(_gedrueckt):
		%Einladen.pressed.connect(_gedrueckt)

func _gedrueckt() -> void:
	einladen.emit(_id)
	%Einladen.text = tr("SW_INVITED")
	%Einladen.disabled = true
