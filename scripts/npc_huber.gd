extends Node3D
## Alois Huber, Wirt vom Nachbarzelt und Rivale. Steht vor seinem roten Zelt
## (scenes/huber_zelt.tscn). Ansprechen mit E öffnet das Gespräch unten im Bild
## (scripts/ui/dialog.gd). Was er sagt, hängt vom Stand ab:
##   Tage 1–4 Spott, 5–10 Stichelei (er sabotiert heimlich), ab 11 kündigt er das
##   Duell um Sepps Ehre an; bei Pleite bietet er an, das Zelt abzukaufen.
## Hat er eine Wette (GameManager.huber_wette_anbieten), fragt er Ja/Nein und
## trägt ein „!" über dem Kopf. Die Wette selbst entscheidet der Server.

const Figuren := preload("res://scripts/figuren.gd")

@export var figur_nr := 0

@onready var _ausruf: Label3D = get_node_or_null("Ausruf")

var _figur: Figur
var _gehoert_tag := -1
var _blick := 0.0

func _ready() -> void:
	add_to_group("huber")
	add_to_group("interactable")
	_figur = Figuren.einsetzen(self, Figuren.ALLE[posmod(figur_nr, Figuren.ALLE.size())])
	_figur.stehen()
	_blick = rotation.y

func ist_huber() -> bool:
	return true

func interact_point() -> Vector3:
	return global_position

func _welt() -> Node:
	return get_tree().current_scene

func _zustand() -> Dictionary:
	var w := _welt()
	if w and "_hud" in w and w._hud:
		return w._hud._zustand
	return {}

## Offene Wette, die noch niemand angenommen hat?
func wette_offen() -> bool:
	var w: Dictionary = _zustand().get("huber_wette", {})
	return not w.is_empty() and not bool(w.get("angenommen", false))

func _process(_delta: float) -> void:
	if _ausruf:
		var tag := int(_zustand().get("day", 0))
		_ausruf.visible = wette_offen() or (_gehoert_tag != tag and tag > 0 and _welt().has_method("tutorial_active") and not _welt().tutorial_active())

func ansprechen() -> void:
	var dialog := get_tree().get_first_node_in_group("dialog")
	if dialog == null:
		return
	var welt := _welt()
	var z := _zustand()
	var mehrere := multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0
	var a := "_IHR" if mehrere else "_DU"
	var sp := welt._players_nodes.get(multiplayer.get_unique_id()) as Node3D if welt and "_players_nodes" in welt else null
	if sp:
		var zu := sp.global_position - global_position
		rotation.y = atan2(zu.x, zu.z)
	if _figur.extra():
		get_tree().create_timer(2.6).timeout.connect(func() -> void:
			if is_instance_valid(_figur):
				_figur.stehen()
				rotation.y = _blick)
	var tag := int(z.get("day", 1))
	_gehoert_tag = tag
	var wer := String(TranslationServer.translate("HUBER_NAME"))
	var zeilen: Array[String] = []
	if int(z.get("kredit", 0)) > 0:
		zeilen.append(_t("HUBER_PLEITE" + a))
	elif tag <= 4:
		zeilen.append(_t("HUBER_SPOTT_%d" % (tag % 3 + 1) + a))
	elif tag <= 10:
		zeilen.append(_t("HUBER_KRIEG_%d" % (tag % 3 + 1) + a))
	else:
		zeilen.append(_t("HUBER_FINALE_1" + a))
		zeilen.append(_t("HUBER_FINALE_2" + a))
	var wette: Dictionary = z.get("huber_wette", {})
	if wette.is_empty() or bool(wette.get("angenommen", false)):
		if not wette.is_empty():
			zeilen.append(_t("HUBER_WETTE_LAEUFT" + a) % Texte.huber_wette_text(wette))
		dialog.zeigen(wer, zeilen, Callable())
		return
	# Wette anbieten: Ja/Nein
	zeilen.append(_t("HUBER_WETTE_FRAGE" + a) % [Texte.huber_wette_text(wette), Texte.euro(int(wette.get("einsatz", 0)))])
	var wahl: Array[String] = [_t("HUBER_WAHL_JA" + a), _t("HUBER_WAHL_NEIN" + a)]
	dialog.zeigen(wer, zeilen, func(i: int) -> void:
		if welt.has_method("net_huber_wette"):
			welt.net_huber_wette.rpc_id(1, i == 0)
		var antwort: Array[String] = [_t(("HUBER_JA" if i == 0 else "HUBER_NEIN") + a)]
		dialog.zeigen(wer, antwort, Callable()), wahl)

const Texte := preload("res://scripts/ui/texte.gd")

func _t(k: String) -> String:
	return String(TranslationServer.translate(k))
