class_name KegStation
extends Node3D
## Fıçı istasyonu. Oyuncu bardak eldeyken E'yi basılı tutunca doldurur
## (dolum mantığı Player içinde; burası görsel + hedef işaretidir).

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	var keg := MeshInstance3D.new()
	var keg_mesh := CylinderMesh.new()
	keg_mesh.top_radius = 0.4
	keg_mesh.bottom_radius = 0.4
	keg_mesh.height = 0.9
	keg.mesh = keg_mesh
	keg.rotation_degrees = Vector3(90, 0, 0)
	keg.position.y = 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.3, 0.15)
	keg.material_override = mat
	add_child(keg)

	var label := Label3D.new()
	label.text = "Fıçı (E basılı tut)"
	label.font_size = 44
	label.pixel_size = 0.006
	label.position = Vector3(0, 1.3, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
