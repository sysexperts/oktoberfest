extends Node3D
## Etwas im Wohnwagen zum Anfassen (scenes/wohnwagen_innen.tscn). Bewusst ohne class_name (Server-Klassencache);
## der Spieler erkennt es an den Methoden hinweis_text und wohnwagen_aktion.
##   art "bett":    Schlafen (nur nach Feierabend), der Server startet den nächsten Tag
##   art "ausgang": zurück vor den Wohnwagen

## Hier steht der Innenraum in der Welt (weit weg von Kirmes und Zelt, siehe scenes/main.tscn)
const INNEN_ORT := Vector3(0, 0, 600)

@export var art := "bett"

func _ready() -> void:
	add_to_group("interactable")

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(geschlossen: bool) -> String:
	if art == "ausgang":
		return "HINT_WAGEN_RAUS"
	return "HINT_SLEEP" if geschlossen else "HINT_SLEEP_SHIFT"

func wohnwagen_aktion(spieler: Node) -> void:
	if art == "ausgang":
		spieler.wohnwagen_verlassen()
		return
	var welt: Node = spieler.get("_world")
	if welt != null and welt.has_method("in_intermission") and welt.in_intermission():
		welt.net_sleep.rpc_id(1)
