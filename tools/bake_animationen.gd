extends SceneTree
## Rechnet die Animationen von character2 (Referenz-Rig) auf das Skelett jedes
## anderen Modells um und legt sie als AnimationLibrary ab. Dann bewegen sich alle
## Figuren mit denselben Clips — nur auf ihrem eigenen Skelett (Ruhepose, Achsen und
## Proportionen werden ausgeglichen, siehe _umrechnen).
##
## Aufruf: godot --headless --path . --script res://tools/bake_animationen.gd -- bean alex
## (ohne Namen: alle). Danach benutzt die Figurszene die Bibliothek als
## leih_bibliothek (Animationen heißen "geliehen/<Name>").

const QUELLE := "res://assets/character/character2/character2.glb"

## Ziele: Modell, Pfad des Skeletts im Modell, Ausgabe
const ZIELE := {
	"bean": {
		"modell": "res://assets/character/character/bavarian_bean.glb",
		"skelett": "Armature/Skeleton3D",
		"ausgabe": "res://assets/character/character/bean_animationen.res",
	},
	"standard": {
		"modell": "res://assets/character/standard/standardkoerper.glb",
		"skelett": "Armature/Skeleton3D",
		"ausgabe": "res://assets/character/standard/standard_animationen.res",
	},
	"alex": {
		"modell": "res://assets/character/character4/alex_Walking_withSkin.glb",
		"skelett": "target_character/Skeleton3D",
		"ausgabe": "res://assets/character/character4/alex_animationen.res",
	},
}

## Knochen von character2 → Knochen von Alex (mixamorig_-Namen). Modelle mit
## denselben Namen wie character2 brauchen keine Zuordnung.
const KNOCHEN_MIXAMO := {
	"Hips": "mixamorig_Hips",
	"Spine02": "mixamorig_Spine", "Spine01": "mixamorig_Spine1", "Spine": "mixamorig_Spine2",
	"neck": "mixamorig_Neck", "Head": "mixamorig_Head",
	"LeftShoulder": "mixamorig_LeftShoulder", "LeftArm": "mixamorig_LeftArm",
	"LeftForeArm": "mixamorig_LeftForeArm", "LeftHand": "mixamorig_LeftHand",
	"RightShoulder": "mixamorig_RightShoulder", "RightArm": "mixamorig_RightArm",
	"RightForeArm": "mixamorig_RightForeArm", "RightHand": "mixamorig_RightHand",
	"LeftUpLeg": "mixamorig_LeftUpLeg", "LeftLeg": "mixamorig_LeftLeg",
	"LeftFoot": "mixamorig_LeftFoot", "LeftToeBase": "mixamorig_LeftToeBase",
	"RightUpLeg": "mixamorig_RightUpLeg", "RightLeg": "mixamorig_RightLeg",
	"RightFoot": "mixamorig_RightFoot", "RightToeBase": "mixamorig_RightToeBase",
}
## Die braucht niemand — restpose ist die T-Pose selbst
const AUSLASSEN := ["restpose"]

## Zuordnung Quellknochen → Zielknochen und Pfad des Zielskeletts für den laufenden Lauf
var KNOCHEN := {}
var ZIEL_SKELETT := ""
var HUEFTE_Q := "Hips"

## Weitere Quellen (Mixamo-Namen): Animation → Datei. Nur für Ziele mit Wilhelms Knochennamen.
const EXTRA_QUELLEN := {
	"Unsteady_Walk": "res://assets/character/character4/alex_Unsteady_Walk_withSkin.glb",
}

func _init() -> void:
	var namen: Array = Array(OS.get_cmdline_user_args())
	if namen.is_empty():
		namen = ZIELE.keys()
	for n in namen:
		_ziel_backen(n)
	quit()

