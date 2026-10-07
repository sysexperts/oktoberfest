extends Node3D
## Etwas zum Anfassen im Casino (scenes/casino.tscn). Der Spieler erkennt es an hinweis_text und kasino_aktion.
##   art "tuer":     der Türsteher prüft die Tarnung (Server: net_casino_tuer)
##   art "roulette": Rot oder Schwarz, 50 € Einsatz (Server: net_roulette)
##   art "blackjack": Karte oder Halten gegen die Bank (Server: net_blackjack)

@export_enum("tuer", "roulette", "blackjack", "watten") var art := "tuer"

func _ready() -> void:
	add_to_group("interactable")

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(_geschlossen: bool) -> String:
	return {"tuer": "HINT_CASINO_TUER", "roulette": "HINT_CASINO_ROULETTE", "blackjack": "HINT_CASINO_BLACKJACK", "watten": "HINT_CASINO_WATTEN"}[art]

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
	var dialog := get_tree().get_first_node_in_group("dialog")
	if dialog == null:
		return
	if art == "blackjack":
		var f: Array[String] = [String(TranslationServer.translate("BJ_FRAGE"))]
		var w: Array[String] = [String(TranslationServer.translate("BJ_SPIELEN")), String(TranslationServer.translate("BJ_NEIN"))]
		dialog.zeigen(String(TranslationServer.translate("CROUPIER_NAME")), f, func(i: int) -> void:
			if i == 0:
				welt.net_blackjack.rpc_id(1, 0), w)
		return
	var wer := String(TranslationServer.translate("CROUPIER_NAME"))
	var zeilen: Array[String] = [String(TranslationServer.translate("CROUPIER_FRAGE"))]
	var wahl: Array[String] = [String(TranslationServer.translate("CROUPIER_ROT")), String(TranslationServer.translate("CROUPIER_SCHWARZ"))]
	dialog.zeigen(wer, zeilen, func(i: int) -> void: welt.net_roulette.rpc_id(1, i), wahl)
