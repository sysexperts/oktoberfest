extends Node
## Baut einen Spielstand zum Fotografieren: großes Zelt, 24 Tische, viel Personal,
## alle Lizenzen, Klo, Deko, volles Lager und reichlich Geld.
##
##   bash tools/screenshot_stand.sh [platz]      (Platz 1..3, Vorgabe 3)
##
## Ein vorhandener Stand auf dem Platz wird vorher nach slot_N.json.vorher
## gesichert. Die anderen Plätze bleiben unangetastet.
##
## Was NICHT im Spielstand steht: die Gäste. Die kommen erst, wenn du im Spiel
## das Zelt aufsperrst — bei 100 % Beliebtheit füllt es sich sofort.

const GELD := 250000
const TAG := 14

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var gm: Node
	var platz := 3

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for a in OS.get_cmdline_user_args():
			if a.is_valid_int():
				platz = clampi(int(a), 1, 3)
		await _spiel_starten()
		_alten_stand_sichern()
		_aufbauen()
		await _frames(30)
		gm._save_game()
		print("STAND FERTIG: Platz %d -> %s" % [platz, ProjectSettings.globalize_path(Net.speicherstand_pfad(platz))])
		get_tree().quit()

	## Direkt in die Spielszene — Net.start_solo ginge über den Ladebildschirm.
	func _spiel_starten() -> void:
		Net.solo = true
		Net.neues_spiel = true
		Net.slot = platz
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		get_tree().change_scene_to_file(Net.GAME_SCENE)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		gm = get_tree().current_scene
		if gm == null or not gm.has_method("net_book_tent"):
			push_error("Spielszene kam nicht hoch.")
			get_tree().quit(1)
			return
		await _frames(30)

	func _alten_stand_sichern() -> void:
		var pfad := Net.speicherstand_pfad(platz)
		if not FileAccess.file_exists(pfad):
			return
		var echt := ProjectSettings.globalize_path(pfad)
		# Mit Zeitstempel sichern: eine feste Endung würde beim zweiten Lauf die
		# Sicherung des ersten überschreiben — dann wäre der echte Stand weg.
		var ziel := "%s.vorher_%d" % [echt, Time.get_unix_time_from_system()]
		DirAccess.copy_absolute(echt, ziel)
		print("Alter Stand gesichert: %s" % ziel)

	func _aufbauen() -> void:
		Game.add_money(GELD - Game.money)
		gm._day = TAG
		gm._shift_num = TAG
		gm._popularity = 100.0
		gm._hygiene = 100.0
		# Tutorial und Wiesnchef-Folge sind durch
		gm._quest_step = 99
		gm._folge_geschafft = true
		# Zelt: größte Stufe, alle Tische
		gm._tent_stage = 4
		gm._active_count = 24
		gm._zelt_name = "Zum Durstigen Hirsch"
		gm._apply_tent()
		gm._rebuild_seats()
		gm._has_toilet = true
		# Alles freigeschaltet, was man ausschenken und kochen kann
		for k in gm.LIC_COST.keys():
			gm._lic[k] = true
		gm._upg_marketing = 5
		gm._upg_deko = 5
		gm._ever_artist = true
		gm._artist_tier = 3
		# Lager voll, damit die Schicht nicht nach fünf Minuten leer läuft
		gm._stock[gm.WARE_BIER] = 600
		gm._stock[gm.WARE_ESSEN] = 400
		gm._lager_gekauft = gm.LAGERREGAL_PLAETZE.size()
		gm._kredit_rest = 0
		_personal()
		_deko()

	## Volle Besetzung: je Rolle mehrere Leute auf höchster Stufe.
	func _personal() -> void:
		var wunsch := {gm.ROLE_KOCH: 4, gm.ROLE_KELLNER: 8, gm.ROLE_REINIGUNG: 4, gm.ROLE_ZAPFER: 4}
		for rolle: int in wunsch:
			for i in int(wunsch[rolle]):
				gm._restore_staff(rolle, gm.STAFF_MAX_LEVEL)

	func _deko() -> void:
		var arten := ["lichtergirlande", "lichtergirlande", "kronleuchter", "kronleuchter",
			"kronleuchter", "banner", "riesenbrezel", "haengelaterne", "haengelaterne"]
		var orte := [Vector2(-5.0, 1.0), Vector2(5.0, 1.0), Vector2(-6.0, -3.0), Vector2(0.0, -3.0),
			Vector2(6.0, -3.0), Vector2(-11.6, -2.0), Vector2(11.6, -6.0),
			Vector2(-3.0, 5.0), Vector2(3.0, 5.0)]
		var nr := 800
		for k in arten.size():
			var ort: Vector2 = orte[k]
			var lage: Dictionary = gm._deko_platz(arten[k], ort.x, ort.y, 0.0)
			nr += 1
			# _add_einrichtung stellt das Stück nur hin — gespeichert wird _einrichtung
			gm._einrichtung[nr] = {"art": arten[k], "x": float(lage.x), "z": float(lage.z),
				"rot": float(lage.rot)}
			gm._add_einrichtung(nr, arten[k], float(lage.x), float(lage.z), float(lage.rot))
			if gm._einrichtung.size() >= gm.DEKO_MAX:
				break

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
