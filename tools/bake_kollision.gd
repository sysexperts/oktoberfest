extends SceneTree
## Gibt den Gegenständen im Spiel eine Kollision: Bierzeltgarnituren, Mülltonne
## und alles aus scenes/einrichtung (das, was im Baumodus hingestellt wird).
##
## Warum als Werkzeug und nicht zur Laufzeit: die Kollision soll als echter
## Knoten in der Szene stehen, damit man sie im Editor sieht und anpassen kann.
## Der Kasten kommt aus den Maßen der sichtbaren Meshes, etwas kleiner als das
## Modell — sonst bleibt man an jeder Deko hängen.
##
## Aufruf: godot --headless --path . --script res://tools/bake_kollision.gd
## Nochmal aufrufen ist gefahrlos: vorhandene Kollision wird ersetzt.

const ORDNER := "res://scenes/einrichtung"
const EINZELN := ["res://scenes/beer_table.tscn", "res://scenes/muellplatz.tscn"]
## So viel kleiner als das Modell (damit man nicht an Kanten hängen bleibt)
const SCHRUMPF := 0.9
## Flacher als das: keine Kollision (Teppiche, Banner am Boden)
const MIN_HOEHE := 0.25
## Hängt es über Kopfhöhe (Kronleuchter, Lichterkette)? Dann keine Kollision —
## da läuft niemand dagegen, es würde nur im Weg stehen.
const HAENGT_AB := 1.9
## Hängendes und Flaches an der Wand: dagegen läuft niemand, ein Kasten dort
## wäre nur eine unsichtbare Wand mitten im Zelt.
const OHNE_KOLLISION := ["lichterkette.tscn", "lichtergirlande.tscn", "wimpel.tscn",
	"kronleuchter.tscn", "haengelaterne.tscn", "banner.tscn", "plakat.tscn", "wanduhr.tscn",
	"hopfen.tscn", "teppich.tscn"]
const KNOTEN := "Kollision"

func _init() -> void:
	var dateien: Array[String] = []
	var d := DirAccess.open(ORDNER)
	if d:
		for f in d.get_files():
			if f.ends_with(".tscn"):
				dateien.append("%s/%s" % [ORDNER, f])
	dateien.append_array(EINZELN)
	var gebaut := 0
	for pfad in dateien:
		if _kollision_bauen(pfad):
			gebaut += 1
	print("Kollision gebaut: %d von %d Szenen" % [gebaut, dateien.size()])
	quit()

func _kollision_bauen(pfad: String) -> bool:
	var szene := load(pfad) as PackedScene
	if szene == null:
		print("  %s: nicht ladbar" % pfad)
		return false
	if pfad.get_file() in OHNE_KOLLISION:
		print("  %s: hängt oder liegt flach — keine Kollision" % pfad.get_file())
		return false
	var wurzel: Node = szene.instantiate()
	# Schon vorhandene eigene Kollision weg — sonst wächst sie bei jedem Lauf
	var alt := wurzel.get_node_or_null(KNOTEN)
	if alt:
		wurzel.remove_child(alt)
		alt.free()
	var kasten := _masse(wurzel)
	if kasten.position.y >= HAENGT_AB:
		print("  %s: hängt über Kopfhöhe — keine Kollision" % pfad.get_file())
		wurzel.free()
		return false
	if kasten.size == Vector3.ZERO or kasten.size.y < MIN_HOEHE:
		print("  %s: zu flach oder ohne Mesh — keine Kollision" % pfad.get_file())
		wurzel.free()
		return false
	var koerper := StaticBody3D.new()
	koerper.name = KNOTEN
	var form := CollisionShape3D.new()
	form.name = "Form"
	var box := BoxShape3D.new()
	# Breite und Tiefe schrumpfen, Höhe bleibt — sonst schwebt der Kasten
	box.size = Vector3(maxf(kasten.size.x * SCHRUMPF, 0.1), kasten.size.y,
		maxf(kasten.size.z * SCHRUMPF, 0.1))
	form.shape = box
	form.position = kasten.get_center()
	koerper.add_child(form)
	wurzel.add_child(koerper)
	koerper.owner = wurzel
	form.owner = wurzel
	var neu := PackedScene.new()
	if neu.pack(wurzel) != OK:
		print("  %s: packen ging schief" % pfad.get_file())
		wurzel.free()
		return false
	var fehler := ResourceSaver.save(neu, pfad)
	print("  %s: %.2f × %.2f × %.2f m%s" % [pfad.get_file(), box.size.x, box.size.y, box.size.z,
		"" if fehler == OK else " (Fehler %d)" % fehler])
	wurzel.free()
	return fehler == OK

## Maße aller sichtbaren Meshes, im Raum der Wurzel.
func _masse(wurzel: Node) -> AABB:
	var gesamt := AABB()
	var erstes := true
	for mi: MeshInstance3D in wurzel.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or not mi.visible:
			continue
		var lokal := mi.get_aabb()
		# Von der Mesh-Lage in die Lage der Wurzel rechnen. Die Szene hängt hier
		# nicht im Baum, global_transform gäbe also nur die Einheitsmatrix —
		# darum die Kette der Eltern selbst hochlaufen.
		var kasten := _relativ(wurzel, mi) * lokal
		if erstes:
			gesamt = kasten
			erstes = false
		else:
			gesamt = gesamt.merge(kasten)
	return gesamt

## Lage eines Knotens im Raum der Wurzel — ohne Szenenbaum.
func _relativ(wurzel: Node, knoten: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = knoten
	while n != null and n != wurzel:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t
