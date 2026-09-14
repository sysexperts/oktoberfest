extends Node3D
## „O'zapft is!" — Fass am Zelteingang. Nach dem Aufstehen ist die Kirmes offen,
## das Festzelt aber noch zu: Ein Spieler eröffnet es hier mit E, erst dann kommen
## Gäste (Test 13.09.). Sichtbar nur in der Schicht, solange das Zelt zu ist
## (GameManager._eroeffnung_anzeigen). Aufbau: scenes/zelt_eroeffnung.tscn.
## Ohne class_name (neue Klassennamen brauchen auf dem Server eine Neuindizierung).

func _ready() -> void:
	add_to_group("zelt_eroeffnung")
	bereit_setzen(false)
	Einstellungen.geaendert.connect(_beschriften)
	_beschriften()

func ist_eroeffnung() -> bool:
	return true

func interact_point() -> Vector3:
	return global_position + Vector3(0, 0.9, 0)

func bereit_setzen(bereit: bool) -> void:
	visible = bereit
	if bereit and not is_in_group("interactable"):
		add_to_group("interactable")
	elif not bereit and is_in_group("interactable"):
		remove_from_group("interactable")

func _beschriften() -> void:
	%Titel.text = TranslationServer.translate("SIGN_ZELT_EROEFFNEN")
	%Unterzeile.text = TranslationServer.translate("SIGN_ZELT_EROEFFNEN_SUB")
