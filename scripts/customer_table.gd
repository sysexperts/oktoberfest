class_name CustomerTable
extends Node3D
## Müşteri masası. Görseller sahne düğümleridir (editörden düzenlenebilir).
## Host mantığı yürütür; istemciler apply_sync ile görseli günceller.

enum State { EMPTY = 0, WAITING = 1, SERVED = 2, MISSED = 3 }

const PATIENCE := 20.0
const REWARD := 10
const CLEAR_DELAY := 1.5

@export var table_index := 0

var state: int = State.EMPTY
var _patience_left := 0.0
var _clear_left := 0.0

@onready var _customer: MeshInstance3D = $Customer
@onready var _bubble: Label3D = $Bubble
@onready var _bar_fill: MeshInstance3D = $Bar

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("tables")
	_apply_visual()

func is_free() -> bool:
	return state == State.EMPTY

func ratio() -> float:
	return clampf(_patience_left / PATIENCE, 0.0, 1.0)

# ---- HOST mantığı ----
func host_seat() -> void:
	state = State.WAITING
	_patience_left = PATIENCE
	_apply_visual()

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
			if m:
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
