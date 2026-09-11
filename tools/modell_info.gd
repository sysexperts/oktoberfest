extends SceneTree
## Vergleicht Figuren-Modelle: Animationen, Skelett, Größe, Meshes, Materialien.
## Hilft beim Einbauen neuer Charaktere — die NPC-Skripte sprechen Animationen
## und Knochen über Namen an, die im neuen Modell gleich heißen müssen.
## Aufruf: godot --headless --path . --script res://tools/modell_info.gd

const MODELLE := [
	"res://assets/character/character/bavarian_bean.glb",
	"res://assets/character/character2/character2.glb",
	"res://assets/character/character3/character3.glb",
]
## Knochen, die customer.gd / visitor.gd / staff.gd direkt ansprechen
const GEBRAUCHTE_KNOCHEN := ["Hips", "Spine", "Head", "RightArm", "RightForeArm", "RightHand",
	"LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg"]
const GEBRAUCHTE_ANIMATIONEN := ["Idle", "Walk", "Run", "Dance"]

func _init() -> void:
	for pfad: String in MODELLE:
		print("\n===== ", pfad)
		var szene := load(pfad) as PackedScene
		if szene == null:
			print("  nicht ladbar (Import fehlt?)")
			continue
		var m := szene.instantiate() as Node3D
		root.add_child(m)
		await process_frame
		for ap: AnimationPlayer in m.find_children("*", "AnimationPlayer", true, false):
			print("  AnimationPlayer ", m.get_path_to(ap), ":")
			for name in ap.get_animation_list():
				var a := ap.get_animation(name)
				print("    %-28s %5.2f s  %d Spuren  Schleife=%d  Hüfte %s%s" % [name, a.length, a.get_track_count(),
					a.loop_mode, _hueft_weg(a), "  ← gebraucht" if name in GEBRAUCHTE_ANIMATIONEN else ""])
		# Blickrichtung aus der Ruhepose: vom Kopf zum Knochen "headfront"
		for sk: Skeleton3D in m.find_children("*", "Skeleton3D", true, false):
			var kopf := sk.find_bone("Head")
			var vorne := sk.find_bone("headfront")
			if kopf >= 0 and vorne >= 0:
				var d := (sk.global_transform * sk.get_bone_global_rest(vorne).origin) \
					- (sk.global_transform * sk.get_bone_global_rest(kopf).origin)
				d.y = 0.0
				print("  Blickrichtung (Welt, Ruhepose): %s → %s" % [str(d.normalized().snapped(Vector3.ONE * 0.01)),
					"schaut nach -Z (Godot-Standard)" if d.z < 0 else "schaut nach +Z (180° drehen)"])
		for sk: Skeleton3D in m.find_children("*", "Skeleton3D", true, false):
			var namen := []
			for i in sk.get_bone_count():
				namen.append(sk.get_bone_name(i))
			print("  Skelett ", m.get_path_to(sk), ": ", sk.get_bone_count(), " Knochen")
			print("    ", ", ".join(namen))
			var fehlen := GEBRAUCHTE_KNOCHEN.filter(func(k: String) -> bool: return not k in namen)
			print("    fehlende gebrauchte Knochen: ", fehlen if not fehlen.is_empty() else "keine")
		var box := AABB()
		var erste := true
		var meshes := 0
		var mats := {}
		for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
			meshes += 1
			var b := mi.global_transform * mi.get_aabb()
			box = b if erste else box.merge(b)
			erste = false
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s)
				mats[str(mat.resource_name if mat else "—")] = true
				# Metallisch wirkt in dunklen Räumen schwarz — deshalb die Werte zeigen
				if mat is BaseMaterial3D:
					var bm := mat as BaseMaterial3D
					print("  Material %s: metallic %.2f (Textur %s) · roughness %.2f (Textur %s) · albedo %s (Textur %s) · shading %d" % [
						bm.resource_name, bm.metallic, bm.metallic_texture != null, bm.roughness,
						bm.roughness_texture != null, str(bm.albedo_color), bm.albedo_texture != null, bm.shading_mode])
					print("    emission %s (Energie %.2f, Textur %s) · normal %s · ao %s · rim %s · specular %.2f · vertex_color %s · transparency %d" % [
						bm.emission_enabled, bm.emission_energy_multiplier, bm.emission_texture != null,
						bm.normal_enabled, bm.ao_enabled, bm.rim_enabled, bm.metallic_specular,
						bm.vertex_color_use_as_albedo, bm.transparency])
					if bm.albedo_texture:
						print("    Farbtextur: mittlere Helligkeit %.2f" % _mittlere_helligkeit(bm.albedo_texture))
					if bm.metallic_texture:
						print("    Metallic-Textur (Kanal %d): Mittelwert %.2f" % [bm.metallic_texture_channel,
							_mittlerer_kanal(bm.metallic_texture, bm.metallic_texture_channel)])
		print("  Meshes: %d · Materialien: %s" % [meshes, ", ".join(mats.keys())])
		print("  Größe (Ruhepose): %.2f × %.2f × %.2f m · Boden bei y=%.2f" % [box.size.x, box.size.y, box.size.z, box.position.y])
		print("  Wurzel: ", m.get_class(), " · Kinder: ", m.get_children().map(func(c: Node) -> String: return "%s(%s)" % [c.name, c.get_class()]))
		m.queue_free()
	quit()

## Mittlere wahrgenommene Helligkeit einer Textur (0 = schwarz, 1 = weiß), grob gerastert.
func _mittlere_helligkeit(tex: Texture2D) -> float:
	var bild := tex.get_image()
	if bild == null:
		return -1.0
	if bild.is_compressed():
		bild.decompress()
	var summe := 0.0
	var n := 0
	var schritt := maxi(1, bild.get_width() / 64)
	for y in range(0, bild.get_height(), schritt):
		for x in range(0, bild.get_width(), schritt):
			var c := bild.get_pixel(x, y)
			summe += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			n += 1
	return summe / maxf(1.0, float(n))

func _mittlerer_kanal(tex: Texture2D, kanal: int) -> float:
	var bild := tex.get_image()
	if bild == null:
		return -1.0
	if bild.is_compressed():
		bild.decompress()
	var summe := 0.0
	var n := 0
	var schritt := maxi(1, bild.get_width() / 64)
	for y in range(0, bild.get_height(), schritt):
		for x in range(0, bild.get_width(), schritt):
			var c := bild.get_pixel(x, y)
			summe += [c.r, c.g, c.b, c.a][clampi(kanal, 0, 3)]
			n += 1
	return summe / maxf(1.0, float(n))

## Wie weit sich die Hüfte über die Animation waagerecht bewegt. Viel Weg = die
## Animation läuft von der Stelle weg (Root Motion) und würde die Figur verschieben.
func _hueft_weg(a: Animation) -> String:
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not String(a.track_get_path(t)).ends_with(":Hips"):
			continue
		var n := a.track_get_key_count(t)
		if n < 2:
			return "fest"
		var p0: Vector3 = a.track_get_key_value(t, 0)
		var p1: Vector3 = a.track_get_key_value(t, n - 1)
		var weg := Vector2(p1.x - p0.x, p1.z - p0.z).length()
		var hoehe := absf(p1.y - p0.y)
		return "%.2f waagerecht / %.2f senkrecht" % [weg, hoehe]
	return "ohne Spur"
