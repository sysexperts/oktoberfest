class_name CustomerTable
extends Node3D
## Müşteri masası. Host mantığı yürütür; istemciler apply_sync ile görseli günceller.
## Durum + sabır oranı ağ üzerinden GameManager tarafından senkronlanır.

enum State { EMPTY = 0, WAITING = 1, SERVED = 2, MISSED = 3 }

const PATIENCE := 20.0
const REWARD := 10
const CLEAR_DELAY := 1.5

var table_index := -1
var state: int = State.EMPTY
var _patience_left := 0.0
var _clear_left := 0.0

var _customer: Node3D
var _bubble: Label3D
var _bar_fill: MeshInstance3D

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()
	_apply_visual()

func _build_visual() -> void:
	var table := MeshInstance3D.new()
	var top := BoxMesh.new()
	top.size = Vector3(1.2, 0.1, 1.2)
	table.mesh = top
	table.position.y = 0.75
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.35, 0.2)
	table.material_override = mat
	add_child(table)

	_customer = MeshInstance3D.new()
	var cust := CapsuleMesh.new()
	cust.radius = 0.3
	cust.height = 1.3
	_customer.mesh = cust
	_customer.position = Vector3(0, 0.65, 0.9)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.8, 0.3, 0.3)
	_customer.material_override = cmat
	_customer.visible = false
	add_child(_customer)

	_bubble = Label3D.new()
	_bubble.font_size = 64
	_bubble.pixel_size = 0.008
	_bubble.position = Vector3(0, 2.0, 0.9)
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.visible = false
	add_child(_bubble)

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

func ratio() -> float:
	return clampf(_patience_left / PATIENCE, 0.0, 1.0)

# ---- HOST mantığı ----
func host_seat() -> void:
	state = State.WAITING
	_patience_left = PATIENCE
	_apply_visual()

## Host her karede çağırır. Sabır bittiyse 1 döndürür (kaçırıldı).
func host_tick(delta: float) -> int:
	var missed := 0
	if state == State.WAITING:
		_patience_left -= delta
		if _patience_left <= 0.0:
			_patience_left = 0.0
			state = State.MISSED
			_clear_left = CLEAR_DELAY
			missed = 1
	elif state == State.SERVED or state == State.MISSED:
		_clear_left -= delta
		if _clear_left <= 0.0:
			state = State.EMPTY
	_apply_visual()
	return missed

## Host: servis dene. Başarılıysa true.
func host_serve() -> bool:
	if state != State.WAITING:
		return false
	state = State.SERVED
	_clear_left = CLEAR_DELAY
	_apply_visual()
	return true

# ---- İSTEMCİ senkronu ----
func apply_sync(new_state: int, new_ratio: float) -> void:
	state = new_state
	_patience_left = new_ratio * PATIENCE
	_apply_visual()

# ---- Ortak görsel ----
func _apply_visual() -> void:
	if _customer == null:
		return
	match state:
		State.WAITING:
			_customer.visible = true
			_bubble.visible = true
			_bubble.text = "🍺"
			_bar_fill.visible = true
			var t := ratio()
			_bar_fill.scale.x = maxf(t, 0.001)
			var col := Color(0.9, 0.2, 0.2).lerp(Color(0.2, 0.9, 0.3), t)
			var m := _bar_fill.material_override as StandardMaterial3D
			m.albedo_color = col
			m.emission = col
		State.SERVED:
			_customer.visible = true
			_bubble.visible = true
			_bubble.text = "😄"
			_bar_fill.visible = false
		State.MISSED:
			_customer.visible = true
			_bubble.visible = true
			_bubble.text = "😡"
			_bar_fill.visible = false
		_:
			_customer.visible = false
			_bubble.visible = false
			_bar_fill.visible = false
