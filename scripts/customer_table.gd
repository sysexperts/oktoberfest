class_name CustomerTable
extends Node3D
## Müşteri masası. Müşteri oturur → bira ister → doğru servis puan/gelir getirir.
## Sabır biterse müşteri kızgın ayrılır (kaçırılan sipariş).

signal order_served(reward: int)
signal order_missed()

enum State { EMPTY, WAITING, SERVED }

const PATIENCE := 20.0    # saniye
const REWARD := 10        # puan + para

var state: State = State.EMPTY
var _patience_left: float = 0.0
var _customer: Node3D
var _bubble: Label3D
var _bar_fill: MeshInstance3D

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	# Masa
	var table := MeshInstance3D.new()
	var top := BoxMesh.new()
	top.size = Vector3(1.2, 0.1, 1.2)
	table.mesh = top
	table.position.y = 0.75
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.35, 0.2)
	table.material_override = mat
	add_child(table)

	# Müşteri (başlangıçta gizli)
	_customer = MeshInstance3D.new()
	var cust_mesh := CapsuleMesh.new()
	cust_mesh.radius = 0.3
	cust_mesh.height = 1.3
	_customer.mesh = cust_mesh
	_customer.position = Vector3(0, 0.65, 0.9)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.8, 0.3, 0.3)
	_customer.material_override = cmat
	_customer.visible = false
	add_child(_customer)

	# Sipariş balonu
	_bubble = Label3D.new()
	_bubble.font_size = 64
	_bubble.pixel_size = 0.008
	_bubble.position = Vector3(0, 2.0, 0.9)
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.visible = false
	add_child(_bubble)

	# Sabır çubuğu
	_bar_fill = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.8, 0.08, 0.08)
	_bar_fill.mesh = bar
	_bar_fill.position = Vector3(0, 1.75, 0.9)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.2, 0.9, 0.3)
	bmat.emission_enabled = true
	bmat.emission = Color(0.2, 0.9, 0.3)
	_bar_fill.material_override = bmat
	_bar_fill.visible = false
	add_child(_bar_fill)

func is_free() -> bool:
	return state == State.EMPTY

## GameManager çağırır: masaya müşteri oturt.
func seat_customer() -> void:
	if state != State.EMPTY:
		return
	state = State.WAITING
	_patience_left = PATIENCE
	_customer.visible = true
	_bubble.text = "🍺"
	_bubble.visible = true
	_bar_fill.visible = true

func _process(delta: float) -> void:
	if state != State.WAITING:
		return
	_patience_left -= delta
	var t := clampf(_patience_left / PATIENCE, 0.0, 1.0)
	_bar_fill.scale.x = maxf(t, 0.001)
	var mat := _bar_fill.material_override as StandardMaterial3D
	var col := Color(0.9, 0.2, 0.2).lerp(Color(0.2, 0.9, 0.3), t)
	mat.albedo_color = col
	mat.emission = col
	if _patience_left <= 0.0:
		_fail()

func interact(player: Player) -> void:
	if state != State.WAITING:
		return
	var mug := player.held as Mug
	if mug == null or not mug.is_full():
		return
	# Doğru servis!
	player.consume_held()
	state = State.SERVED
	_bubble.text = "😄"
	_bar_fill.visible = false
	order_served.emit(REWARD)
	_clear_after(1.5)

func _fail() -> void:
	state = State.SERVED # tekrar tetiklenmesin
	_bubble.text = "😡"
	_bar_fill.visible = false
	order_missed.emit()
	_clear_after(1.5)

func _clear_after(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	_customer.visible = false
	_bubble.visible = false
	state = State.EMPTY
