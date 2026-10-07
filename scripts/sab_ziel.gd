extends Node3D
## Eine Stelle in Konrads Zelt, an der man Gustavs Werkzeug einsetzen kann (scenes/sab_ziel.tscn).
## art: "fass" (Fassbohrer), "strom" (Zange), "stink" (Stinkbombe), "juck" (Juckpulver).
## Der Spieler erkennt die Stelle an den Methoden hinweis_text und sabotage_aktion. Ob Konrad hinsieht,
## entscheidet sich hier beim Einsetzen, den Rest macht der Server (GameManager.net_sabotage).

@export_enum("fass", "strom", "stink", "juck") var art := "fass"

func _ready() -> void:
	add_to_group("interactable")
	# Der Sicherungskasten ist die einzige Stelle mit eigenem Modell
	var kasten := get_node_or_null("Kasten")
	if kasten:
		kasten.visible = art == "strom"

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(_geschlossen: bool) -> String:
	return "HINT_SAB_" + art.to_upper()

func sabotage_aktion(spieler: Node) -> void:
	var welt: Node = spieler.get("_world")
	if welt == null:
		return
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	var stufe := int(z.get("tarnung_stufe", 0)) if bool(z.get("tarnung_an", false)) else 0
	var konrad := get_tree().get_first_node_in_group("huber") as Node3D
	var erwischt: bool = konrad != null and konrad.has_method("sieht") and konrad.sieht((spieler as Node3D).global_position, stufe)
	# Konrads Kameras schwenken über die Stellen: wer im Bild steht, fliegt auf
	if not erwischt:
		for k in get_tree().get_nodes_in_group("konrad_kamera"):
			if k.sieht((spieler as Node3D).global_position, stufe):
				erwischt = true
				break
	welt.net_sabotage.rpc_id(1, art, erwischt)
