extends Node
## Simuliert Gäste ohne Echtzeit: Wartezeit bis zu den ersten Gästen, Weg vom
## Haupttor zum Platz, Pinkeln und Kotzen — der Dreck darf erst entstehen, wenn
## der Gast angekommen ist. Sichert Spielstände und Einstellungen.
## Aufruf: godot --path . res://tools/sim_gaeste.tscn

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]
const SCHRITT := 0.05

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}
	var _fehler := 0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".simbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".simbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".simbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".simbackup"))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(30)
		var gm := get_tree().current_scene
		gm.net_book_tent.rpc_id(1)
		gm.net_buy_table.rpc_id(1)
		await _frames(5)
		gm.set_process(false)

		print("  -- Tagesbeginn")
		gm._start_shift()
		_check("erste Gäste frühestens nach 45 s", gm._guest_spawn_timer >= 45.0 and gm._guest_spawn_timer <= 75.0,
			"%.1f s" % gm._guest_spawn_timer)

		print("  -- Weg vom Haupttor")
		var vorher: Array = gm._guest_sim.keys()
		gm._spawn_guest()
		var id: int = -1
		for k in gm._guest_sim.keys():
			if not vorher.has(k):
				id = k
		_check("Gast erschienen", id >= 0, "")
		if id < 0:
			_ende()
			return
		var g: Dictionary = gm._guest_sim[id]
		_check("startet am Haupttor", (g.pos as Vector3).distance_to(gm.HAUPTTOR) < 2.5, str(g.pos))
		var am_weg := false
		var zeit := 0.0
		while int(g.mode) == 0 and zeit < 120.0:
			gm._update_guests(SCHRITT)
			zeit += SCHRITT
			if not gm._guest_sim.has(id):
				break
			g = gm._guest_sim[id]
			if absf((g.pos as Vector3).z - 19.0) < 0.3 and absf((g.pos as Vector3).x) < 0.5:
				am_weg = true
		_check("läuft über den Weg (0 | 19)", am_weg, "")
		_check("sitzt nach %.0f s am Platz" % zeit, gm._guest_sim.has(id) and int(g.mode) == 1
			and (g.pos as Vector3).distance_to(gm._seats[int(g.seat)].pos) < 0.3, str(g.pos))

		print("  -- Pinkeln ohne Klo")
		gm._has_toilet = false
		g.bladder = 0.0
		g.patience = 9999.0
		var urin0: int = gm._urin_count
		gm._update_guests(SCHRITT)
		_check("beim Losgehen noch keine Pfütze", gm._urin_count == urin0, str(gm._urin_count - urin0))
		var abstand_bei_pfuetze := -1.0
		zeit = 0.0
		while gm._guest_sim.has(id) and int(g.mode) == 3 and zeit < 60.0:
			gm._update_guests(SCHRITT)
			zeit += SCHRITT
			if abstand_bei_pfuetze < 0.0 and gm._urin_count > urin0:
				var d: Vector3 = (g.tgt as Vector3) - (g.pos as Vector3)
				d.y = 0.0
				abstand_bei_pfuetze = d.length()
		_check("Pfütze erst am Ziel", abstand_bei_pfuetze >= 0.0 and abstand_bei_pfuetze < 0.4, "%.2f m" % abstand_bei_pfuetze)
		_check("genau eine Pfütze", gm._urin_count == urin0 + 1, str(gm._urin_count - urin0))

		print("  -- Kotzen")
		# zurück an den Platz laufen lassen
		zeit = 0.0
		while gm._guest_sim.has(id) and (g.pos as Vector3).distance_to(gm._seats[int(g.seat)].pos) > 0.3 and zeit < 60.0:
			gm._update_guests(SCHRITT)
			zeit += SCHRITT
		g.mode = 4
		g.ostate = 0
		g.puked = false
		g.kotzt = false
		g.tgt = (gm._seats[int(g.seat)].pos as Vector3) + Vector3(0, 0, 3.2)
		var abstand_bei_kotze := -1.0
		zeit = 0.0
		while gm._guest_sim.has(id) and int(g.mode) == 4 and zeit < 60.0:
			gm._update_guests(SCHRITT)
			zeit += SCHRITT
			if abstand_bei_kotze < 0.0 and bool(g.puked):
				var d: Vector3 = (g.tgt as Vector3) - (g.pos as Vector3)
				d.y = 0.0
				abstand_bei_kotze = d.length()
		_check("Kotze erst am Ziel", abstand_bei_kotze >= 0.0 and abstand_bei_kotze < 0.3, "%.2f m" % abstand_bei_kotze)

		print("  -- Heimweg")
		gm._end_shift(2)
		zeit = 0.0
		var am_tor := false
		while gm._guest_sim.has(id) and zeit < 120.0:
			var p: Vector3 = gm._guest_sim[id].pos
			if p.distance_to(Vector3(6.8, 0.1, 25.5)) < 0.6:
				am_tor = true
			gm._update_guests(SCHRITT)
			zeit += SCHRITT
		_check("verlässt die Wiesn durchs Haupttor", am_tor and not gm._guest_sim.has(id), "%.0f s" % zeit)
		_ende()

	func _ende() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".simbackup", echt)
				DirAccess.remove_absolute(echt + ".simbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("ERGEBNIS: %s (%d Fehler)" % ["BESTANDEN" if _fehler == 0 else "FEHLGESCHLAGEN", _fehler])
		get_tree().quit(1 if _fehler > 0 else 0)

	func _check(name: String, ok: bool, info: String) -> void:
		if not ok:
			_fehler += 1
		print("  [%s] %s  %s" % ["OK  " if ok else "FEHL", name, info])

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame
