extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft die Spielerliste (Tab halten): erscheint, zeigt den Spieler, verschwindet beim Loslassen.
## wie beim Start aus dem Steam-Warteraum (Net.solo = false, KoopDaten.lobby_wahl).

const KoopDaten := preload("res://scripts/koop_daten.gd")
const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	const KoopDaten := preload("res://scripts/koop_daten.gd")
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".testbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".testbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".testbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".testbackup"))
		var ok := await _pruefen()
		_wiederherstellen()
		print("TEST ", "BESTANDEN" if ok else "FEHLGESCHLAGEN")
		get_tree().quit(0 if ok else 1)

	func _pruefen() -> bool:
		Net.solo = false
		Net.neues_spiel = true
		Net.slot = 2
		KoopDaten.lobby_wahl = {"name": "Test", "figur": int(OS.get_environment("FIG") if OS.get_environment("FIG") != "" else "12"), "id": ""}
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		get_tree().change_scene_to_file(Net.GAME_SCENE)
		var ende := Time.get_ticks_msec() + 120000
		var gm: Node = null
		while Time.get_ticks_msec() < ende:
			var sz := get_tree().current_scene
			if sz != null and sz.has_method("net_book_tent"):
				gm = sz
				break
			await get_tree().process_frame
		if gm == null:
			return false
		for i in 120:
			await get_tree().process_frame
		var hud: Node = gm.get_node("HUD")
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		hud.melde("MSG_GOODS_ORDERED", [1, "GOODS_BEER", {"euro": 40}], 2)
		hud.melde("MSG_RAUSCH")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_TAB
		ev.pressed = true
		Input.parse_input_event(ev)
		for i in 20:
			await get_tree().process_frame
		var liste: Control = hud.get_node("%Spielerliste")
		print("Liste sichtbar: ", liste.visible, " Zeilen: ", liste.get_node("%Liste").get_child_count())
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/spielerliste.png"))
		print("Ereignisse: ", liste.get_node("%Ereignisse").get_child_count())
		var ok := liste.visible and liste.get_node("%Liste").get_child_count() == 1 and liste.get_node("%Ereignisse").get_child_count() == 2
		ev = ev.duplicate()
		ev.pressed = false
		Input.parse_input_event(ev)
		for i in 10:
			await get_tree().process_frame
		print("nach Loslassen sichtbar: ", liste.visible)
		# Neuer Tag: Verlauf des Vortags weg
		hud._day = 2
		hud.melde("MSG_RAUSCH")
		print("Verlauf nach Tageswechsel: ", hud.verlauf.size())
		return ok and not liste.visible and hud.verlauf.size() == 1

	func _wiederherstellen() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es.get(pfad, false):
				DirAccess.copy_absolute(echt + ".testbackup", echt)
				DirAccess.remove_absolute(echt + ".testbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
