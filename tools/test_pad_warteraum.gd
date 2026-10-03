extends Node
## Steam-Warteraum nur mit Controller: Fokus beim Öffnen, alle Knöpfe per Steuerkreuz
## erreichbar, Bereit/Figurwahl/Weltwahl/Start mit A, B schließt die Fenster und gibt den
## Fokus zurück. Ohne Steam (Ersatz-Quelle wie in render_steam_warteraum).
## Sichert Einstellungen (die Figurwahl wird dort gemerkt) und stellt sie wieder her.
##   godot --path . res://tools/test_pad_warteraum.tscn --resolution 1280x720

const Ersatz := preload("res://tools/render_steam_warteraum.gd").Ersatz
const DATEIEN := ["user://einstellungen.cfg"]

class Quelle extends Ersatz:
	var bereit := false
	var gestartet := false
	func mitglied_setzen(schluessel: String, wert: String) -> void:
		super.mitglied_setzen(schluessel, wert)
		if schluessel == "bereit":
			bereit = wert == "1"
	func lobby_mitglieder() -> Array:
		var l := super.lobby_mitglieder()
		l[0]["bereit"] = bereit
		return l
	func lobby_setzen(schluessel: String, wert: String) -> void:
		super.lobby_setzen(schluessel, wert)
		if schluessel == "start" and wert == "1":
			gestartet = true

var fehler := 0

func _check(n: String, ok: bool, info := "") -> void:
	print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
	if not ok:
		fehler += 1

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _knopf(index: int, unten: bool) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = index
	ev.pressed = unten
	ev.pressure = 1.0 if unten else 0.0
	Input.parse_input_event(ev)

func _tippen(index: int) -> void:
	_knopf(index, true)
	await _frames(4)
	_knopf(index, false)
	await _frames(4)

func _fokus() -> Control:
	return get_viewport().gui_get_focus_owner()

## Alle Bedienelemente, die man vom Fokus aus mit dem Steuerkreuz erreicht
func _erreichbar(start: Control) -> Array:
	var gesehen: Array = [start]
	var offen: Array = [start]
	while not offen.is_empty():
		var c: Control = offen.pop_back()
		for seite in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			var n := c.find_valid_focus_neighbor(seite)
			if n != null and not gesehen.has(n):
				gesehen.append(n)
				offen.append(n)
	return gesehen

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var gab_es := FileAccess.file_exists(DATEIEN[0])
	if gab_es:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(DATEIEN[0]), ProjectSettings.globalize_path(DATEIEN[0] + ".testbackup"))
	await _pruefen()
	var echt := ProjectSettings.globalize_path(DATEIEN[0])
	if gab_es:
		DirAccess.copy_absolute(echt + ".testbackup", echt)
		DirAccess.remove_absolute(echt + ".testbackup")
	elif FileAccess.file_exists(DATEIEN[0]):
		DirAccess.remove_absolute(echt)
	print("ERGEBNIS: ", "BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
	get_tree().quit(0 if fehler == 0 else 1)

func _pruefen() -> void:
	var quelle := Quelle.new()
	var raum := (load("res://scenes/ui/steam_warteraum.tscn") as PackedScene).instantiate()
	raum.quelle = quelle
	add_child(raum)
	await _frames(60)
	# Der Controller ist aktiv (Fokus ohne Zeiger)
	Einstellungen.am_pad = true

	print("-- Fokus und Erreichbarkeit")
	var start := _fokus()
	_check("Beim Öffnen ist etwas angewählt", start != null)
	if start == null:
		return
	var alle := _erreichbar(start)
	for n: String in ["Bereit", "Los", "Verlassen", "WeltAendern", "Kopieren"]:
		var k: Control = raum.get_node("%" + n)
		if k.visible:
			_check("%s per Steuerkreuz erreichbar" % n, alle.has(k))
	_check("Figur-wählen-Knopf der eigenen Karte erreichbar", alle.any(func(c): return c is Button and c.get_parent().name == "Spieler" or String(c.name).contains("Waehlen")))

	print("-- Bereit mit A")
	raum.get_node("%Bereit").grab_focus()
	await _frames(3)
	await _tippen(JOY_BUTTON_A)
	_check("A setzt Bereit", quelle.bereit)
	await _tippen(JOY_BUTTON_A)
	_check("A nimmt Bereit zurück", not quelle.bereit)

	print("-- Figurwahl")
	raum.get_node("%Wahl").zeigen(0, {})
	await _frames(10)
	_check("Wahl-Fenster hat Fokus", _fokus() != null and raum.get_node("%Wahl").is_ancestor_of(_fokus()))
	await _tippen(JOY_BUTTON_DPAD_RIGHT)
	await _tippen(JOY_BUTTON_A)
	_check("A wählt Figur 1", quelle.figuren.get(1, -1) == 1, str(quelle.figuren.get(1, -1)))
	await _tippen(JOY_BUTTON_B)
	await _frames(5)
	_check("B schließt die Wahl", not raum.get_node("%Wahl").visible)
	_check("Fokus zurück auf Bereit", _fokus() == raum.get_node("%Bereit"))

	print("-- Weltwahl")
	raum.get_node("%WeltAendern").grab_focus()
	await _frames(3)
	await _tippen(JOY_BUTTON_A)
	await _frames(15)
	var welt: Control = raum.get_node("%Welt")
	_check("A öffnet die Weltwahl", welt.visible)
	_check("Weltwahl hat Fokus", _fokus() != null and welt.is_ancestor_of(_fokus()))
	await _tippen(JOY_BUTTON_B)
	await _frames(5)
	_check("B schließt die Weltwahl", not welt.visible)
	_check("Fokus zurück auf Welt ändern", _fokus() == raum.get_node("%WeltAendern"))
