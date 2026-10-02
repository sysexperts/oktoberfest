extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft, dass kein Fleck (Dreck, Müll, Fußspur) unter einem Tisch landet: Flecken auf Tischmitten
## und Tischkanten werden neben den Tisch geschoben.

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
		var gm := await Spielstart.starten(self, true, 2)
		if gm == null:
			return false
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var fehler := 0
		var geprueft := 0
		for bt in gm._all_tables:
			var t := bt as Node3D
			for kind in [0, 1, 2, 30]:
				for versatz in [Vector3.ZERO, Vector3(0.9, 0, 0.3), Vector3(0, 0, 0.6)]:
					var ziel: Vector3 = t.global_position + versatz
					ziel.y = 0.0
					var p: Vector3 = gm._fleck_neben_tisch(ziel, gm.ebene_von(ziel))
					var lokal := t.global_transform.affine_inverse() * p
					geprueft += 1
					if absf(lokal.x) < gm.TISCH_FLECK_HALB.x + 0.4 and absf(lokal.z) < gm.TISCH_FLECK_HALB.y + 0.4:
						fehler += 1
						if fehler < 5:
							print("Fleck unter Tisch ", t.name, " lokal ", lokal)
		print("Prüfungen ", geprueft, " Fehler ", fehler, " Tische ", gm._all_tables.size())
		return geprueft > 0 and fehler == 0

	func _wiederherstellen() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es.get(pfad, false):
				DirAccess.copy_absolute(echt + ".testbackup", echt)
				DirAccess.remove_absolute(echt + ".testbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
