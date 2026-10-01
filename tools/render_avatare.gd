extends Node3D
## Rendert für jede wählbare Figur (scripts/figuren.gd, ALLE) ein Porträt nach
## assets/ui/avatare/figur_<Nr>.png — transparent, Kopf und Schultern. Die Bilder
## erscheinen im Warteraum und in der Figurenwahl. Konrad steht nicht in ALLE,
## ist also nicht wählbar und bekommt keinen Avatar.
##   godot --path . res://tools/render_avatare.tscn --resolution 640x480
## Danach einmal importieren: godot --headless --path . --import

const Figuren := preload("res://scripts/figuren.gd")
const GROESSE := 256
const AUSGABE := "res://assets/ui/avatare/figur_%d.png"
## Kopfhöhe kommt aus dem Knochen "Head" der jeweiligen Figur; Abstand und
## Brennweite sind für alle gleich, damit die Köpfe gleich groß wirken.
const ABSTAND := 1.85
const BRENNWEITE := 26.0
const MITTE_UNTER_KOPF := -0.03

func _ready() -> void:
	var ansicht := SubViewport.new()
	ansicht.size = Vector2i(GROESSE, GROESSE)
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
		var h := _kopf_hoehe(figur)
		kamera.look_at_from_position(Vector3(0.12, h + 0.05, ABSTAND), Vector3(0, h - MITTE_UNTER_KOPF, 0))
		await get_tree().process_frame
		await get_tree().process_frame
		var bild := ansicht.get_texture().get_image()
		bild.save_png(ProjectSettings.globalize_path(AUSGABE % i))
		figur.queue_free()
		await get_tree().process_frame
	print("AVATARE FERTIG: %d" % Figuren.ALLE.size())
	get_tree().quit()

func _kopf_hoehe(f: Figur) -> float:
	if f.skelett == null or f.skelett.find_bone("Head") < 0:
		return 1.6
	var b := f.skelett.find_bone("Head")
	return (f.skelett.global_transform * f.skelett.get_bone_global_pose(b).origin).y
