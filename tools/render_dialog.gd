extends Node
## Zeigt das Gesprächsfenster (scenes/ui/dialog.tscn) mit Beispieltext, ohne Spiel:
## einmal mit Text und einmal mit Ja/Nein-Frage. Bilder: tools/dialog_text.png, dialog_frage.png
##   godot --path . res://tools/render_dialog.tscn --resolution 1280x720
func _ready() -> void:
	var hg := ColorRect.new()
	hg.color = Color(0.35, 0.5, 0.3)
	hg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hg)
	var d: CanvasLayer = load("res://scenes/ui/dialog.tscn").instantiate()
	add_child(d)
	await _warte(5)
	d.visible = true
	d.get_node("%Sprecher").text = "Festleiter"
	d.get_node("%Text").text = "Unterschreibt vorne am roten Schild, dann gehört das Zelt euch. Danach kommt der Rest von allein — erst die Tische, dann das Bier."
	d.get_node("%Hinweis").text = "Linksklick / E weiter"
	d.get_node("%Kasten").modulate.a = 1.0
	d.set_process(false)
	await _warte(10)
	get_viewport().get_texture().get_image().save_png("res://tools/dialog_text.png")
	d.get_node("%Text").text = "Übernehmt ihr Sepps Zelt?"
	d.get_node("%Auswahl").visible = true
	d.get_node("%Hinweis").visible = false
	d.get_node("%Ja").text = "1  Ja, wir übernehmen"
	d.get_node("%Nein").text = "2  Erst mal nicht"
	await _warte(10)
	get_viewport().get_texture().get_image().save_png("res://tools/dialog_frage.png")
	print("RENDER FERTIG")
	get_tree().quit()

func _warte(n: int) -> void:
	for i in n:
		await get_tree().process_frame
