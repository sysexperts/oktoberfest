extends Node3D
## Schwarzmarkt-Händler Gustav: steht abseits hinter dem Riesenrad, Hut und Koffer. Ab Kapitel 3 verkauft er
## Tarnung (Mantel, Komplettset) und Werkzeuge für Streiche in Konrads Zelt (scenes/ui/gustav_laden.tscn).
## Der Spieler erkennt ihn an den Methoden gustav_aktion und hinweis_text (Duck-Typing, kein class_name).

const Figuren := preload("res://scripts/figuren.gd")

var _figur: Figur

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("gustav")
	_figur = Figuren.einsetzen_look(self, Figuren.look_gustav())
	_figur.stehen()

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func hinweis_text(_geschlossen: bool) -> String:
	return "HINT_GUSTAV"

## Vom Spieler beim Drücken von E: erst reden, dann Laden öffnen
func gustav_aktion(spieler: Node) -> void:
	var welt: Node = spieler.get("_world")
	var story: Node = welt.get_node_or_null("Story") if welt else null
	var dialog := get_tree().get_first_node_in_group("dialog")
	var laden := get_tree().get_first_node_in_group("gustav_laden")
	if dialog == null or laden == null:
		return
	var wer := String(TranslationServer.translate("GUSTAV_NAME"))
	if story == null or not story.aktiv or story.kapitel < 3:
		dialog.zeigen(wer, [String(TranslationServer.translate("GUSTAV_NOCH_NICHT"))] as Array[String])
		return
	var zeilen: Array[String] = [String(TranslationServer.translate("GUSTAV_HALLO"))]
	dialog.zeigen(wer, zeilen, func() -> void: laden.zeigen(spieler))
