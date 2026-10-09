extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Figuren (Budenbesitzer, Verkäufer, Konrads Gäste) dürfen keine Sichtweite an einzelnen Kleidungsstücken haben.
##   godot --headless --path . res://tools/test_figur_sichtweite.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await get_tree().create_timer(3.0).timeout
		var figuren := gm.find_children("*", "Node3D", true, false).filter(func(n): return n.get_script() != null and n.get_script().resource_path.get_file() == "figur.gd")
		var mit := 0
		var gesamt := 0
		for f in figuren:
			for g in f.find_children("*", "GeometryInstance3D", true, false):
				gesamt += 1
				if (g as GeometryInstance3D).visibility_range_end > 0.0:
					mit += 1
		print("  [%s] Figuren ohne Sichtweite an Einzelteilen  %d Figuren, %d Teile, %d mit Sichtweite" % ["OK  " if mit == 0 else "FAIL", figuren.size(), gesamt, mit])
		print("ERGEBNIS: ", "OK" if mit == 0 else "FEHLGESCHLAGEN")
		get_tree().quit(0 if mit == 0 else 1)
