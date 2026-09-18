extends Node3D
## Goldener Pfeil über dem nächsten Tutorialziel, mit Entfernung.
## Läuft bei jedem Spieler lokal: das Ziel hängt davon ab, was *dieser* Spieler
## gerade in der Hand hat (leerer Krug → Fass, voller Krug → Gast).
## Aussehen liegt in scenes/ui/zielmarker.tscn.

const PRUEF_INTERVALL := 0.25
## Schwebehöhe über dem Ursprung des Ziels, je nach Art.
const HOEHE_STANDARD := 2.6

@onready var _entfernung: Label3D = $Entfernung

var _ziel: Node3D
var _timer := 0.0

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = PRUEF_INTERVALL
		_ziel = ziel_suchen()
	if _ziel == null or not is_instance_valid(_ziel):
		visible = false
		return
	visible = true
	var punkt := _ziel.global_position
	var schweben := sin(Time.get_ticks_msec() * 0.004) * 0.12
	global_position = punkt + Vector3(0, _hoehe(_ziel) + schweben, 0)
	var sp := _spieler()
	if sp:
		_entfernung.text = "%d m" % roundi(sp.global_position.distance_to(punkt))

## Wohin der aktuelle Tutorialschritt führt. null = kein sinnvolles Ziel.
## Schrittnummern wie in GameManager._quest_done.
func ziel_suchen() -> Node3D:
	var gm := get_parent()
	var sp := _spieler()
	if sp == null or not gm.has_method("tutorial_active") or not gm.tutorial_active():
		return null
	var geschlossen: bool = gm.in_intermission()
	# Rundgang: Hat der Wiesnchef Neues zu erzählen oder läuft er voraus, zeigt der Pfeil auf ihn
	var fuehrer := get_tree().get_first_node_in_group("wiesnchef") as Node3D
	if fuehrer and fuehrer.has_method("hat_neues") and (fuehrer.hat_neues() or fuehrer.unterwegs()):
		return fuehrer
	match int(gm._quest_step):
		0:
			# Erste Mission: dem Wiesnchef nach — er läuft zum Zelteingang vor
			var chef := get_tree().get_first_node_in_group("wiesnchef") as Node3D
			if chef:
				return chef
			return _naechstes(sp, func(n: Node) -> bool: return n is ZeltVermietung)
		1:
			# Das Schild am Zelteingang — ist es weg (gemietet), bleibt das Wiesenbüro
			var schild := _naechstes(sp, func(n: Node) -> bool: return n is ZeltVermietung)
			if schild:
				return schild
			return _naechstes(sp, func(n: Node) -> bool: return n is OfficeDesk) if geschlossen else null
		2:
			# Zelt putzen: Sack in der Hand → Müllplatz, sonst Plane/Dreck, dann liegende Säcke
			if sp.carry_state == 3 and sp.carry_pkg_kind == 3:
				return _naechstes(sp, func(n: Node) -> bool: return n is Muellplatz)
			var dreck := _naechstes(sp, func(n: Node) -> bool: return n is Mess and n.ist_dreck())
			if dreck:
				return dreck
			return _naechstes(sp, func(n: Node) -> bool: return n is Package and n.kind == 3)
		3, 4, 10, 11, 12, 13:
			return _naechstes(sp, func(n: Node) -> bool: return n is OfficeDesk) if geschlossen else null
		5:
			# Lieferwagen unterwegs — schon zeigen, wohin die Pakete später gehören
			return _naechstes(sp, func(n: Node) -> bool: return n is Lager)
		6:
			if sp.carry_state == 3:
				return _naechstes(sp, func(n: Node) -> bool: return n is Lager)
			var paket := _naechstes(sp, func(n: Node) -> bool: return n is Package)
			return paket if paket else _naechstes(sp, func(n: Node) -> bool: return n is Lager)
		7:
			return _naechstes(sp, func(n: Node) -> bool: return n is Caravan) if geschlossen else null
		8:
			if geschlossen:
				return _naechstes(sp, func(n: Node) -> bool: return n is Caravan)
			return _ziel_bedienen(sp)
	return null

## Schritt "Bediene einen Gast": Krug holen → zapfen → zum wartenden Gast.
func _ziel_bedienen(sp: Node) -> Node3D:
	if sp.carry_state == 0:
		return _naechstes(sp, func(n: Node) -> bool: return n is MugDispenser)
	if sp.carry_state == 1 and sp.carry_fill < 0.999:
		var sorte: int = sp.carry_type
		return _naechstes(sp, func(n: Node) -> bool:
			return n is KegStation and (sorte == 0 or (n as KegStation).beer_type == sorte))
	var passend := _naechstes(sp, func(n: Node) -> bool:
		return n is Customer and (n as Customer).can_serve(sp.carry_state, sp.carry_type))
	if passend:
		return passend
	return _naechstes(sp, func(n: Node) -> bool: return n is Customer and (n as Customer).order_state == 1)

func _naechstes(sp: Node3D, passt: Callable) -> Node3D:
	var bestes: Node3D = null
	var beste_dist := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		if not (n is Node3D) or not (n as Node3D).is_visible_in_tree() or not passt.call(n):
			continue
		var d := sp.global_position.distance_squared_to((n as Node3D).global_position)
		if d < beste_dist:
			beste_dist = d
			bestes = n
	return bestes

func _hoehe(t: Node3D) -> float:
	if t is Caravan:
		return 3.4
	if t is ZeltVermietung:
		return 2.4
	if t is OfficeDesk:
		return 3.0
	if t is Package:
		return 1.4
	if t is MugDispenser or t is KegStation:
		return 1.0
	if t is Customer:
		return 2.2
	return HOEHE_STANDARD

func _spieler() -> Node3D:
	var spieler := get_parent().get_node_or_null("Players")
	if spieler == null:
		return null
	return spieler.get_node_or_null(str(multiplayer.get_unique_id())) as Node3D
