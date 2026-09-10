extends PanelContainer
## Eine Meldung im Stapel unten in der Mitte. Blendet ein, bleibt kurz und
## verschwindet von selbst. Aufbau: scenes/ui/meldung.tscn.

## Randfarbe je Art: 0 Info (Gold), 1 Problem (Rot), 2 Erfolg (Grün)
const FARBEN := [Color(1, 0.839, 0.349), Color(1, 0.42, 0.35), Color(0.55, 0.93, 0.55)]

@export var dauer := 4.5

func zeige(text: String, art: int) -> void:
	%Text.text = text
	var stil := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if stil:
		stil.border_color = FARBEN[clampi(art, 0, FARBEN.size() - 1)]
		add_theme_stylebox_override("panel", stil)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_interval(dauer)
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)

func text() -> String:
	return %Text.text
