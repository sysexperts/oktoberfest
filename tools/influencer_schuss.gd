extends Node3D
## Bilder eines Influencers (daten/influencer.json): vorn, schräg, Gesicht nah → build/influencer_<id>_*.png
## ID=sloptanablack88 godot --path . res://tools/influencer_schuss.tscn --resolution 1000x800
const Look := preload("res://scripts/charakter_look.gd")
@onready var _kamera: Camera3D = $Kamera

func _ready() -> void:
	var id := OS.get_environment("ID") if OS.get_environment("ID") != "" else "sloptanablack88"
	var daten: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://daten/influencer.json"))
	var l := Look.pruefen(daten[id]["look"])
	var f := Look.bauen(l)
	add_child(f)
	Look.faerben(f, l)
	for i in 12:
		await get_tree().process_frame
	f.anim.active = false   # Ruhepose: Gesicht und Tattoos ohne Bewegung beurteilen
	for i in 6:
		await get_tree().process_frame
	await _bild(id, "vorn", Vector3(0, 1.0, 2.6), Vector3(0, 0.95, 0))
	await _bild(id, "schraeg", Vector3(1.2, 1.3, 1.6), Vector3(0, 1.2, 0))
	await _bild(id, "gesicht", Vector3(0.0, 1.38, 0.75), Vector3(0, 1.36, 0))
	await _bild(id, "brust", Vector3(0.0, 1.0, 0.9), Vector3(0, 0.98, 0))
	await _bild(id, "arm", Vector3(0.75, 0.95, 0.75), Vector3(0.3, 0.9, 0))
	await _bild(id, "seite", Vector3(1.0, 1.4, 0.2), Vector3(0, 1.35, 0))
	get_tree().quit()

func _bild(id: String, name: String, von: Vector3, ziel: Vector3) -> void:
	_kamera.global_position = von
	_kamera.look_at(ziel)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/influencer_%s_%s.png" % [id, name])
