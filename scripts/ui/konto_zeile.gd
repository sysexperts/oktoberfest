extends PanelContainer
## Eine Buchungszeile im Kontoauszug der Bank-App (scenes/ui/konto_zeile.tscn): Tag, Einnahmen, Ausgaben, Ergebnis.

const GRUEN := Color(0.4, 0.92, 0.68)
const ROT := Color(1, 0.48, 0.45)

func setze(tag: String, einnahmen: String, ausgaben: String, ergebnis: String, plus: bool) -> void:
	%Tag.text = tag
	%Einnahmen.text = einnahmen
	%Ausgaben.text = ausgaben
	%Ergebnis.text = ergebnis
	%Ergebnis.add_theme_color_override("font_color", GRUEN if plus else ROT)
