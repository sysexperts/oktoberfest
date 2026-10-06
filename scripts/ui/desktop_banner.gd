extends PanelContainer
## Farbbanner oben in einem Desktop-Fenster: App-Icon, Name und Untertitel auf einem Farbverlauf (scenes/ui/desktop_banner.tscn).

func setze(icon: Texture2D, titel: String, untertitel: String, farbe_oben: Color, farbe_unten: Color, hell: Color) -> void:
	%Icon.texture = icon
	%Name.text = titel
	%Sub.text = untertitel
	%Sub.add_theme_color_override("font_color", hell)
	# Verlauf gehört dieser Instanz allein, sonst färben sich alle Banner mit
	var stil: StyleBoxTexture = get_theme_stylebox("panel").duplicate()
	var tex: GradientTexture2D = stil.texture.duplicate()
	tex.gradient = tex.gradient.duplicate()
	tex.gradient.colors = PackedColorArray([farbe_oben, farbe_unten])
	stil.texture = tex
	add_theme_stylebox_override("panel", stil)
