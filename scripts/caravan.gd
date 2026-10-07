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
	add_to_group("wohnwagen")
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

## Alle Wohnwagen eines Platzes in fester Reihenfolge: der eigene Wagen (Schlaf-Wagen) ist Platz 1,
## danach die übrigen nach Abstand dazu. Platz i gehört dem i-ten Spieler (Beitrittsreihenfolge).
static func plaetze(baum: SceneTree) -> Array:
	var alle: Array = baum.get_nodes_in_group("wohnwagen")
	var haupt: Caravan = null
	for w: Caravan in alle:
		if w.is_mine:
			haupt = w
	if haupt == null:
		return alle
	alle.erase(haupt)
	alle.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_to(haupt.global_position) < b.global_position.distance_to(haupt.global_position))
	alle.push_front(haupt)
	return alle

## Außenfarbe und Besitzername: aus dem Zustand des GameManagers („wagen_plaetze“, je Spieler ein Wagen)
func _process(delta: float) -> void:
	_farbe_t -= delta
	if _farbe_t > 0.0:
		return
	_farbe_t = 0.5
	var welt := get_tree().current_scene
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	var farbe := str((z.get("wagen", {}) as Dictionary).get("farbe", "blau"))
	var besitzer := ""
	var liste: Array = z.get("wagen_plaetze", [])
	var nr: int = plaetze(get_tree()).find(self)
	if nr >= 0 and nr < liste.size():
		farbe = str((liste[nr] as Dictionary).get("farbe", "blau"))
		besitzer = str((liste[nr] as Dictionary).get("name", "")) if liste.size() > 1 else ""
	elif not is_mine:
		farbe = "blau"
	$Modell.visible = farbe == "blau"
	$ModellRot.visible = farbe == "rot"
	$ModellGruen.visible = farbe == "gruen"
	$Besitzer.text = besitzer
	$Besitzer.visible = besitzer != "" and not is_mine
