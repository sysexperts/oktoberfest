extends SceneTree
## Gibt den Gegenständen im Spiel eine Kollision — Bierzeltgarnituren, Mülltonne,
## alles aus scenes/einrichtung (Baumodus), die Sachen im Zelt (scenes/zelt),
## Büromöbel und die Bäume.
##
## Die Kollision wird als echter Knoten in die Szenendatei geschrieben, damit man
## sie im Editor sieht und anpassen kann. Geschrieben wird im Szenentext und
## nicht über PackedScene.pack() — beim Packen ist schon einmal das Skript der
## Wurzel verlorengegangen (scenes/ausgabe.tscn).
##
## Nicht dabei: Kirmesbuden und Fahrgeschäfte. Ein Kasten um ihre ganzen Maße
## würde den Platz zumauern, an dem man spielt oder durchläuft — die brauchen
## von Hand gesetzte Formen.
##
## Aufruf: godot --headless --path . --script res://tools/bake_kollision.gd
## Nochmal aufrufen ist gefahrlos: vorhandene Kollision wird ersetzt.

const ORDNER: Array[String] = ["res://scenes/einrichtung", "res://scenes/zelt",
	"res://scenes/moebel", "res://scenes/kulisse"]
const EINZELN := ["res://scenes/beer_table.tscn", "res://scenes/muellplatz.tscn"]
## So viel kleiner als das Modell (damit man nicht an Kanten hängen bleibt)
const SCHRUMPF := 0.9
## Flacher als das: keine Kollision (Teppiche, Banner am Boden)
const MIN_HOEHE := 0.25
## Unterkante höher als das: hängt über Kopfhöhe, da läuft niemand dagegen
const HAENGEND_AB := 1.6
## Dünner als das bei einiger Höhe: flach an der Wand (Fenster, Wappen, Plakate)
const FLACH := 0.18
## Kulisse am Horizont, Straßen, Handgeräte — nie Kollision
const OHNE_KOLLISION := ["lichterkette.tscn", "lichtergirlande.tscn", "wimpel.tscn",
	"kronleuchter.tscn", "haengelaterne.tscn", "banner.tscn", "plakat.tscn", "wanduhr.tscn",
	"hopfen.tscn", "teppich.tscn", "altstadt.tscn", "strassen.tscn", "deckenlampe.tscn",
	"lichterkette_giebel.tscn",
	# Am Giebel und an der Wand: Kranzleuchter, Krone, Wappen, Girlanden, Fenster
	"kranzleuchter.tscn", "krone.tscn", "wappen.tscn", "girlande_2_5.tscn",
	"lambrequin_2.tscn", "fenster.tscn", "wandlaterne.tscn"]
## Bäume: nur der Stamm, nicht die ganze Krone — sonst steht ein unsichtbarer
## Block von sechs Metern um jeden Baum.
const NUR_STAMM := 0.55

const KNOTEN := "Kollision"
const FORM_ID := "KollisionForm"

func _init() -> void:
	var dateien: Array[String] = []
	for ordner: String in ORDNER:
		var d := DirAccess.open(ordner)
		if d == null:
			continue
		for f in d.get_files():
			if f.ends_with(".tscn"):
				dateien.append("%s/%s" % [ordner, f])
	dateien.append_array(EINZELN)
	var gebaut := 0
	for pfad in dateien:
		if _kollision_bauen(pfad):
			gebaut += 1
	print("Kollision gebaut: %d von %d Szenen" % [gebaut, dateien.size()])
	quit()

