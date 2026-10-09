extends SceneTree
func _init() -> void:
	var K := load("res://scripts/karte.gd")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://daten/karte.json"))
	var liste: Array = d.eintraege
	var huber := liste.filter(func(e): return str(e.p).contains("huber_zelt"))
	print("FILTER Huber ", huber)
	var neu: Array = K._ohne_casino_platz(liste)
	print("FILTER vorher %d nachher %d" % [liste.size(), neu.size()])
	quit()
