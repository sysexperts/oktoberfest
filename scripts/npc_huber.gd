extends Node3D
## Konrad, Wirt vom Nachbarzelt und Rivale. Steht vor seinem roten Zelt
## (scenes/huber_zelt.tscn). Ansprechen mit E öffnet das Gespräch unten im Bild
## (scripts/ui/dialog.gd). Was er sagt, hängt vom Stand ab:
##   Tage 1–4 Spott, 5–10 Stichelei (er sabotiert heimlich), ab 11 kündigt er das
##   Duell um Sepps Ehre an; bei Pleite bietet er an, das Zelt abzukaufen.
## Hat er eine Wette (GameManager.huber_wette_anbieten), fragt er Ja/Nein und
## trägt ein „!" über dem Kopf. Die Wette selbst entscheidet der Server.

const Figuren := preload("res://scripts/figuren.gd")

@export var figur_nr := 0
## Eigene Figur statt Nummer aus Figuren.ALLE — Konrad ist keine Gastfigur
## (scenes/figuren/konrad.tscn: Zylinderhut, Zwirbelbart, Weinrot).
@export var figur_szene: PackedScene

@onready var _ausruf: Label3D = get_node_or_null("Ausruf")

var _figur: Figur
var _gehoert_tag := -1
var _blick := 0.0
## Runde durch sein Zelt (Punkte relativ zum Zelt, Boden y = 0). Leer = steht an seinem Platz.
## Wer sabotiert, während Konrad hinsieht, fliegt auf (sieht()).
@export var runde: Array[Vector3] = []
@export var tempo := 1.0
@export var pause := 3.0
var _punkt := 0
var _warte := 0.0
var _rennt := false

func _ready() -> void:
	add_to_group("huber")
	add_to_group("interactable")
	_figur = Figuren.einsetzen_look(self, Figuren.look_huber())
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

## Beim Ansprechen weich zum Spieler drehen, nach dem Gespräch zurück in die alte Blickrichtung
var _zu_spieler := 0.0
var _dreht := false

func _zuwenden(delta: float) -> void:
	if not _dreht or _rennt:
		return
	var dialog := get_tree().get_first_node_in_group("dialog")
	var im_gespraech: bool = dialog != null and dialog.get("aktiv") == true
	var ziel := _zu_spieler if im_gespraech else _blick
	rotation.y = lerp_angle(rotation.y, ziel, minf(1.0, 6.0 * delta))
	if not im_gespraech and absf(angle_difference(rotation.y, _blick)) < 0.02:
		rotation.y = _blick
		_dreht = false