func _ziel_backen(name: String) -> void:
	var z: Dictionary = ZIELE[name]
	var q_wurzel: Node = (load(QUELLE) as PackedScene).instantiate()
	var z_wurzel: Node = (load(z["modell"]) as PackedScene).instantiate()
	var q_skel: Skeleton3D = q_wurzel.find_children("*", "Skeleton3D", true, false)[0]
	var z_skel: Skeleton3D = z_wurzel.get_node(z["skelett"])
	ZIEL_SKELETT = z["skelett"]
	KNOCHEN = {}
	for b in q_skel.get_bone_count():
		var n := q_skel.get_bone_name(b)
		if z_skel.find_bone(n) >= 0:
			KNOCHEN[n] = n
		elif KNOCHEN_MIXAMO.has(n) and z_skel.find_bone(KNOCHEN_MIXAMO[n]) >= 0:
			KNOCHEN[n] = KNOCHEN_MIXAMO[n]
	var q_spieler: AnimationPlayer = q_wurzel.find_children("*", "AnimationPlayer", true, false)[0]
	var bibliothek := AnimationLibrary.new()
	var gebaut := 0
	for an in q_spieler.get_animation_library("").get_animation_list():
		if an in AUSLASSEN:
			continue
		bibliothek.add_animation(an, _umrechnen(q_spieler.get_animation(an), q_skel, z_skel))
		gebaut += 1
	if name == "standard":
		for an in EXTRA_QUELLEN:
			var e_wurzel: Node = (load(EXTRA_QUELLEN[an]) as PackedScene).instantiate()
			var e_skel: Skeleton3D = e_wurzel.find_children("*", "Skeleton3D", true, false)[0]
			var e_spieler: AnimationPlayer = e_wurzel.find_children("*", "AnimationPlayer", true, false)[0]
			KNOCHEN = {}
			for b in e_skel.get_bone_count():
				var qn := e_skel.get_bone_name(b)
				var zn = KNOCHEN_MIXAMO.find_key(qn)
				if zn != null and z_skel.find_bone(zn) >= 0:
					KNOCHEN[qn] = zn
			HUEFTE_Q = "mixamorig_Hips"
			bibliothek.add_animation(an, _umrechnen(e_spieler.get_animation(an), e_skel, z_skel))
			HUEFTE_Q = "Hips"
			e_wurzel.free()
			print("Zusatz: ", an, " (", KNOCHEN.size(), " Knochen)")
	var fehler := ResourceSaver.save(bibliothek, z["ausgabe"])
	print("%s: %d Animationen, %d von %d Knochen zugeordnet → %s (Fehler %d)" % [name, gebaut, KNOCHEN.size(), q_skel.get_bone_count(), z["ausgabe"], fehler])
	q_wurzel.free()
	z_wurzel.free()

## Bilder pro Sekunde, in denen jede Animation abgetastet wird
const TAKT := 30.0

