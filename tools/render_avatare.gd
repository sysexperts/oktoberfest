extends Node3D
## Rendert für jede wählbare Figur (scripts/figuren.gd, ALLE) ein Porträt nach
## assets/ui/avatare/figur_<Nr>.png — transparent, Kopf und Schultern. Die Bilder
## erscheinen im Warteraum und in der Figurenwahl. Konrad steht nicht in ALLE,
## ist also nicht wählbar und bekommt keinen Avatar.
##   godot --path . res://tools/render_avatare.tscn --resolution 640x480
## Danach einmal importieren: godot --headless --path . --import

const Figuren := preload("res://scripts/figuren.gd")
## Es wird groß gerendert und dann aufs Gesicht zugeschnitten (siehe _gesicht_ausschnitt)
const RENDER := 900
const GROESSE := 256
## Drehung der Figur (Grad), Abstand Brust unter dem Kopfknochen, Rand und kleinste Bildhöhe (m)
const DREHUNG := 18.0
const BRUST_UNTER_KOPF := 0.3
const RAND := 0.1
const MIN_SEITE := 0.6
## Kopfhöhe (m) für Figuren ohne brauchbaren Kopfknochen, und feste Oberkante (Otto)
const KOPF_Y := {0: 1.0, 3: 1.3, 7: 1.3, 8: 1.3, 9: 1.3}
const OBEN := {0: 1.4}
const AUSGABE := "res://assets/ui/avatare/figur_%d.png"
## Kopfhöhe kommt aus dem Knochen "Head" der jeweiligen Figur; Abstand und
## Brennweite sind für alle gleich, damit die Köpfe gleich groß wirken.
const ABSTAND := 2.6
const BRENNWEITE := 38.0
const MITTE_UNTER_KOPF := -0.2
## Bildbreite = so viel mal der Augenabstand; Mitte so viel Augenabstände unter den Augen
const AUGEN_ABSTAND_ZU_BILD := 3.1
const AUGEN_NACH_UNTEN := 0.3
const AUGEN_ABSTAND_MAX := 4.4

func _ready() -> void:
	var ansicht := SubViewport.new()
	ansicht.size = Vector2i(RENDER, RENDER)
	ansicht.transparent_bg = true
	ansicht.own_world_3d = true
	ansicht.msaa_3d = Viewport.MSAA_4X
	ansicht.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(ansicht)
	var umgebung := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 0.93, 0.82)
	env.ambient_light_energy = 0.75
	umgebung.environment = env
	ansicht.add_child(umgebung)
	var licht := DirectionalLight3D.new()
	licht.rotation_degrees = Vector3(-25, 35, 0)
	licht.light_color = Color(1, 0.95, 0.85)
	licht.light_energy = 1.2
	ansicht.add_child(licht)
	var kamera := Camera3D.new()
	kamera.fov = BRENNWEITE
	ansicht.add_child(kamera)
	kamera.current = true

	for i in Figuren.ALLE.size():
		var figur := Figuren.ALLE[i].instantiate() as Figur
		ansicht.add_child(figur)
		for f in 4:
			await get_tree().process_frame
		figur.stehen()
		for f in 25:
			await get_tree().process_frame
		# Alle gleich: dieselbe Drehung (leicht zur Seite), Orthokamera, Ausschnitt von der
		# Brust bis zur höchsten Stelle der Figur (Hut, Haare), Mitte auf dem Kopf
		figur.rotation_degrees.y = DREHUNG
		var kopf := _kopf_pos(figur)
		# Bei Otto und Alex liefert das Skelett keinen brauchbaren Kopfknochen
		if KOPF_Y.has(i):
			kopf.y = KOPF_Y[i]
		var oben := _oberkante(figur, kopf.y)
		if OBEN.has(i):
			oben = OBEN[i]
		var unten := kopf.y - BRUST_UNTER_KOPF
		var seite := maxf(oben - unten + RAND, MIN_SEITE)
		kamera.projection = Camera3D.PROJECTION_ORTHOGONAL
		kamera.size = seite
		kamera.look_at_from_position(Vector3(kopf.x, oben + RAND * 0.5 - seite * 0.5, kopf.z + 3.0),
			Vector3(kopf.x, oben + RAND * 0.5 - seite * 0.5, kopf.z))
		await get_tree().process_frame
		await get_tree().process_frame
		var bild := ansicht.get_texture().get_image()
		bild.convert(Image.FORMAT_RGBA8)
		bild.resize(GROESSE, GROESSE, Image.INTERPOLATE_LANCZOS)
		_unten_ausblenden(bild)
		# OneDrive oder Virenscanner halten die Datei manchmal kurz fest — nochmal versuchen
		for versuch in 5:
			if bild.save_png(ProjectSettings.globalize_path(AUSGABE % i)) == OK:
				break
			await get_tree().create_timer(0.3).timeout
		figur.queue_free()
		await get_tree().process_frame
	print("AVATARE FERTIG: %d" % Figuren.ALLE.size())
	get_tree().quit()