func _process(delta: float) -> void:
	_patrouille(delta)
	_zuwenden(delta)
	if _ausruf:
		var tag := int(_zustand().get("day", 0))
		_ausruf.visible = wette_offen() or bool(_zustand().get("duell_offen", false)) or (_gehoert_tag != tag and tag > 0 and _welt().has_method("tutorial_active") and not _welt().tutorial_active())

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
		_zu_spieler = atan2(zu.x, zu.z)
		_dreht = true
	if _figur.extra():
		get_tree().create_timer(2.6).timeout.connect(func() -> void:
			if is_instance_valid(_figur):
				_figur.stehen())
	var tag := int(z.get("day", 1))
	_gehoert_tag = tag
	var wer := String(TranslationServer.translate("HUBER_NAME"))
	# Kapitel 3: Konrad mit dem Beweis zur Rede stellen (Quest 3.6)
	var story := welt.get_node_or_null("Story")
	if story != null and story.aktiv and story.zustand("3.6") == "offen":
		var rede: Array[String] = []
		for k in ["KONRAD_REDE_1", "KONRAD_REDE_2", "KONRAD_REDE_3"]:
			rede.append(_t(k + a))
		dialog.zeigen(wer, rede, func() -> void: welt.net_story_flag.rpc_id(1, "konrad_zur_rede"))
		return
	# Kapitel 5: Konrad gibt die dritte Rezeptseite heraus (Quest 5.3)
	if story != null and story.aktiv and story.zustand("5.3") == "offen":
		var seite: Array[String] = []
		for k in ["KONRAD_SEITE_1", "KONRAD_SEITE_2", "KONRAD_SEITE_3"]:
			seite.append(_t(k + a))
		dialog.zeigen(wer, seite, func() -> void: welt.net_story_flag.rpc_id(1, "rezeptseite3"))
		return
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
	var duell := get_tree().get_first_node_in_group("wettschleppen")
	if duell and duell.aktiv:
		return
	# Letzter Festtag: Duell um Sepps Ehre anbieten
	if bool(z.get("duell_offen", false)):
		zeilen = [_t("HUBER_DUELL_1" + a), _t("HUBER_DUELL_2" + a), _t("HUBER_DUELL_FRAGE" + a)]
		var duell_wahl: Array[String] = [_t("HUBER_DUELL_JA" + a), _t("HUBER_DUELL_NEIN" + a)]
		dialog.zeigen(wer, zeilen, func(i: int) -> void:
			if i == 0 and welt.has_method("net_duell_start"):
				welt.net_duell_start.rpc_id(1)
			else:
				dialog.zeigen(wer, [_t("HUBER_DUELL_SPAETER" + a)] as Array[String], Callable()), duell_wahl)
		return
	if bool(z.get("duell_gewonnen", false)):
		zeilen = [_t("HUBER_NACH_SIEG" + a)]
	var wette: Dictionary = z.get("huber_wette", {})
	if wette.is_empty() or bool(wette.get("angenommen", false)):
		if not wette.is_empty():
			zeilen.append(_t("HUBER_WETTE_LAEUFT" + a) % Texte.huber_wette_text(wette))
		dialog.zeigen(wer, zeilen, Callable())
		return
	# Quest-Wette (Kapitel 3): gilt automatisch, ohne Ja/Nein
	if bool(wette.get("quest", false)):
		zeilen.append(_t("HUBER_WETTE_QUEST" + a) % [Texte.huber_wette_text(wette), Texte.euro(int(wette.get("einsatz", 0)))])
		if welt.has_method("net_huber_wette"):
			welt.net_huber_wette.rpc_id(1, true)
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

## Beim Wettschleppen (scripts/wettschleppen.gd): rennen bzw. wieder stehen
func rennen(an: bool) -> void:
	_rennt = an
	if _figur == null:
		return
	if an:
		_figur.rennen(1.3)
	else:
		_figur.stehen()

## Konrads Runde durchs Zelt. Er bleibt stehen, solange jemand mit ihm redet oder das Duell läuft.
func _patrouille(delta: float) -> void:
	if runde.is_empty() or _rennt or _figur == null:
		return
	var dialog := get_tree().get_first_node_in_group("dialog")
	if dialog != null and dialog.get("aktiv") == true:
		return
	if _warte > 0.0:
		_warte -= delta
		if _warte <= 0.0:
			_figur.gehen()
		return
	var ziel: Vector3 = runde[_punkt]
	var zu := ziel - position
	zu.y = 0.0
	if zu.length() < 0.1:
		_punkt = (_punkt + 1) % runde.size()
		_warte = pause
		_figur.stehen()
		_blick = rotation.y
		return
	position += zu.normalized() * minf(tempo * delta, zu.length())
	rotation.y = lerp_angle(rotation.y, atan2(zu.x, zu.z), minf(1.0, 6.0 * delta))
	_blick = rotation.y

## Sieht Konrad die Stelle? stufe: 0 ohne Tarnung, 1 Mantel, 2 Komplettset (kleinerer Radius).
## Blickfeld: 70 Grad nach vorn.
func sieht(stelle: Vector3, stufe: int) -> bool:
	var reichweite: float = [16.0, 10.0, 5.0][clampi(stufe, 0, 2)]
	var zu := stelle - global_position
	zu.y = 0.0
	if zu.length() > reichweite:
		return false
	if zu.length() < 1.2:
		return true
	var vorn := global_transform.basis.z
	vorn.y = 0.0
	return rad_to_deg(vorn.normalized().angle_to(zu.normalized())) <= 70.0