func _kollision_bauen(pfad: String) -> bool:
	var name := pfad.get_file()
	if name in OHNE_KOLLISION:
		print("  %s: hängt oder liegt flach — keine Kollision" % name)
		return false
	var szene := load(pfad) as PackedScene
	if szene == null:
		print("  %s: nicht ladbar" % name)
		return false
	var wurzel: Node = szene.instantiate()
	var kasten := _masse(wurzel)
	wurzel.free()
	if kasten.size == Vector3.ZERO or kasten.size.y < MIN_HOEHE:
		print("  %s: zu flach oder ohne Mesh — keine Kollision" % name)
		return false
	if kasten.position.y >= HAENGEND_AB:
		print("  %s: hängt über Kopfhöhe — keine Kollision" % name)
		return false
	if minf(kasten.size.x, kasten.size.z) < FLACH and kasten.size.y > 0.5:
		print("  %s: flach an der Wand — keine Kollision" % name)
		return false
	var groesse := Vector3(maxf(kasten.size.x * SCHRUMPF, 0.1), kasten.size.y,
		maxf(kasten.size.z * SCHRUMPF, 0.1))
	var mitte := kasten.get_center()
	if name.begins_with("baum_") or name == "maibaum.tscn":
		# Nur der Stamm; der steht in der Mitte der Krone
		groesse = Vector3(NUR_STAMM, kasten.size.y, NUR_STAMM)
	return _schreiben(pfad, groesse, mitte)

## Kollisionsknoten in den Szenentext schreiben (vorhandenen vorher heraus).
func _schreiben(pfad: String, groesse: Vector3, mitte: Vector3) -> bool:
	var datei := FileAccess.open(pfad, FileAccess.READ)
	if datei == null:
		return false
	var zeilen := datei.get_as_text().split("\n")
	datei.close()
	var behalten: Array[String] = []
	var ueberspringen := false
	for zeile: String in zeilen:
		if zeile.begins_with("[sub_resource") and zeile.contains("\"%s\"" % FORM_ID):
			ueberspringen = true
			continue
		if zeile.begins_with("[node "):
			var knoten := _wert(zeile, "name")
			var eltern := _wert(zeile, "parent")
			ueberspringen = knoten == KNOTEN or eltern == KNOTEN
		elif zeile.begins_with("[") and ueberspringen:
			ueberspringen = false
		if not ueberspringen:
			behalten.append(zeile)
	# Die Form muss vor den Knoten stehen — direkt vor dem ersten [node …]
	var form := "[sub_resource type=\"BoxShape3D\" id=\"%s\"]\nsize = Vector3(%s, %s, %s)\n" % [
		FORM_ID, groesse.x, groesse.y, groesse.z]
	var text := ""
	var gesetzt := false
	for zeile: String in behalten:
		if not gesetzt and zeile.begins_with("[node "):
			text += form + "\n"
			gesetzt = true
		text += zeile + "\n"
	text = text.strip_edges() + "\n"
	text += "\n[node name=\"%s\" type=\"StaticBody3D\" parent=\".\"]\n" % KNOTEN
	text += "\n[node name=\"Form\" type=\"CollisionShape3D\" parent=\"%s\"]\n" % KNOTEN
	text += "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\n" % [mitte.x, mitte.y, mitte.z]
	text += "shape = SubResource(\"%s\")\n" % FORM_ID
	var raus := FileAccess.open(pfad, FileAccess.WRITE)
	if raus == null:
		return false
	raus.store_string(text)
	raus.close()
	print("  %s: %.2f × %.2f × %.2f m" % [pfad.get_file(), groesse.x, groesse.y, groesse.z])
	return true

func _wert(zeile: String, feld: String) -> String:
	var suche := feld + "=\""
	var von := zeile.find(suche)
	if von < 0:
		return ""
	von += suche.length()
	var bis := zeile.find("\"", von)
	return zeile.substr(von, bis - von) if bis > von else ""

## Maße aller sichtbaren Meshes, im Raum der Wurzel.
func _masse(wurzel: Node) -> AABB:
	var gesamt := AABB()
	var erstes := true
	for mi: MeshInstance3D in wurzel.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or not mi.visible:
			continue
		var kasten := _relativ(wurzel, mi) * mi.get_aabb()
		if erstes:
			gesamt = kasten
			erstes = false
		else:
			gesamt = gesamt.merge(kasten)
	return gesamt

## Lage eines Knotens im Raum der Wurzel — die Szene hängt nicht im Baum,
## global_transform gäbe nur die Einheitsmatrix.
func _relativ(wurzel: Node, knoten: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = knoten
	while n != null and n != wurzel:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t