func _kopf_pos(f: Figur) -> Vector3:
	if f.skelett == null or f.skelett.find_bone("Head") < 0:
		return Vector3(0, 1.6, 0)
	var b := f.skelett.find_bone("Head")
	return f.skelett.global_transform * f.skelett.get_bone_global_pose(b).origin

## Höchster Punkt der Figur über dem Kopf (Hut, Frisur, Feder), aus den Mesh-Rahmen
func _oberkante(f: Figur, kopf_y: float) -> float:
	var oben := kopf_y + 0.12
	for mi: MeshInstance3D in f.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var box := mi.global_transform * mi.mesh.get_aabb()
		# Rümpfe und Ganzkörper-Netze reichen nur bis zum Scheitel; Ausreißer begrenzen
		oben = maxf(oben, minf(box.end.y, kopf_y + 0.7))
	return oben

## Unterer Rand weich ausblenden, damit die Brust nicht hart abgeschnitten wirkt
func _unten_ausblenden(bild: Image) -> void:
	var von := int(bild.get_height() * 0.84)
	for y in range(von, bild.get_height()):
		var f := 1.0 - float(y - von) / float(bild.get_height() - von)
		for x in bild.get_width():
			var c := bild.get_pixel(x, y)
			c.a *= f
			bild.set_pixel(x, y, c)

## Augen finden (zwei weiße, runde Flächen auf gleicher Höhe) und quadratisch um
## das Gesicht schneiden, die Größe aus dem Augenabstand — so sitzen alle Gesichter
## gleich groß in der Bildmitte, egal ob Hut, Haare oder Bart. Ohne sichtbare Augen
## (Sonnenbrille): Kopf als obere Hälfte der Figur schätzen.
func _gesicht_ausschnitt(voll: Image) -> Image:
	var rechteck := Rect2i(0, 0, voll.get_width(), voll.get_height())
	var gesamt := voll.get_used_rect()
	var mitte := Vector2.ZERO
	var seite := 0.0
	# Erst nur reines Weiß (Hutbänder, Hemden stören sonst), dann etwas milder
	var augen := _augen(voll, gesamt, 0.86)
	if augen.size() != 2:
		augen = _augen(voll, gesamt, 0.74)
	if augen.size() == 2:
		var abstand := (augen[0] as Vector2).distance_to(augen[1])
		mitte = ((augen[0] as Vector2) + (augen[1] as Vector2)) / 2.0 + Vector2(0, abstand * AUGEN_NACH_UNTEN)
		# Hohe Köpfe und Hüte ganz aufs Bild nehmen, aber nicht endlos aufziehen
		seite = clampf(2.0 * (mitte.y - gesamt.position.y) * 1.04, abstand * AUGEN_ABSTAND_ZU_BILD, abstand * AUGEN_ABSTAND_MAX)
	else:
		var kopf := voll.get_region(Rect2i(0, gesamt.position.y, voll.get_width(), int(gesamt.size.y * 0.5))).get_used_rect()
		kopf.position.y += gesamt.position.y
		mitte = Vector2(kopf.position.x + kopf.size.x / 2.0, kopf.position.y + kopf.size.y * 0.95)
		seite = kopf.size.x * 1.25
	var s := clampi(int(seite), 64, RENDER)
	var quadrat := Rect2i(int(mitte.x) - s / 2, int(mitte.y) - s / 2, s, s)
	var aus := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var innen := quadrat.intersection(rechteck)
	aus.blit_rect(voll, innen, innen.position - quadrat.position)
	aus.resize(GROESSE, GROESSE, Image.INTERPOLATE_LANCZOS)
	return aus

