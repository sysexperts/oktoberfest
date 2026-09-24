extends Node
const Texte := preload("res://scripts/ui/texte.gd")
## Gamepad-Belegung prüfen (Steam Deck): Liegt auf jeder Spielaktion auch ein
## Knopf oder eine Stickachse? Stimmen die Totzonen? Bleibt die Tastatur heil,
## wenn jemand eine Taste umbelegt?
##
##   Godot.exe --headless --path . res://tools/test_pad.tscn
##
## Ohne angeschlossenen Controller prüfbar: getestet wird die Zuordnung, nicht
## das Gerät. Ob sich der Blick am Stick gut anfühlt, sagt nur ein echtes Deck.

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var fehler := 0

	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1

	## Hat die Aktion ein Ereignis dieser Art?
	func _hat(aktion: String, typ) -> bool:
		if not InputMap.has_action(aktion):
			return false
		for ev in InputMap.action_get_events(aktion):
			if is_instance_of(ev, typ):
				return true
		return false

	func _ready() -> void:
		print("-- Gamepad-Belegung")
		Einstellungen.anwenden()
		for aktion: String in Einstellungen.PAD_KNOEPFE:
			_check("%s hat einen Knopf" % aktion, _hat(aktion, InputEventJoypadButton))
		for aktion: String in Einstellungen.PAD_ACHSEN:
			_check("%s hat eine Stickachse" % aktion, _hat(aktion, InputEventJoypadMotion))
		for aktion: String in Einstellungen.BLICK_ACHSEN:
			_check("%s vorhanden" % aktion, _hat(aktion, InputEventJoypadMotion))

		print("-- Tastatur bleibt")
		for aktion: String in Einstellungen.PAD_KNOEPFE:
			_check("%s hat weiterhin eine Taste" % aktion, _hat(aktion, InputEventKey))

		print("-- Totzonen")
		for aktion: String in Einstellungen.PAD_ACHSEN:
			var tz := InputMap.action_get_deadzone(aktion)
			_check("%s Totzone %.2f" % [aktion, tz], is_equal_approx(tz, Einstellungen.STICK_TOTZONE))

		print("-- Doppelbelegung")
		var belegt := {}
		var doppelt := ""
		for aktion: String in Einstellungen.PAD_KNOEPFE:
			var knopf: int = Einstellungen.PAD_KNOEPFE[aktion]
			if belegt.has(knopf):
				doppelt += "%s=%s " % [aktion, belegt[knopf]]
			belegt[knopf] = aktion
		_check("kein Knopf doppelt belegt", doppelt == "", doppelt)

		print("-- Umbelegen zerstört das Gamepad nicht")
		Einstellungen.setze_taste("interact", KEY_F)
		_check("interact: Taste F", Einstellungen.taste("interact") == KEY_F)
		_check("interact: Knopf bleibt", _hat("interact", InputEventJoypadButton))
		Einstellungen.tasten_zuruecksetzen()
		_check("zurückgesetzt auf E", Einstellungen.taste("interact") == KEY_E)
		_check("Knopf immer noch da", _hat("interact", InputEventJoypadButton))

		print("-- Hinweistexte")
		Einstellungen.am_pad = false
		_check("Tastatur: interact zeigt E", Einstellungen.anzeige_name("interact") == "E",
			Einstellungen.anzeige_name("interact"))
		Einstellungen.am_pad = true
		_check("Gamepad: interact zeigt A", Einstellungen.anzeige_name("interact") == "A",
			Einstellungen.anzeige_name("interact"))
		var satz := Texte.mit_tasten("HUD_HELP_HINT")
		_check("Hinweissatz nutzt Knopfnamen", not satz.contains("[F1]"), satz)
		Einstellungen.am_pad = false
		_check("Belegungsmenü zeigt weiter die Taste", Einstellungen.tasten_name("interact") == "E")

		print("-- Menüführung")
		for aktion in ["ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right"]:
			_check("%s am Gamepad" % aktion, _hat(aktion, InputEventJoypadButton) \
				or _hat(aktion, InputEventJoypadMotion))

		print("ERGEBNIS: ", "BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(1 if fehler > 0 else 0)
