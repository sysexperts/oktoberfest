extends Label3D
## Beschriftung in der Welt aus einem Übersetzungsschlüssel. {interact} und
## andere Aktionen werden durch die aktuell belegte Taste ersetzt.
## Label3D übersetzt im Spiel nicht zuverlässig selbst (roher Schlüssel auf dem
## Mietschild) — deshalb hier, und neu bei Sprach- oder Tastenwechsel.
## Benutzen: Skript an ein Label3D hängen, im Inspector "schluessel" setzen.

const Texte := preload("res://scripts/ui/texte.gd")

@export var schluessel := ""

func _ready() -> void:
	Einstellungen.geaendert.connect(aktualisieren)
	aktualisieren()

func aktualisieren() -> void:
	if schluessel != "":
		text = Texte.mit_tasten(schluessel)