## Eine Animation auf das Zielskelett umrechnen.
##
## Die beiden Skelette stehen in der Ruhelage verschieden (character2 in
## A-Pose mit hängenden Armen, Alex in T-Pose). Eine Drehung „relativ zur
## Ruhelage des Knochens" zu übertragen reicht deshalb nicht — Alex hielte die
## Arme dauernd waagrecht. Stattdessen wird Bild für Bild die Lage jedes
## Knochens im Modell bestimmt (ganze Kette von der Hüfte aus) und das Ziel so
## gedreht, dass jeder Knochen im Modell dieselbe Richtung bekommt wie in der
## Quelle. Das ist unabhängig von Ruhelage und Knochenachsen.
func _umrechnen(alt: Animation, q_skel: Skeleton3D, z_skel: Skeleton3D) -> Animation:
	var neu := Animation.new()
	neu.length = alt.length
	neu.loop_mode = Animation.LOOP_LINEAR
	neu.step = 1.0 / TAKT
	# Lage der Skelette im Modell (Armature-Knoten können gedreht sein)
	var q_s := _modell_lage(q_skel)
	var z_s := _modell_lage(z_skel)
	# Form, in der die Haut modelliert ist (kann von der Ruhelage abweichen)
	var q_bind := _bindung(q_skel)
	var z_bind := _bindung(z_skel)
	# Spuren der Quelle je Knochen
	var q_dreh := {}
	var q_pos := {}
	for s in alt.get_track_count():
		var knochen := String(alt.track_get_path(s)).get_slice(":", 1)
		var b := q_skel.find_bone(knochen)
		if b < 0:
			continue
		if alt.track_get_type(s) == Animation.TYPE_ROTATION_3D:
			q_dreh[b] = s
		elif alt.track_get_type(s) == Animation.TYPE_POSITION_3D:
			q_pos[b] = s
	# Zielknochen in Reihenfolge der Kette (Eltern zuerst) mit ihrer Quelle
	var paare := []
	for zb in z_skel.get_bone_count():
		var qname: String = KNOCHEN.find_key(z_skel.get_bone_name(zb)) if KNOCHEN.values().has(z_skel.get_bone_name(zb)) else ""
		paare.append(q_skel.find_bone(qname) if qname != "" else -1)
	# A-Pose gegen T-Pose: jeden Zielknochen in der Bindungsform erst auf die
	# Richtung des Quellknochens drehen (Knochen → erstes zugeordnetes Kind).
	# Ohne das bliebe der Unterschied erhalten und Alex hielte die Arme ab.
	var ausrichtung := []
	for zb in z_skel.get_bone_count():
		var a := Quaternion()
		var qb: int = paare[zb]
		var kind := -1
		for k in z_skel.get_bone_children(zb):
			if paare[k] >= 0:
				kind = k
				break
		if qb >= 0 and kind >= 0:
			var z_richtung := z_s.basis * ((z_bind[kind] as Transform3D).origin - (z_bind[zb] as Transform3D).origin)
			var q_richtung := q_s.basis * ((q_bind[paare[kind]] as Transform3D).origin - (q_bind[qb] as Transform3D).origin)
			if z_richtung.length() > 0.0001 and q_richtung.length() > 0.0001:
				a = Quaternion(z_richtung.normalized(), q_richtung.normalized())
		elif z_skel.get_bone_parent(zb) >= 0:
			# Hände, Zehen: wie ihr Eltern-Knochen
			a = ausrichtung[z_skel.get_bone_parent(zb)]
		ausrichtung.append(a)
	var spuren := {}
	for zb in z_skel.get_bone_count():
		if paare[zb] >= 0:
			spuren[zb] = neu.add_track(Animation.TYPE_ROTATION_3D)
			neu.track_set_path(spuren[zb], NodePath("%s:%s" % [ZIEL_SKELETT, z_skel.get_bone_name(zb)]))
	# Hüfthöhe: sonst schwebt eine sitzende Figur über der Bank. Umgerechnet
	# auf die Beinlänge des Ziels.
	var q_huefte := q_skel.find_bone(HUEFTE_Q)
	var z_huefte := z_skel.find_bone(KNOCHEN[HUEFTE_Q])
	var huefte_spur := -1
	var faktor := 1.0
	if q_pos.has(q_huefte) and z_huefte >= 0:
		huefte_spur = neu.add_track(Animation.TYPE_POSITION_3D)
		neu.track_set_path(huefte_spur, NodePath("%s:%s" % [ZIEL_SKELETT, KNOCHEN[HUEFTE_Q]]))
		var qy := (q_s * q_skel.get_bone_global_rest(q_huefte)).origin.y
		var zy := (z_s * z_skel.get_bone_global_rest(z_huefte)).origin.y
		faktor = zy / qy if absf(qy) > 0.001 else 1.0

	var bilder := maxi(1, int(ceil(alt.length * TAKT)))
	for i in bilder + 1:
		var zeit := minf(i / TAKT, alt.length)
		# Quelle: Lage jedes Knochens im Modell
		var q_welt := []
		for qb in q_skel.get_bone_count():
			var lokal := q_skel.get_bone_rest(qb).basis.get_rotation_quaternion()
			if q_dreh.has(qb):
				lokal = alt.rotation_track_interpolate(q_dreh[qb], zeit)
			var eltern := q_skel.get_bone_parent(qb)
			q_welt.append((q_welt[eltern] if eltern >= 0 else q_s.basis.get_rotation_quaternion()) * lokal)
		# Ziel: gleiche Drehung gegenüber der Ruhelage, im Modell gemessen
		var z_welt := []
		for zb in z_skel.get_bone_count():
			var eltern := z_skel.get_bone_parent(zb)
			var eltern_welt: Quaternion = z_welt[eltern] if eltern >= 0 else z_s.basis.get_rotation_quaternion()
			var qb: int = paare[zb]
			if qb < 0:
				z_welt.append(eltern_welt * z_skel.get_bone_rest(zb).basis.get_rotation_quaternion())
				continue
			var q_ruhe := q_s.basis.get_rotation_quaternion() * (q_bind[qb] as Transform3D).basis.get_rotation_quaternion()
			var z_ruhe: Quaternion = ausrichtung[zb] * z_s.basis.get_rotation_quaternion() * (z_bind[zb] as Transform3D).basis.get_rotation_quaternion()
			var welt: Quaternion = (q_welt[qb] as Quaternion) * q_ruhe.inverse() * z_ruhe
			z_welt.append(welt)
			var lokal := (eltern_welt.inverse() * welt).normalized()
			neu.rotation_track_insert_key(spuren[zb], zeit, lokal)
		if huefte_spur >= 0:
			# Verschiebung gegenüber der Ruhelage, im Modell gemessen und skaliert
			var q_ruhe_pos := q_skel.get_bone_rest(q_huefte).origin
			var weg := q_s.basis * (alt.position_track_interpolate(q_pos[q_huefte], zeit) - q_ruhe_pos) * faktor
			var z_pos := z_skel.get_bone_rest(z_huefte).origin + z_s.basis.inverse() * weg
			neu.position_track_insert_key(huefte_spur, zeit, z_pos)
	return neu

