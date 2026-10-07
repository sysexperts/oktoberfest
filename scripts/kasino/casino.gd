extends Node3D
## Das Casino: Anbau hinten an Konrads Zelt (scenes/casino.tscn, eingebaut in scenes/huber_zelt.tscn).
## Die Tür ist gesperrt, bis der Türsteher dich einlässt (Tarnung an, Server merkt sich den Tag) — dann geht die
## Sperre bei dir auf. Der Kessel dreht sich bei jedem Spiel (dreh()), bei allen Spielern.

@onready var _sperre: StaticBody3D = $Sperre

func _ready() -> void:
	add_to_group("casino")

func _process(_delta: float) -> void:
	var welt := get_tree().current_scene
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	var offen := int(z.get("casino_tag", -1)) == int(z.get("day", 0)) and bool(z.get("tarnung_an", false))
	_sperre.process_mode = Node.PROCESS_MODE_DISABLED if offen else Node.PROCESS_MODE_INHERIT
	for k in _sperre.get_children():
		var f := k as CollisionShape3D
		if f:
			f.disabled = offen

## Kessel drehen lassen, Ergebnis kommt vom Server
func dreh() -> void:
	for kessel in find_children("Kessel", "Node3D", true, false):
		var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(kessel, "rotation:y", (kessel as Node3D).rotation.y + TAU * 4.0, 3.2)

## Blackjack-Stand vom Server: Karten der Bank und des Spielers. offen = noch eine Entscheidung (Karte oder Halten).
func bj_zeigen(text: String, offen: bool) -> void:
	var dialog := get_tree().get_first_node_in_group("dialog")
	var welt := get_tree().current_scene
	if dialog == null:
		return
	var wer := String(TranslationServer.translate("CROUPIER_NAME"))
	var zeilen: Array[String] = [text]
	if offen:
		var wahl: Array[String] = [String(TranslationServer.translate("BJ_KARTE")), String(TranslationServer.translate("BJ_HALTEN"))]
		dialog.zeigen(wer, zeilen, func(i: int) -> void: welt.net_blackjack.rpc_id(1, 1 if i == 0 else 2), wahl)
	else:
		dialog.zeigen(wer, zeilen)