## Mittelpunkte der beiden Augen in Bildpunkten, [] wenn keine zu finden sind.
## Weiße, deckende Punkte im oberen Teil der Figur, zu Flecken zusammengefasst
## (Raster 4×4 Punkte); Augen sind runde Flecken, nicht zu groß, auf gleicher Höhe.
func _augen(voll: Image, gesamt: Rect2i, helligkeit: float) -> Array:
	const RASTER := 4
	var b := voll.get_width() / RASTER
	var h := voll.get_height() / RASTER
	var weiss := PackedByteArray()
	weiss.resize(b * h)
	# Die Augen liegen im obersten Drittel der Figur; tiefer sind Blusen und Hemden
	var bis := gesamt.position.y + int(RENDER * 0.3)
	for y in h:
		if y * RASTER < gesamt.position.y or y * RASTER > bis:
			continue
		for x in b:
			var c := voll.get_pixel(x * RASTER + 2, y * RASTER + 2)
			if c.a > 0.9 and minf(c.r, minf(c.g, c.b)) > helligkeit:
				weiss[y * b + x] = 1
	var flecken: Array = []
	for start in b * h:
		if weiss[start] != 1:
			continue
		var stapel: Array[int] = [start]
		weiss[start] = 2
		var lo := Vector2i(b, h)
		var ru := Vector2i(-1, -1)
		var anzahl := 0
		while not stapel.is_empty():
			var i: int = stapel.pop_back()
			var x := i % b
			var y := i / b
			anzahl += 1
			lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
			ru = Vector2i(maxi(ru.x, x), maxi(ru.y, y))
			for n: int in [i - 1, i + 1, i - b, i + b]:
				if n >= 0 and n < b * h and weiss[n] == 1 and absi(n % b - x) <= 1:
					weiss[n] = 2
					stapel.append(n)
		var br := ru.x - lo.x + 1
		var ho := ru.y - lo.y + 1
		var runder := float(br) / float(ho)
		if anzahl >= 8 and runder > 0.55 and runder < 1.8 and br < b / 5:
			flecken.append({"mitte": Vector2(lo + ru) / 2.0 * RASTER + Vector2(RASTER, RASTER) / 2.0, "anzahl": anzahl})
	var beste: Array = []
	var bester := 0
	for i in flecken.size():
		for k in range(i + 1, flecken.size()):
			var a: Dictionary = flecken[i]
			var c: Dictionary = flecken[k]
			var am: Vector2 = a["mitte"]
			var cm: Vector2 = c["mitte"]
			var abstand := am.distance_to(cm)
			var gleich_hoch := absf(am.y - cm.y) < abstand * 0.35
			var gleich_gross := float(mini(a["anzahl"], c["anzahl"])) / float(maxi(a["anzahl"], c["anzahl"])) > 0.5
			if gleich_hoch and gleich_gross and abstand > 25 and abstand < RENDER * 0.2 and mini(a["anzahl"], c["anzahl"]) > bester:
				bester = mini(a["anzahl"], c["anzahl"])
				beste = [am, cm]
	return beste
