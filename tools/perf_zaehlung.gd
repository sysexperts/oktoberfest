extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Wie viele Figuren gibt es, nach Art? (Skelette je oberstem Eintrag der Karte bzw. der Welt)
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._day = 5
		gm._apply_crowd(14.0)
		await get_tree().create_timer(30.0).timeout
		var je := {}
		var karte := gm.get_node("Kirmes/Karte")
		for s in gm.find_children("*", "Skeleton3D", true, false):
			var q: Node = s
			var art := ""
			while q != null and q != gm:
				if q.get_parent() == karte:
					art = "Karte/" + (q.scene_file_path.get_file() if q.scene_file_path != "" else str(q.name))
					break
				if q.is_in_group("visitor"):
					art = "Besucher"
					break
				if q.get_parent() == gm:
					art = "Welt/" + str(q.name)
					break
				q = q.get_parent()
			je[art] = int(je.get(art, 0)) + 1
		var sortiert := je.keys()
		sortiert.sort_custom(func(a, b): return je[a] > je[b])
		for k in sortiert:
			print("ZAEHL %4d  %s" % [je[k], k])
		print("ZAEHL Besucher-Ziel: ", gm._crowd._target, " max ", gm._crowd.max_visitors)
		get_tree().quit()
