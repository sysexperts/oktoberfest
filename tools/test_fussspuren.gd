extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft die Fußspuren: erscheinen im offenen Zelt bei Gästen, lassen sich wischen,
## zeigen den Hinweis und stehen als Bild in tools/fussspuren.png.
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
		# Gäste vortäuschen, Zelt offen: Spuren müssen entstehen, aber höchstens FUSS_MAX
		var echte_gaeste: Dictionary = gm._guest_sim
		gm._guest_sim = {1: {}, 2: {}, 3: {}, 4: {}}
		gm._phase = gm.Phase.SHIFT
		gm._zelt_offen = true
		for i in 40:
			gm._fuss_t = 0.0
			gm._update_fussspuren(0.01)
		var anzahl: int = gm._fuss_anzahl()
		print("Fußspuren nach 40 Versuchen: ", anzahl, " (Höchstzahl ", gm.FUSS_MAX, ")")
		# Bei geschlossenem Zelt oder ohne Gäste kommen keine dazu
		gm._zelt_offen = false
		gm._fuss_t = 0.0
		gm._update_fussspuren(0.01)
		print("bei geschlossenem Zelt unverändert: ", gm._fuss_anzahl() == anzahl)
		gm._guest_sim = echte_gaeste
		await _frames(20)
		# Eine Spur aufsuchen: Hinweis, Bild, wischen
		var spur: Mess = null
		for m in gm._messes.values():
			if m is Mess and m.ist_fuss():
				spur = m
				break
		if spur == null:
			print("keine Spur gefunden")
			return false
		print("Hinweis an der Spur: ", sp._hint_for(spur), " · ist_dreck=", spur.ist_dreck(), " ist_sabotage=", spur.ist_sabotage())
		# Feste Stelle für das Bild: Spur und zum Vergleich ein Dreckhaufen, Kamera von oben
		var punkt := Vector3(0.0, 0.0, 2.5)
		gm._spawn_mess_at(punkt, Mess.FUSS)
		gm._spawn_mess_at(punkt + Vector3(1.3, 0.0, 0.0), Mess.DRECK)
		sp.global_position = punkt + Vector3(0.6, 0.1, 3.5)
		await _frames(10)
		var kamera := Camera3D.new()
		gm.add_child(kamera)
		kamera.global_position = punkt + Vector3(0.7, 1.7, 1.4)
		kamera.look_at(punkt + Vector3(0.6, 0.0, 0.0))
		kamera.current = true
		await _frames(30)
		print("Kamera aktiv: ", get_viewport().get_camera_3d().global_position)
		get_viewport().get_texture().get_image().save_png("res://tools/fussspuren.png")
		var q: MeshInstance3D = spur._fuss
		print("Fuss-Quad: sichtbar=%s in_baum=%s Welt=%s scale=%s mat=%s tex=%s" % [q.visible, q.is_visible_in_tree(), q.global_position, q.global_transform.basis.get_scale(), q.material_override, (q.material_override as StandardMaterial3D).albedo_texture if q.material_override else null])
		print("Mess: ", spur.global_position, " kind=", spur.kind, " Kotze=", spur._kotze.visible, " Disc=", spur._disc.visible)
		var id: int = spur.mess_id
		var vorher: int = gm._fuss_anzahl()
		for i in 120:
			gm.net_clean.rpc_id(1, id)
			await get_tree().process_frame
			if not gm._messes.has(id):
				break
		print("nach dem Wischen: %d -> %d, Spur weg: %s (Schritte %d)" % [vorher, gm._fuss_anzahl(), not gm._messes.has(id), 0])
		return anzahl >= 1 and anzahl <= gm.FUSS_MAX and not gm._messes.has(id) and gm._fuss_anzahl() == vorher - 1

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
