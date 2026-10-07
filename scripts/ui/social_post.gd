extends PanelContainer
## Ein Beitrag im Feed der Social-App (scenes/ui/social_post.tscn): Avatar mit Anfangsbuchstabe, Name, Tag, Sterne, Text.

func setze(autor: String, tag: String, sterne: float, text: String, farbe: Color) -> void:
	%Initial.text = autor.left(1)
	%Avatar.self_modulate = farbe
	%Name.text = autor
	%Tag.text = tag
	%Sterne.setze(sterne)
	%Text.text = text

## Fake-Bewertung: Knopf „Melden“ zeigen
func als_fake(melden: Callable) -> void:
	%Melden.visible = true
	%Melden.pressed.connect(melden)
