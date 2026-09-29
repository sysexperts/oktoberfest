@tool
extends Node3D
## Nur im Editor: lädt Spielwelt und Kirmes-Aufstellung (daten/karte.json) als
## Kulisse, damit man beim Bauen der Kamerafahrt sieht, wo man ist. Wird nicht
## gespeichert (kein owner) und beim Abspielen entfernt — im Spiel kommt die
## echte Welt über den Spielstart.

@export var karte_zeigen := true:
	set(v):
		karte_zeigen = v
		if is_inside_tree():
			_neu_laden()

const WELT := "res://scenes/main.tscn"
const KARTE := "res://daten/karte.json"

func _ready() -> void:
	if Engine.is_editor_hint():
		_neu_laden()

func _neu_laden() -> void:
	for c in get_children():
		c.queue_free()
	var welt := (load(WELT) as PackedScene).instantiate()
	add_child(welt)
	if not karte_zeigen:
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(KARTE))
	if not d is Dictionary:
		return
	var teile := Node3D.new()
	teile.name = "Karte"
	add_child(teile)
	for e: Dictionary in d.get("eintraege", []):
		var szene := load(str(e.p)) as PackedScene
		if szene == null or str(e.p).contains("besucher_sperre"):
			continue
		var k := szene.instantiate() as Node3D
		if k == null:
			continue
		var s := float(e.get("s", 1.0))
		k.transform = Transform3D(Basis(Vector3.UP, float(e.get("r", 0.0))).scaled(Vector3(s, s, s)),
			Vector3(float(e.get("x", 0.0)), float(e.get("y", 0.0)), float(e.get("z", 0.0))))
		teile.add_child(k)
