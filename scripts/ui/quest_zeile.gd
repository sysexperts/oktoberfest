extends PanelContainer
## Eine Quest im Quests-Fenster (scenes/ui/quest_zeile.tscn). Angebote haben Knöpfe zum Annehmen und Ablehnen.

signal angenommen
signal abgelehnt

func _ready() -> void:
	%Annehmen.text = tr("QUESTS_ANNEHMEN")
	%Ablehnen.text = tr("QUESTS_ABLEHNEN")
	%Annehmen.pressed.connect(func() -> void: angenommen.emit())
	%Ablehnen.pressed.connect(func() -> void: abgelehnt.emit())

## Titel und Text sind Schlüssel (Q_<kapitel>_<nr>_TITLE/_TEXT). Fehlt die Übersetzung, steht die Quest-ID da.
func setze(id: String, titel: String, text: String, frist: String, angebot: bool, platz: bool) -> void:
	%Titel.text = titel
	%Text.text = text
	%Frist.text = frist
	%Frist.visible = frist != ""
	%Knoepfe.visible = angebot
	%Annehmen.disabled = not platz
	%Annehmen.tooltip_text = "" if platz else tr("QUESTS_VOLL")
