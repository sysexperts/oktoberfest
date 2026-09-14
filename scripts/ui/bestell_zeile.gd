extends HBoxContainer
## Eine Zeile in „Offene Bestellungen" (HUD rechts), z. B. „🍺 8× Helles".
## Neue Zeilen gleiten ein, bei geänderter Anzahl hüpft die Zahl kurz.
## Aufbau: scenes/ui/bestell_zeile.tscn. Befüllt von hud.gd (_bestellungen_neu).

var anzahl := -1

func _ready() -> void:
	modulate.a = 0.0
	position.x += 40.0
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.tween_property(self, "position:x", position.x - 40.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setzen(symbol: String, farbe: Color, n: int, name_text: String) -> void:
	%Symbol.text = symbol
	%Symbol.modulate = farbe
	%Name.text = name_text
	%Anzahl.text = "%d×" % n
	if n != anzahl and anzahl >= 0:
		var anz: Label = %Anzahl
		anz.pivot_offset = anz.size * 0.5
		anz.scale = Vector2(1.35, 1.35)
		anz.add_theme_color_override("font_color", Color(1, 0.84, 0.35) if n > anzahl else Color(0.6, 0.95, 0.6))
		var tw := create_tween()
		tw.tween_property(anz, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void: anz.remove_theme_color_override("font_color"))
	anzahl = n

## Ausblenden und entfernen, wenn niemand mehr das bestellt.
func weg() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
