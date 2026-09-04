extends Node
## Game — global oyun durumu singleton'ı (Faz 2+ ile büyüyecek).
## Para, vardiya süresi, hijyen puanı gibi paylaşılan durumu tutar.

signal score_changed(new_score: int)
signal money_changed(new_money: int)

var score: int = 0
var money: int = 0
var hygiene: float = 100.0

func _ready() -> void:
	_ensure_input_actions()

## Girdi eylemlerini kodda tanımlar (project.godot'u elle düzenlemeye gerek kalmadan).
func _ensure_input_actions() -> void:
	var actions := {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"interact": KEY_E,
		"sprint": KEY_SHIFT,
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var ev := InputEventKey.new()
			ev.physical_keycode = actions[action_name]
			InputMap.action_add_event(action_name, ev)

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func reset() -> void:
	score = 0
	money = 0
	hygiene = 100.0
	score_changed.emit(score)
	money_changed.emit(money)
