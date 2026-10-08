extends Node
## Startet direkt ein neues Spiel im Fenster (zum Ansehen von Hand), ohne Menü.
## Aufruf: godot --path . res://tools/spiel_neu.tscn  (Platz 1, überschreibt den Spielstand!)

const Spielstart := preload("res://tools/spielstart.gd")

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		await Spielstart.starten(self)
