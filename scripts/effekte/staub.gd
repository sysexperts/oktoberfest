extends Node3D
## Staubwolke vom Boden: bei Treffern, beim K.o. und wenn ein rausgeworfener Gast
## aufschlägt. Einmal auslösen, räumt sich danach selbst weg.
## Aufbau: scenes/effekte/staub.tscn — Wolke und Ring (GPUParticles3D), Knall (Ton).

const SchlagTon := preload("res://scripts/effekte/schlag_ton.gd")

## staerke 0.2 … 1.5 (Größe und Menge), ton: "schlag", "ko", "aufprall" oder "" (stumm)
func ausloesen(staerke := 1.0, ton := "schlag") -> void:
	scale = Vector3.ONE * lerpf(0.5, 1.6, clampf(staerke / 1.5, 0.0, 1.0))
	for p: GPUParticles3D in [%Wolke, %Ring]:
		p.amount_ratio = clampf(staerke, 0.25, 1.0)
		p.restart()
		p.emitting = true
	if ton != "":
		var knall: AudioStreamPlayer3D = %Knall
		knall.stream = SchlagTon.hol(ton)
		knall.pitch_scale = randf_range(0.85, 1.15)
		knall.volume_db = linear_to_db(clampf(staerke, 0.35, 1.3))
		knall.play()
	get_tree().create_timer(3.0).timeout.connect(queue_free)
