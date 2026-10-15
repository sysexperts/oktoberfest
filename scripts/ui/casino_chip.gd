extends TextureRect
## Jeton auf einem Wettfeld (scenes/ui/casino_chip.tscn): zeigt den gesetzten Betrag, Bild nach dem größten passenden Jeton.

const STUFEN := [1000, 500, 100, 50, 10]

func setze(betrag: int) -> void:
	var stufe: int = 10
	for s in STUFEN:
		if betrag >= s:
			stufe = s
			break
	texture = load("res://assets/casino/chip_%d.png" % stufe)
	%Betrag.text = str(betrag) if betrag < 10000 else "%dk" % (betrag / 1000)
