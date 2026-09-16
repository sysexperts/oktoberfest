extends Node
## Schreibt die fest eingebaute Aufstellung (kirmes.tscn + strassen.tscn) als
## Bau-Vorlage nach res://daten/karte_vorlage.json (für den Baumodus, F8).
## Aufruf: Godot --path . res://tools/export_vorlage.tscn

const BEHALTEN := ["Altstadt", "Wiesenbuero", "Wohnwagenplatz", "Mauern", "Pflaster", "Besucherwege", "Stadtgrenze", "Ground"]

var _liste: Array = []

func _ready() -> void:
	var kirmes := (load("res://scenes/kirmes.tscn") as PackedScene).instantiate() as Node3D
	_laufen(kirmes, Transform3D.IDENTITY)
	var f := FileAccess.open("res://daten/karte_vorlage.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"eintraege": _liste}))
	f.close()
	print("Vorlage: ", _liste.size(), " Teile")
	kirmes.free()
	get_tree().quit()

func _laufen(n: Node, eltern: Transform3D) -> void:
	for c in n.get_children():
		if not c is Node3D or String(c.name) in BEHALTEN:
			continue
		var t: Transform3D = eltern * (c as Node3D).transform
		if c.scene_file_path != "" and c.name != "Strassen":
			var s := t.basis.get_scale()
			_liste.append({"p": c.scene_file_path, "x": snappedf(t.origin.x, 0.01), "y": snappedf(t.origin.y, 0.01),
				"z": snappedf(t.origin.z, 0.01), "r": snappedf(t.basis.get_euler().y, 0.001), "s": snappedf(s.y, 0.01)})
			if absf(s.x - s.y) > 0.01 or absf(s.z - s.y) > 0.01:
				var b := t.basis
				_liste.back()["b"] = [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z]
		elif not c is MeshInstance3D:
			_laufen(c, t)
