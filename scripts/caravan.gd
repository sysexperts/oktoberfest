class_name Caravan
extends Node3D
## Wohnwagen. Nur DEIN Wohnwagen (is_mine = true) ist benutzbar:
## Molada etkileş → uyu → gün başlar (net_sleep). Diğerleri sadece dekor.

## Editörden kapatılabilir: false ise sadece dekor (etkileşim yok).
@export var is_mine := true

func _ready() -> void:
	# Mehrere Wohnwagenplätze: nur einer ist der eigene (später wählt man ihn beim Start).
	if is_mine:
		for n in get_tree().get_nodes_in_group("interactable"):
			if n != self and n is Caravan:
				is_mine = false
				break
	if is_mine:
		add_to_group("interactable")
	var label := get_node_or_null("Label") as Label3D
	if label and not is_mine:
		label.visible = false

## Ansprechpunkt an der Tür statt in der Wagenmitte — sonst muss man
## praktisch im Wohnwagen stehen, um schlafen zu können.
func interact_point() -> Vector3:
	var tuer := get_node_or_null("Modell/TuerPunkt") as Node3D
	if tuer:
		return tuer.global_position + Vector3(0, 1.0, 0)
	return global_position + global_transform.basis.z * 1.1

var _farbe_t := 0.0

## Außenfarbe (aus dem Zustand des GameManagers, „wagen.farbe“): eines der drei Modelle ist sichtbar
func _process(delta: float) -> void:
	_farbe_t -= delta
	if _farbe_t > 0.0 or not is_mine:
		return
	_farbe_t = 0.5
	var welt := get_tree().current_scene
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	var farbe := str((z.get("wagen", {}) as Dictionary).get("farbe", "blau"))
	$Modell.visible = farbe == "blau"
	$ModellRot.visible = farbe == "rot"
	$ModellGruen.visible = farbe == "gruen"
