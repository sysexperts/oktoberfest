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

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(_geschlossen: bool) -> String:
	return {"tuer": "HINT_CASINO_TUER", "roulette": "HINT_CASINO_ROULETTE", "blackjack": "HINT_CASINO_BLACKJACK", "watten": "HINT_CASINO_WATTEN", "wuerfel": "HINT_CASINO_WUERFEL", "slot": "HINT_CASINO_SLOT"}[art]

func kasino_aktion(spieler: Node) -> void:
	var welt: Node = spieler.get("_world")
	if welt == null:
		return
	if art == "tuer":
		welt.net_casino_tuer.rpc_id(1)
		return
	if art == "watten":
		var w := get_tree().get_first_node_in_group("watten_ui")
		if w != null:
			w.zeigen(spieler)
		return
	if art == "roulette":
		var r := get_tree().get_first_node_in_group("roulette_ui")
		if r != null:
			r.zeigen(spieler)
		return
	var fenster := {"slot": "slot_ui", "blackjack": "blackjack_ui", "wuerfel": "wuerfel_ui"}
	if fenster.has(art):
		var f := get_tree().get_first_node_in_group(fenster[art])
		if f != null:
			f.zeigen(spieler)
