extends Node
## Test für Phase 1: Solo-Start, Spieleraktionen, Pausemenü, Tastenbelegung.
## Sichert vorher Spielstand UND Einstellungen und stellt beide am Ende wieder
## her — der Test verändert nichts an deinem echten Stand.
## Aufruf: godot --headless --path . res://tools/test_phase1.tscn

const DATEIEN := ["user://oktoberfest_save.json", "user://einstellungen.cfg"]

func _ready() -> void:
	# Der Szenenwechsel würde diesen Knoten freigeben — Testlauf an die Wurzel hängen.
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var fehler := 0
	## Pfad -> ob es die Datei vor dem Test gab
	var _gab_es := {}

	func _ready() -> void:
		# Muss auch weiterlaufen, während das Pausemenü den Baum anhält.
		process_mode = Node.PROCESS_MODE_ALWAYS
		_sichern()
		get_tree().create_timer(60.0).timeout.connect(_abbruch)
		Net.start_solo(true)
		await _frames(40)
		await _pruefen()
		_wiederherstellen()
		print("ERGEBNIS: %s (%d Fehler)" % ["BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN", fehler])
		get_tree().quit(0 if fehler == 0 else 1)

	func _pruefen() -> void:
		var gm := get_tree().current_scene
		_check("Spielszene geladen", gm != null and gm.has_method("net_book_tent"), str(gm))
		if gm == null or not gm.has_method("net_book_tent"):
			return
		_check("Offline-Peer aktiv", multiplayer.multiplayer_peer is OfflineMultiplayerPeer,
			multiplayer.multiplayer_peer.get_class())
		_check("Spieler gespawnt", gm.get_node("Players").get_child_count() >= 1, "")
		_check("Startgeld 1200", Game.money == 1200, "Geld=%d" % Game.money)

		print("  -- Spieleraktionen")
		var stufe0: int = gm.get("_tent_stage")
		gm.net_book_tent.rpc_id(1)
		await _frames(5)
		_check("Zelt mieten kommt an", gm.get("_tent_stage") == stufe0 + 1, "")
		var tische0: int = gm.get("_active_count")
		gm.net_buy_table.rpc_id(1)
		await _frames(5)
		_check("Tisch kaufen kommt an", gm.get("_active_count") == tische0 + 1, "")

		print("  -- Hinweis am Fadenkreuz (2.2)")
		var spieler := gm.get_node("Players").get_child(0)
		var zapfhahn := gm.get_node("Stations/MugDispenser")
		var fass := gm.get_node("Stations/Keg1")
		spieler.carry_state = 0
		_check("Krugspender, Hände leer", spieler._hint_for(zapfhahn) == "HINT_TAKE_MUG", spieler._hint_for(zapfhahn))
		_check("Fass, Hände leer", spieler._hint_for(fass) == "HINT_NEED_MUG", spieler._hint_for(fass))
		spieler.carry_state = 1
		spieler.carry_fill = 0.2
		_check("Fass mit halbem Krug", spieler._hint_for(fass) == "HINT_TAP", spieler._hint_for(fass))
		_check("Krugspender mit Krug: nichts", spieler._hint_for(zapfhahn) == "", spieler._hint_for(zapfhahn))
		spieler.carry_state = 0
		spieler.carry_fill = 0.0
		var hud := gm.get_node("HUD")
		Einstellungen.sprache = "de"
		Einstellungen.anwenden()
		hud.set_hint("HINT_TAKE_MUG")
		var hinweis: String = hud.get_node("%HinweisText").text
		_check("Hinweistext mit Taste", hinweis == "[E] Krug nehmen" and hud.get_node("%Hinweis").visible, hinweis)
		hud.set_hint("")
		_check("Hinweis ausgeblendet", not hud.get_node("%Hinweis").visible, "")

		print("  -- Pausemenü")
		var pause := gm.get_node_or_null("PauseMenu")
		_check("Pausemenü in der Szene", pause != null and pause.has_method("oeffnen"), str(pause))
		if pause:
			_check("anfangs geschlossen", not pause.visible, "")
			pause.oeffnen()
			await _frames(3)
			_check("sichtbar nach Öffnen", pause.visible, "")
			_check("Solo: Zeit angehalten", get_tree().paused, "")
			pause.schliessen()
			await _frames(3)
			_check("Fortsetzen: Pause aufgehoben", not get_tree().paused, "")
			_check("wieder unsichtbar", not pause.visible, "")

		print("  -- Tastenbelegung")
		_check("Standard: Benutzen auf E", _taste("interact") == KEY_E, OS.get_keycode_string(_taste("interact")))
		Einstellungen.setze_taste("interact", KEY_F)
		_check("umbelegt auf F", _taste("interact") == KEY_F, OS.get_keycode_string(_taste("interact")))
		_check("Anzeigename F", Einstellungen.tasten_name("interact") == "F", Einstellungen.tasten_name("interact"))
		Einstellungen.tasten_zuruecksetzen()
		_check("zurückgesetzt auf E", _taste("interact") == KEY_E, OS.get_keycode_string(_taste("interact")))
		_check("Prost-Aktion existiert", InputMap.has_action("emote") and _taste("emote") == KEY_Q, "")

		print("  -- Sprache")
		for lang in ["de", "en", "tr"]:
			Einstellungen.sprache = lang
			Einstellungen.anwenden()
			var t := tr("MENU_NEW_GAME")
			_check("%s übersetzt" % lang, t != "MENU_NEW_GAME", t)

	func _taste(aktion: String) -> int:
		for ev in InputMap.action_get_events(aktion):
			if ev is InputEventKey:
				return (ev as InputEventKey).physical_keycode
		return KEY_NONE

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame

	func _check(name: String, ok: bool, info: String) -> void:
		if not ok:
			fehler += 1
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", name, info])

	func _sichern() -> void:
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad),
					ProjectSettings.globalize_path(pfad + ".testbackup"))
		print("  gesichert: ", _gab_es)

	func _wiederherstellen() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			var backup := echt + ".testbackup"
			if _gab_es.get(pfad, false):
				DirAccess.copy_absolute(backup, echt)
				DirAccess.remove_absolute(backup)
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("  wiederhergestellt")

	func _abbruch() -> void:
		print("ERGEBNIS: ABBRUCH nach Zeitlimit")
		_wiederherstellen()
		get_tree().quit(2)