## Lage des Skeletts gegenüber der Modellwurzel (alle Knoten dazwischen)
func _modell_lage(skel: Skeleton3D) -> Transform3D:
	var t := Transform3D()
	var n: Node = skel
	while n != null and n is Node3D and n.get_parent() != null:
		t = (n as Node3D).transform * t
		n = n.get_parent()
	return t

## Lage jedes Knochens (im Skelett) in der Form, in der die Haut gebunden ist (aus der
## Skin: Bindungsmatrix umgekehrt). Das ist die Pose, in der das Modell ohne
## Animation aussieht — bei Alex eine andere als die Ruhelage des Skeletts.
## Knochen ohne Bindung: aus der Ruhelage, über den Eltern weitergerechnet.
func _bindung(skel: Skeleton3D) -> Array:
	var aus_skin := {}
	for mi: MeshInstance3D in skel.find_children("*", "MeshInstance3D", false, false):
		if mi.skin == null:
			continue
		for i in mi.skin.get_bind_count():
			var bn := mi.skin.get_bind_name(i)
			var b := mi.skin.get_bind_bone(i) if bn == "" else skel.find_bone(bn)
			if b >= 0:
				aus_skin[b] = mi.transform * mi.skin.get_bind_pose(i).affine_inverse()
		break
	var ergebnis := []
	for b in skel.get_bone_count():
		if aus_skin.has(b):
			ergebnis.append(aus_skin[b])
		else:
			var eltern := skel.get_bone_parent(b)
			var e: Transform3D = ergebnis[eltern] if eltern >= 0 else Transform3D()
			ergebnis.append(e * skel.get_bone_rest(b))
	return ergebnis
