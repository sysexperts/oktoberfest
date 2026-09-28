extends Node
## Festbüro-Oberfläche im echten Spiel in allen Reitern fotografieren.
## Aufruf: VORSCHAU=pfad_%s.png godot --path . res://tools/render_festbuero.tscn
const Spielstart := preload("res://tools/spielstart.gd")
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		if await Spielstart.starten(self) == null:
			return
		TranslationServer.set_locale("de")
		for i in 40: await get_tree().process_frame
		var gm := get_tree().current_scene
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		Game.add_money(20000)
		var b: Control = gm.get_node("HUD").get_node("%Festbuero")
		b.oeffnen()
		var reiter: TabContainer = b.get_node("%Reiter")
		for i in reiter.get_tab_count():
			reiter.current_tab = i
			for f in 8: await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(OS.get_environment("VORSCHAU") % str(i))
		get_tree().quit()
