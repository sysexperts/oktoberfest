class_name MugDispenser
extends Node3D
## Boş bardak dağıtıcısı. Görsel sahnede; mantık Player içinde.

func _ready() -> void:
	add_to_group("interactable")
	# Der Name steht erst da, wenn man den Spender anvisiert (ziel_markieren)
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.visible = false

## Vom Spieler: der Spender ist anvisiert (Umriss an) — Name und Tastensymbol zeigen
func ziel_markieren(an: bool) -> void:
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.visible = an
	var t := get_node_or_null("TasteHinweis")
	if t:
		t.zeigen(an)
