extends Label3D
## Schwebender Betrag über Gast oder Pfütze: steigt auf und verblasst.
## Aufbau: scenes/ui/betrag.tscn, erzeugt von GameManager._net_betrag.

const Texte := preload("res://scripts/ui/texte.gd")

func starte(betrag: int) -> void:
	text = "+" + Texte.euro(betrag)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "position:y", position.y + 1.2, 1.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.9).set_delay(0.6)
	tw.chain().tween_callback(queue_free)
