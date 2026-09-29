extends Node3D
## Prüft umgerechnete Animationen: stellt Quelle und Ziel in dieselbe
## Animation und vergleicht die Richtung von Oberarm, Unterarm und Oberschenkel
## im Modell. Sollte bei guter Umrechnung fast gleich sein.
## Aufruf: godot --headless --path . res://tools/arm_pruefen.tscn

const PAARE := [["LeftArm", "mixamorig_LeftArm", "LeftForeArm", "mixamorig_LeftForeArm"],
	["LeftForeArm", "mixamorig_LeftForeArm", "LeftHand", "mixamorig_LeftHand"],
	["LeftUpLeg", "mixamorig_LeftUpLeg", "LeftLeg", "mixamorig_LeftLeg"],
	["Spine", "mixamorig_Spine2", "neck", "mixamorig_Neck"]]

func _ready() -> void:
	var c2: Figur = load("res://scenes/figuren/charakter2.tscn").instantiate()
	var alex: Figur = load("res://scenes/figuren/alex.tscn").instantiate()
	add_child(c2)
	add_child(alex)
	await get_tree().process_frame
	for paar in [["Idle_12", "geliehen/Idle_12"], ["Sit_and_Drink", "geliehen/Sit_and_Drink"], ["Hip_Hop_Dance", "geliehen/Hip_Hop_Dance"]]:
		c2.anim.play(paar[0])
		alex.anim.play(paar[1])
		for f in [c2, alex]:
			f.anim.seek(0.5, true)
			f.anim.speed_scale = 0.0
		await get_tree().process_frame
		await get_tree().process_frame
		print(paar[0], "  aktuell: ", c2.anim.current_animation, " / ", alex.anim.current_animation)
		for p in PAARE:
			print("  %-12s c2 %s   alex %s" % [p[0], _richtung(c2, p[0], p[2]), _richtung(alex, p[1], p[3])])
	get_tree().quit()

func _richtung(f: Figur, von: String, bis: String) -> Vector3:
	var sk := f.skelett
	var a := sk.global_transform * sk.get_bone_global_pose(sk.find_bone(von)).origin
	var b := sk.global_transform * sk.get_bone_global_pose(sk.find_bone(bis)).origin
	return ((b - a).normalized() * 100).round() / 100
