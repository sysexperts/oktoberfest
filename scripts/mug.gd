class_name Mug
extends Carryable
## Bira bardağı. Boş başlar, fıçı istasyonunda doldurulur.

const FULL_HEIGHT := 0.16

var contents: String = "empty" # "empty" | "beer"
var fill: float = 0.0 : set = _set_fill # 0.0 .. 1.0

var _beer_mesh: MeshInstance3D

func _ready() -> void:
	super._ready()
	display_name = "Bira Bardağı"
	_build_visual()
	_set_fill(fill)

func _build_visual() -> void:
	# Cam bardak
	var glass := MeshInstance3D.new()
	var glass_mesh := CylinderMesh.new()
	glass_mesh.top_radius = 0.06
	glass_mesh.bottom_radius = 0.05
	glass_mesh.height = 0.18
	glass.mesh = glass_mesh
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.85, 0.9, 0.95, 0.35)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.material_override = glass_mat
	glass.position.y = 0.09
	add_child(glass)

	# Bira sıvısı (fill'e göre ölçeklenir)
	_beer_mesh = MeshInstance3D.new()
	var beer_cyl := CylinderMesh.new()
	beer_cyl.top_radius = 0.055
	beer_cyl.bottom_radius = 0.048
	beer_cyl.height = FULL_HEIGHT
	_beer_mesh.mesh = beer_cyl
	var beer_mat := StandardMaterial3D.new()
	beer_mat.albedo_color = Color(0.95, 0.65, 0.05)
	_beer_mesh.material_override = beer_mat
	add_child(_beer_mesh)

func _set_fill(value: float) -> void:
	fill = clampf(value, 0.0, 1.0)
	if fill > 0.0:
		contents = "beer"
	if _beer_mesh:
		_beer_mesh.visible = fill > 0.001
		_beer_mesh.scale.y = maxf(fill, 0.001)
		# alttan büyüsün diye taban yüksekliğinden itibaren konumla
		_beer_mesh.position.y = 0.02 + (FULL_HEIGHT * fill) * 0.5

func is_full() -> bool:
	return fill >= 0.999
