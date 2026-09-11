class_name ZeltVermietung
extends Node3D
## „Zu vermieten"-Schild am Festzelt: Mit E wird das Zelt direkt hier gemietet,
## ohne Umweg über das Wiesenbüro. Verschwindet, sobald das Zelt gemietet ist
## (GameManager._vermietung_aktualisieren). Aufbau: scenes/zelt_vermietung.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
## Muss zu GameManager.TENT_BOOK_COST passen — steht nur auf dem Schild.
@export var preis := 500

func _ready() -> void:
	add_to_group("zelt_vermietung")
	frei_setzen(true)
	Einstellungen.geaendert.connect(_beschriften)
	_beschriften()

## Angesprochen wird die Tafel, nicht der Fußpunkt.
func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.4, 0)

func frei_setzen(frei: bool) -> void:
	visible = frei
	if frei and not is_in_group("interactable"):
		add_to_group("interactable")
	elif not frei and is_in_group("interactable"):
		remove_from_group("interactable")

func _beschriften() -> void:
	%Titel.text = tr("SIGN_TENT_FOR_RENT")
	%Preis.text = tr("SIGN_TENT_PRICE") % Texte.euro(preis)
