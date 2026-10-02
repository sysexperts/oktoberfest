extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft die Fußspuren: Im offenen Zelt entsteht ein welliger Weg vom Eingang zu einem
## Tisch (mehrere Stücke), höchstens FUSS_MAX, kein neuer Weg bei geschlossenem Zelt;
## ein Stück zeigt den Hinweis und lässt sich wischen. Bilder: tools/fussspuren.png (von
## oben) und tools/fussspuren_boden.png (aus Augenhöhe).
## Sichert Spielstände und Einstellungen vorher und stellt sie danach wieder her.
##   godot --path . res://tools/test_fussspuren.tscn   (mit Fenster)

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
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
		var sp: Node3D = gm._players_nodes.get(1)
		# Zelt gemietet mit Tischen, damit es Sitzplätze als Ziel gibt
		gm._tent_stage = 1
		gm._rebuild_seats()
		print("Sitzplätze: ", gm._seats.size())
		# Gäste vortäuschen, Zelt offen
		var echte_gaeste: Dictionary = gm._guest_sim
		gm._guest_sim = {1: {}, 2: {}, 3: {}, 4: {}}
		gm._phase = gm.Phase.SHIFT
		gm._zelt_offen = true
		gm._fuss_t = 0.0
		gm._fuss_t = 1000.0
		gm._fuss_pfad_anlegen(Vector3(4.0, 0.0, -2.5))   # fester Weg fürs Bild
		gm._update_fussspuren(0.01)
		gm._guest_sim = echte_gaeste   # die Spielschleife darf mit den vorgetäuschten Gästen nicht weiterlaufen
		var erster: int = gm._fuss_anzahl()
		print("Stücke im ersten Weg: ", erster)
		# Bild nur mit diesem einen Weg, aus dem Zelt von schräg oben
		var oben := Camera3D.new()
		gm.add_child(oben)
		oben.global_position = Vector3(2.0, 6.5, 9.0)
		oben.look_at(Vector3(2.0, 0.0, 5.5))
		oben.current = true
		await _frames(30)
		get_viewport().get_texture().get_image().save_png("res://tools/fussspuren.png")
		oben.queue_free()
		# Aus Augenhöhe am Eingang, den Weg entlang
		sp.global_position = Vector3(0, 0.1, 14.5)
		sp.look_at(Vector3(0, 1.0, 3.0))
		sp._head.rotation.x = -0.45
		sp._cam.current = true
		await _frames(30)
		get_viewport().get_texture().get_image().save_png("res://tools/fussspuren_boden.png")
		# Weitere Wege, bis die Höchstzahl erreicht ist — darüber hinaus darf nichts mehr kommen
		for i in 30:
			gm._fuss_pfad_anlegen()
		var anzahl: int = gm._fuss_anzahl()
		print("Stücke nach 30 weiteren Wegen: ", anzahl, " (Höchstzahl ", gm.FUSS_MAX, ")")
		# Bei geschlossenem Zelt kommt nichts dazu
		gm._zelt_offen = false
		gm._guest_sim = {1: {}}
		gm._fuss_t = 0.0
		gm._update_fussspuren(0.01)
		gm._guest_sim = echte_gaeste
		print("bei geschlossenem Zelt unverändert: ", gm._fuss_anzahl() == anzahl)
		await _frames(20)
		# Ein Stück: Hinweis und Wischen
		var spur: Mess = null
		for m in gm._messes.values():
			if m is Mess and m.ist_fuss():
				spur = m
				break
		if spur == null:
			return false
		print("Hinweis an der Spur: ", sp._hint_for(spur), " · ist_dreck=", spur.ist_dreck(), " ist_sabotage=", spur.ist_sabotage())
		var id: int = spur.mess_id
		var vorher: int = gm._fuss_anzahl()
		for i in 120:
			gm.net_clean.rpc_id(1, id)
			await get_tree().process_frame
			if not gm._messes.has(id):
				break
		print("nach dem Wischen: %d -> %d, Stück weg: %s" % [vorher, gm._fuss_anzahl(), not gm._messes.has(id)])
		return erster >= 3 and anzahl <= gm.FUSS_MAX and anzahl > erster and not gm._messes.has(id) and gm._fuss_anzahl() == vorher - 1

	func _frames(k: int) -> void:
		for i in k:
			await get_tree().process_frame

	func _wiederherstellen() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".testbackup", echt)
				DirAccess.remove_absolute(echt + ".testbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
