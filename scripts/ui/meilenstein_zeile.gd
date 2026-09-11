extends PanelContainer
## Eine Zeile im Reiter „Ziele" des Wiesenbüros: Titel, Beschreibung,
## Fortschrittsbalken, Belohnung, Haken. Aufbau: scenes/ui/meilenstein_zeile.tscn.

const Texte := preload("res://scripts/ui/texte.gd")

@export var stil_offen: StyleBox
@export var stil_erreicht: StyleBox

func setze(titel: String, text: String, wert: int, ziel: int, belohnung: String, erreicht: bool) -> void:
	%Titel.text = ("🏆 " if erreicht else "") + titel
	%Text.text = text
	var angezeigt := mini(wert, ziel)
	%Balken.max_value = ziel
	%Balken.value = angezeigt
	%Wert.text = "%s / %s" % [Texte.geld(angezeigt), Texte.geld(ziel)]
	%Belohnung.text = tr("MS_REWARD") % belohnung
	%Status.visible = erreicht
	add_theme_stylebox_override("panel", stil_erreicht if erreicht else stil_offen)
