extends Node
## Fotografiert den Menü-Test (scenes/ui/menue_test.tscn): Ruhe, Hover mitten im
## Schaukeln, Klick mit fliegendem Spruch. Bilder: tools/menue_test_*.png (nicht im Git).
## Aufruf: godot --path . res://tools/render_menue_test.tscn --resolution 1600x975

const TEST := preload("res://scenes/ui/menue_test.tscn")

func _ready() -> void:
	var m := TEST.instantiate()
	add_child(m)
	await _frames(20)
	_foto("menue_test_ruhe")
	var laden: TextureButton = m.get_node("Leinwand/Knoepfe/SpielLaden")
	m.hover_an(laden)
	await _zeit(0.16)
	_foto("menue_test_hover_1")
	await _zeit(0.2)
	_foto("menue_test_hover_2")
	await _zeit(0.6)
	_foto("menue_test_hover_ende")
	var neu: TextureButton = m.get_node("Leinwand/Knoepfe/NeuesSpiel")
	m.hover_aus(laden)
	m.hover_an(neu)
	m.klick(neu)
	await _zeit(0.3)
	_foto("menue_test_klick")
	print("RENDER FERTIG")
	get_tree().quit()

func _foto(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
	print("  gespeichert: ", name)

func _zeit(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await _frames(1)

func _frames(n: int) -> void:
	for k in n:
		await get_tree().process_frame
