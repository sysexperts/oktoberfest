extends Node3D
## Feuerwerk am Himmel: mehrere Sterne nacheinander, jeder in eigener Farbe.
## Aufbau: scenes/effekte/feuerwerk.tscn — ein Stern (GPUParticles3D) als Vorlage, Knall (Ton).
## Einmal auslösen, räumt sich danach selbst weg.

const SchlagTon := preload("res://scripts/effekte/schlag_ton.gd")
const FARBEN := [
	Color(1.0, 0.25, 0.2), Color(1.0, 0.85, 0.2), Color(0.3, 0.8, 1.0),
	Color(0.5, 1.0, 0.4), Color(1.0, 0.45, 0.9), Color(1.0, 1.0, 1.0),
]

## anzahl Sterne, abstand = Zeit zwischen zwei Sternen in Sekunden
func ausloesen(anzahl := 12, abstand := 0.45) -> void:
	for i in anzahl:
		get_tree().create_timer(i * abstand).timeout.connect(_stern.bind(i))
	get_tree().create_timer(anzahl * abstand + 4.0).timeout.connect(queue_free)

func _stern(i: int) -> void:
	var vorlage: GPUParticles3D = %Stern
	var s: GPUParticles3D = vorlage.duplicate()
	s.process_material = vorlage.process_material.duplicate()
	(s.process_material as ParticleProcessMaterial).color = FARBEN[i % FARBEN.size()]
	s.position = Vector3(randf_range(-14.0, 14.0), randf_range(16.0, 26.0), randf_range(-8.0, 8.0))
	add_child(s)
	s.restart()
	s.emitting = true
	var knall := AudioStreamPlayer3D.new()
	knall.stream = SchlagTon.hol("ko")
	knall.bus = &"SFX"
	knall.unit_size = 30.0
	knall.pitch_scale = randf_range(0.5, 0.8)
	knall.position = s.position
	add_child(knall)
	knall.play()
