class_name RundgangStation
extends Node3D
## Eine Station im Rundgang des Festleiters (scripts/npc_festleiter.gd).
## Sobald das Tutorial Schritt `schritt` erreicht (GameManager._quest_done),
## läuft er die Marker3D-Kinder der Reihe nach ab, bleibt am letzten stehen
## (Blickrichtung = Drehung des letzten Markers) und erklärt beim Ansprechen
## die `zeilen`. Ohne Marker bleibt er, wo er ist.
## Texte: locale/texte.csv, <Schlüssel>_DU / _IHR.

@export var schritt := 1
@export var zeilen: Array[String] = []
## Direkt hinstellen statt hinlaufen (z. B. nach „Tutorial überspringen")
@export var springen := false

func _ready() -> void:
	add_to_group("rundgang_station")

func wegpunkte() -> Array[Marker3D]:
	var w: Array[Marker3D] = []
	for c in get_children():
		if c is Marker3D:
			w.append(c)
	return w
