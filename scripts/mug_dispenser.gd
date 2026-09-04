class_name MugDispenser
extends Node3D
## Boş bardak dağıtıcısı. Oyuncu yaklaşıp E'ye basınca boş bardak alır
## (mantık Player içinde; burası görsel + hedef işaretidir).

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	var base := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 0.9, 0.6)
	base.mesh = mesh
	base.position.y = 0.45
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.25)
	base.material_override = mat
	add_child(base)

	var label := Label3D.new()
	label.text = "Boş Bardak"
	label.font_size = 48
	label.pixel_size = 0.006
	label.position = Vector3(0, 1.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
