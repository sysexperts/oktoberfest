class_name Caravan
extends Node3D
## Wohnwagen. Jeder Spieler sucht sich beim Start einen aus (Tutorial-Schritt, GameManager.net_wagen_waehlen)
## und richtet nur seinen eigenen ein. Hinein darf jeder in jeden vergebenen Wagen, auch mehrere zugleich.
## Freie Wagen sind Kulisse, solange sie keiner ausgesucht hat.

## Editörden kapatılabilir: false ise sadece dekor (etkileşim yok).
@export var is_mine := true

## Nummer in Caravan.sortiert (gleich auf allen Rechnern) und Besitzer (Peer-ID, 0 = keiner)
var nummer := -1
var besitzer := 0
## Gerade läuft die Wahl: ein freier Wagen lässt sich aussuchen
var wahl_offen := false

func _ready() -> void:
	# Der erste Wagen gilt als Rückfall für „der eigene“ (GameManager._eigener_wohnwagen), wenn jemand keinen hat.
	if is_mine:
		for n in get_tree().get_nodes_in_group("wohnwagen"):
			if n != self and n is Caravan and (n as Caravan).is_mine:
				is_mine = false
				break
	add_to_group("wohnwagen")
	add_to_group("interactable")
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.visible = false

## Ansprechpunkt an der Tür statt in der Wagenmitte — sonst muss man
## praktisch im Wohnwagen stehen, um schlafen zu können.
func interact_point() -> Vector3:
	var tuer := get_node_or_null("Modell/TuerPunkt") as Node3D
	if tuer:
		return tuer.global_position + Vector3(0, 1.0, 0)
	return global_position + global_transform.basis.z * 1.1

## Hinweis beim Anschauen: freien Wagen aussuchen, fremden besuchen, eigenen betreten
func hinweis_text(_geschlossen: bool) -> String:
	if besitzer == 0:
		return "HINT_WAGEN_AUSSUCHEN" if wahl_offen else "HINT_WAGEN_FREI"
	if besitzer == multiplayer.get_unique_id():
		return "HINT_WAGEN_REIN"
	return "HINT_WAGEN_BESUCH"

var _farbe_t := 0.0

## Alle Wohnwagen in fester Reihenfolge (von West nach Ost, dann Nord nach Süd). Die Nummer ist der Wohnwagenplatz.
static func sortiert(baum: SceneTree) -> Array:
	var alle: Array = baum.get_nodes_in_group("wohnwagen")
	alle.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		var pa := a.global_position
		var pb := b.global_position
		if absf(pa.x - pb.x) > 0.01:
			return pa.x < pb.x
		return pa.z < pb.z)
	return alle

## Der Wagen eines Spielers aus dem Büro-Zustand („wagen_alle“, Peer → Bett, Einrichtung, Farben)
static func zustand_von(z: Dictionary, peer: int) -> Dictionary:
	var alle: Dictionary = z.get("wagen_alle", {})
	if alle.has(peer):
		return alle[peer]
	return z.get("wagen", {"bett": 1, "items": [], "farben": ["blau"], "farbe": "blau"})

## Außenfarbe und Besitzername: aus dem Zustand des GameManagers („wagen_plaetze“, je Spieler ein Platz)
func _process(delta: float) -> void:
	_farbe_t -= delta
	if _farbe_t > 0.0:
		return
	_farbe_t = 0.5
	var welt := get_tree().current_scene
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	nummer = sortiert(get_tree()).find(self)
	wahl_offen = bool(z.get("wagen_wahl_offen", false))
	var farbe := "blau"
	besitzer = 0
	var steam_besitzer := 0
	var name_besitzer := ""
	var liste: Array = z.get("wagen_plaetze", [])
	for e: Dictionary in liste:
		if int(e.get("platz", -1)) != nummer:
			continue
		# Während der Wahl zählt nur, was ein Spieler wirklich ausgesucht hat
		if wahl_offen and not bool(e.get("fest", false)):
			continue
		besitzer = int(e.get("peer", 0))
		farbe = str(e.get("farbe", "blau"))
		name_besitzer = str(e.get("name", ""))
		steam_besitzer = int(e.get("steam", 0))
	$Modell.visible = farbe == "blau"
	$ModellRot.visible = farbe == "rot"
	$ModellGruen.visible = farbe == "gruen"
	# Statt „Wohnwagen (E: schlafen)“ stehen Steam-Avatar und Name des Besitzers am Wagen
	$Besitzer.text = name_besitzer
	$Besitzer.visible = besitzer != 0
	var sid := steam_besitzer
	if besitzer == multiplayer.get_unique_id() and sid == 0:
		sid = SteamDienst.eigene_id()
	var tex: Texture2D = SteamDienst.avatar_textur(sid) if sid != 0 else null
	$Avatar.texture = tex
	$Avatar.visible = besitzer != 0 and tex != null
