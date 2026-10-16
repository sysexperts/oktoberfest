extends Node3D
## Etwas zum Anfassen im Casino (scenes/casino.tscn). Der Spieler erkennt es an hinweis_text und kasino_aktion.
##   art "tuer":     der Türsteher prüft die Tarnung (Server: net_casino_tuer)
##   art "roulette": Tisch mit Jetons und allen Wetten (scripts/ui/casino_roulette.gd) (Server: net_roulette)
##   art "blackjack": Karte, Halten, Verdoppeln gegen die Bank (scripts/ui/casino_blackjack.gd, Server: net_blackjack)
##   art "wuerfel":  Würfelbecher mit Wetten auf Tief, Sieben, Hoch, Pasch (scripts/ui/casino_wuerfel.gd, Server: net_wuerfel)
##   art "slot":     Spielautomat mit 5 Gewinnlinien (scripts/ui/casino_slot.gd, Server: net_slot)

@export_enum("tuer", "roulette", "blackjack", "watten", "wuerfel", "slot") var art := "tuer"

func _ready() -> void:
	add_to_group("interactable")
	# Die Tische bekommen ihre eigene Auflage (scenes/kasino/auflage_*.tscn): Karten und Jetons des Tischmodells weg
	if art in ["blackjack", "watten", "wuerfel"]:
		for n in find_children("*", "MeshInstance3D", true, false):
			if str(n.name).begins_with("Karte") or str(n.name).begins_with("Chip"):
				(n as Node3D).visible = false

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(_geschlossen: bool) -> String:
	var sitz := get_node_or_null("Sitz")
	if sitz != null and sitz.has_method("belegt_von_anderem") and sitz.belegt_von_anderem():
		return "HINT_CASINO_BELEGT"
	return {"tuer": "HINT_CASINO_TUER", "roulette": "HINT_CASINO_ROULETTE", "blackjack": "HINT_CASINO_BLACKJACK", "watten": "HINT_CASINO_WATTEN", "wuerfel": "HINT_CASINO_WUERFEL", "slot": "HINT_CASINO_SLOT"}[art]

func kasino_aktion(spieler: Node) -> void:
	var welt: Node = spieler.get("_world")
	if welt == null:
		return
	if art == "tuer":
		welt.net_casino_tuer.rpc_id(1)
		return
	# Alle Spiele: erst hinsetzen (pro Platz nur einer), dann öffnet sich das Spiel
	if get_node_or_null("Sitz") != null and spieler.has_method("kasino_sitz_anfragen"):
		spieler.kasino_sitz_anfragen(self)
	else:
		kasino_spiel_oeffnen(spieler)

## Das Spiel-Fenster zum Tisch öffnen (nach dem Hinsetzen)
func kasino_spiel_oeffnen(spieler: Node) -> void:
	var fenster := {"roulette": "roulette_ui", "watten": "watten_ui", "slot": "slot_ui", "blackjack": "blackjack_ui", "wuerfel": "wuerfel_ui"}
	if not fenster.has(art):
		return
	var f := get_tree().get_first_node_in_group(fenster[art])
	if f != null:
		f.zeigen(spieler)
	else:
		spieler.minispiel_beendet()
