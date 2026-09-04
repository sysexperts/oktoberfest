extends Node
## Game — global oyun durumu singleton'ı (Faz 2+ ile büyüyecek).
## Para, vardiya süresi, hijyen puanı gibi paylaşılan durumu tutar.

signal score_changed(new_score: int)

var score: int = 0
var money: int = 0
var hygiene: float = 100.0

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func reset() -> void:
	score = 0
	money = 0
	hygiene = 100.0
	score_changed.emit(score)
