extends Node3D
## Bilder der Mittelfinger-Pose aus daten/mittelfinger_pose.json: vorn, von der Seite, Nahaufnahme der
## Hand (build/finger_*.png). Eingestellt wird die Pose mit tools/pose_editor.tscn.
## FIG=basis bash tools/finger.sh   (FIG leer = Bean)
var _figur: Figur
@onready var _kamera: Camera3D = $Kamera

func _ready() -> void:
	_figur = $Figur
	var fig := OS.get_environment("FIG")
	if fig != "":
		_figur.queue_free()
		_figur = (load("res://scenes/figuren/%s.tscn" % fig) as PackedScene).instantiate()
		add_child(_figur)
	for i in 10:
		await get_tree().process_frame
	_figur.mittelfinger_pose(0.0)
	for i in 5:
		await get_tree().process_frame
	await _bild("vorn", Vector3(-0.3, 1.2, 1.4), Vector3(-0.15, 1.15, 0))
	await _bild("seite", Vector3(1.7, 1.25, 0), Vector3(0, 1.15, 0))
	var sk := _figur.skelett
	var hand := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("RightHand")).origin
	await _bild("hand_vorn", hand + Vector3(0, 0.09, 0.27), hand + Vector3(0, 0.07, 0))
	await _bild("hand_seite", hand + Vector3(-0.27, 0.09, 0.0), hand + Vector3(0, 0.07, 0))
	await _bild("hand_hinten", hand + Vector3(0, 0.09, -0.27), hand + Vector3(0, 0.07, 0))
	await _bild("hand_innen", hand + Vector3(0.27, 0.09, 0.0), hand + Vector3(0, 0.07, 0))
	get_tree().quit()

func _bild(name: String, von: Vector3, ziel: Vector3) -> void:
	_kamera.global_position = von
	_kamera.look_at(ziel)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/finger_%s.png" % name)
