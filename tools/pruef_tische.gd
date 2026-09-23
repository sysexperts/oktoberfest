extends Node
## Prüft die Tischaufstellung im geladenen Spielstand: wie viele Tische aktiv
## sind, welche zu dicht beieinander stehen (Mindestabstand) und welche in einer
## Sperrzone liegen. Findet Aufstellungen, in denen man sich nicht mehr bewegen
## kann.
## Aufruf: godot --headless --path . res://tools/pruef_tische.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		Net.start_solo(true)
		for i in 9000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		for i in 60:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		# Knoten direkt aus der Szene, nicht aus _beertables — genau da war der
		# Unterschied: nicht registrierte Tische fallen sonst durch.
		var tische: Array = []
		for t in gm.get_node("Tables").get_children():
			tische.append(t)
		print("Zeltstufe %d · aktive Tische %d · Tischknoten %d"
			% [gm._tent_stage, gm._active_count, tische.size()])
		print("--- Knoten in Tables ---")
		for t: Node3D in tische:
			var k := t.get_node_or_null("Kollision") as CollisionShape3D
			print("  %s  sichtbar=%s  kollision=%s  bei %.1f/%.1f"
				% [t.name, t.visible, "an" if (k != null and not k.disabled) else "aus",
					t.position.x, t.position.z])
		var aktiv := 0
		var sichtbar_mit_kollision := 0
		for i in tische.size():
			var t: Node3D = tische[i]
			var an: bool = i < gm._active_count
			if an:
				aktiv += 1
			var kol := t.get_node_or_null("Kollision") as CollisionShape3D
			var kol_an := kol != null and not kol.disabled
			if kol_an and not t.visible:
				sichtbar_mit_kollision += 1
				print("  UNSICHTBAR MIT KOLLISION: %s bei %.1f/%.1f (aktiv=%s)"
					% [t.name, t.position.x, t.position.z, an])
		print("unsichtbar aber mit Kollision: %d" % sichtbar_mit_kollision)
		print("--- zu dicht beieinander (unter %.1f m) ---" % gm.TISCH_MINDESTABSTAND)
		var eng := 0
		for i in tische.size():
			for j in range(i + 1, tische.size()):
				var a: Node3D = tische[i]
				var b: Node3D = tische[j]
				if not a.visible or not b.visible:
					continue
				var d := Vector2(a.position.x - b.position.x, a.position.z - b.position.z).length()
				if d < gm.TISCH_MINDESTABSTAND - 0.05:
					eng += 1
					print("  %s und %s nur %.2f m (%.1f/%.1f und %.1f/%.1f)"
						% [a.name, b.name, d, a.position.x, a.position.z, b.position.x, b.position.z])
		print("zu dichte Paare: %d" % eng)
		print("--- in einer Sperrzone ---")
		for i in tische.size():
			var t2: Node3D = tische[i]
			if not t2.visible:
				continue
			for sperre: Array in gm.TISCH_SPERREN:
				var m: Vector2 = sperre[0]
				var h: Vector2 = sperre[1]
				if absf(t2.position.x - m.x) < h.x and absf(t2.position.z - m.y) < h.y:
					print("  %s bei %.1f/%.1f in Sperre um %.1f/%.1f"
						% [t2.name, t2.position.x, t2.position.z, m.x, m.y])
		get_tree().quit()
