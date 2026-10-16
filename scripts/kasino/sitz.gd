extends Node3D
## Ein Sitzplatz im Casino (scenes/kasino/sitz.tscn): hängt am Tisch oder Automaten, pro Platz sitzt nur ein Spieler.
## Der Server führt Buch (GameManager.net_kasino_sitz); wer sitzt, ist für alle auf dem Hocker zu sehen.
## Blickrichtung des Sitzenden ist -Z dieses Knotens (zum Tisch hin).

func _ready() -> void:
	add_to_group("kasino_sitz")

## Eindeutige Kennung (Name des Tisches bzw. Automaten)
func sitz_id() -> String:
	return str(get_parent().name)

## Sitzt hier gerade jemand anderes als ich?
func belegt_von_anderem() -> bool:
	var welt := get_tree().current_scene
	var sitze: Dictionary = welt.get("kasino_sitze") if welt.get("kasino_sitze") != null else {}
	var wer := int(sitze.get(sitz_id(), 0))
	return wer != 0 and wer != multiplayer.get_unique_id()
