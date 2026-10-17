extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Woher kommen die 600+ Lichter? Zählt Light3D nach Art, Schatten, Sichtbarkeit und nach Herkunft (Eltern-Szene/Skript).
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		await get_tree().create_timer(8.0).timeout
		var alle := gm.find_children("*", "Light3D", true, false)
		var art := {}
		var herkunft := {}
		var schatten := 0
		var sichtbar := 0
		var reichweite := 0.0
		for l in alle:
			var k := (l as Node).get_class()
			art[k] = int(art.get(k, 0)) + 1
			if (l as Light3D).shadow_enabled:
				schatten += 1
			if (l as Light3D).is_visible_in_tree():
				sichtbar += 1
			if l is OmniLight3D:
				reichweite += (l as OmniLight3D).omni_range
			var p: Node = l
			var h := ""
			while p != null and p != gm:
				if p.scene_file_path != "" and p != l:
					h = p.scene_file_path
					break
				p = p.get_parent()
			if h == "":
				h = "(eigene Knoten) " + str(l.get_parent().name)
			herkunft[h] = int(herkunft.get(h, 0)) + 1
		print("LICHTER gesamt %d  sichtbar %d  mit Schatten %d  mittlere Omni-Reichweite %.1f" % [alle.size(), sichtbar, schatten, reichweite / maxf(1.0, float(art.get("OmniLight3D", 1)))])
		print("ARTEN ", art)
		var liste := []
		for h in herkunft.keys():
			liste.append([herkunft[h], h])
		liste.sort_custom(func(a, b): return a[0] > b[0])
		for e in liste.slice(0, 18):
			print("  %4d  %s" % [e[0], e[1]])
		get_tree().quit()
