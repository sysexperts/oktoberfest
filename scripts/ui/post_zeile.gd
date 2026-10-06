extends Button
## Eine Zeile im Posteingang (scenes/ui/post_zeile.tscn): Absender, Betreff, Tag, Punkt für „ungelesen".

func setze(absender: String, betreff: String, tag: String, ungelesen: bool, gewaehlt: bool) -> void:
	%Absender.text = absender
	%Betreff.text = betreff
	%Tag.text = tag
	%Punkt.visible = ungelesen
	button_pressed = gewaehlt
	toggle_mode = true
