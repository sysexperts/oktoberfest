extends Node3D
## Wie lange dauert es, einen Besucher zu bauen? (ms je Besucher, 30 Stück)
##   godot --path . res://tools/perf_visitor_bau.tscn
func _ready() -> void:
	var szene := load("res://scenes/visitor.tscn") as PackedScene
	var summe := 0.0
	var hoechst := 0.0
	for i in 30:
		var t0 := Time.get_ticks_usec()
		var v := szene.instantiate()
		add_child(v)
		var ms := float(Time.get_ticks_usec() - t0) / 1000.0
		summe += ms
		hoechst = maxf(hoechst, ms)
		if i < 5 or i % 10 == 0:
			print("Besucher %2d: %6.1f ms" % [i, ms])
		await get_tree().process_frame
	print("Schnitt %.1f ms, schlimmster %.1f ms" % [summe / 30.0, hoechst])
	get_tree().quit()
