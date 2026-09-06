class_name CustomerTable
extends Node3D
## Müşteri masası. Görseller sahne düğümleridir (editörden düzenlenebilir).
## Host mantığı yürütür; istemciler apply_sync ile görseli günceller.

enum State { EMPTY = 0, WAITING = 1, SERVED = 2, MISSED = 3 }

const PATIENCE := 20.0
const REWARD := 10
const CLEAR_DELAY := 1.5
const BEER_NAMES := {1: "Helles", 2: "Weizen", 3: "Radler"}
const BEER_COLORS := {1: Color(0.95, 0.75, 0.2), 2: Color(0.85, 0.5, 0.15), 3: Color(0.85, 0.85, 0.45)}
const FOOD_NAMES := {1: "Pretzel", 2: "Sosis"}
const FOOD_COLORS := {1: Color(0.72, 0.45, 0.15), 2: Color(0.8, 0.3, 0.2)}

@export var table_index := 0
@export var active := true   # false = henüz satın alınmamış (gizli)

var state: int = State.EMPTY
var order_kind := 1        # 1 içecek, 2 yemek
var required_type := 1
var _patience_left := 0.0
var _clear_left := 0.0

@onready var _table_mesh: MeshInstance3D = $Table
@onready var _customer: MeshInstance3D = $Customer
@onready var _bubble: Label3D = $Bubble
@onready var _bar_fill: MeshInstance3D = $Bar

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("tables")
	set_active(active)

func set_active(a: bool) -> void:
	active = a
	if _table_mesh:
		_table_mesh.visible = a
	if not a:
		state = State.EMPTY
	_apply_visual()

func is_free() -> bool:
	return active and state == State.EMPTY

## İstemci tarafı ön kontrol (senkron duruma göre): bu sipariş verilebilir mi?
func can_serve(kind: int, type: int) -> bool:
	return active and state == State.WAITING and kind == order_kind and type == required_type

## Vardiya sonu: masayı boşalt (host).
func host_reset() -> void:
	state = State.EMPTY
	_patience_left = 0.0
	_apply_visual()

func ratio() -> float:
	return clampf(_patience_left / PATIENCE, 0.0, 1.0)

# ---- HOST mantığı ----
func host_seat() -> void:
	state = State.WAITING
	if randf() < 0.6:
		order_kind = 1
		required_type = randi_range(1, 3)  # bira tipi
	else:
		order_kind = 2
		required_type = randi_range(1, 2)  # yemek tipi
	_patience_left = PATIENCE
	_apply_visual()

## Dönüş kodu: 0 normal, 1 az önce kaçırıldı, 2 içen müşteri az önce ayrıldı (kir olabilir).
func host_tick(delta: float) -> int:
	var code := 0
	if state == State.WAITING:
		_patience_left -= delta
		if _patience_left <= 0.0:
			_patience_left = 0.0
			state = State.MISSED
			_clear_left = CLEAR_DELAY
			code = 1
	elif state == State.SERVED or state == State.MISSED:
		var was := state
		_clear_left -= delta
		if _clear_left <= 0.0:
			state = State.EMPTY
			if was == State.SERVED:
				code = 2
	_apply_visual()
	return code

func global_pos() -> Vector3:
	return global_position

## Doğru bira tipiyse servis eder. Yanlış tip -> false (servis olmaz).
func host_serve(kind: int, type: int) -> bool:
	if state != State.WAITING:
		return false
	if kind != order_kind or type != required_type:
		return false
	state = State.SERVED
	_clear_left = CLEAR_DELAY
	_apply_visual()
	return true

# ---- İSTEMCİ senkronu ----
func apply_sync(new_state: int, new_ratio: float, kind: int, type: int, act: bool) -> void:
	if act != active:
		set_active(act)
	state = new_state
	order_kind = kind
	required_type = type
	_patience_left = new_ratio * PATIENCE
	_apply_visual()

# ---- Ortak görsel ----
func _apply_visual() -> void:
	if _customer == null:
		return
	_customer.visible = false  # görsel müşteri artık yürüyen NPC modeli
	if not active:
		_bubble.visible = false
		_bar_fill.visible = false
		return
	match state:
		State.WAITING:
			_bubble.visible = true
			if order_kind == 2:
				_bubble.text = "🥨 " + FOOD_NAMES.get(required_type, "Yemek")
				_bubble.modulate = FOOD_COLORS.get(required_type, Color.WHITE)
			else:
				_bubble.text = "🍺 " + BEER_NAMES.get(required_type, "Bira")
				_bubble.modulate = BEER_COLORS.get(required_type, Color.WHITE)
			_bar_fill.visible = true
			var t := ratio()
			_bar_fill.scale.x = maxf(t, 0.001)
			var col := Color(0.9, 0.2, 0.2).lerp(Color(0.2, 0.9, 0.3), t)
			var m := _bar_fill.material_override as StandardMaterial3D
			if m:
				m.albedo_color = col
				m.emission = col
		State.SERVED:
			_bubble.visible = true
			_bubble.text = "😄"
			_bubble.modulate = Color.WHITE
			_bar_fill.visible = false
		State.MISSED:
			_bubble.visible = true
			_bubble.text = "😡"
			_bubble.modulate = Color.WHITE
			_bar_fill.visible = false
		_:
			_customer.visible = false
			_bubble.visible = false
			_bar_fill.visible = false
