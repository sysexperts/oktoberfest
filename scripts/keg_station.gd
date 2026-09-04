class_name KegStation
extends Node3D
## Fıçı istasyonu. E'yi basılı tut: elindeki boş bardağı doldurur.

const FILL_RATE := 0.6 # saniyede doluluk oranı (~1.7 sn'de dolar)

var _label: Label3D

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	# Fıçı gövdesi
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

	_label = Label3D.new()
	_label.text = "Fıçı (E basılı tut)"
	_label.font_size = 44
	_label.pixel_size = 0.006
	_label.position = Vector3(0, 1.3, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)

## E'ye basıldığı ilk anda: bilgi amaçlı (dolum hold_interact ile olur).
func interact(_player: Player) -> void:
	pass

## E basılı tutulurken her karede çağrılır.
func hold_interact(player: Player, delta: float) -> void:
	var mug := player.held as Mug
	if mug == null:
		return
	if mug.is_full():
		return
	mug.fill = mug.fill + FILL_RATE * delta
