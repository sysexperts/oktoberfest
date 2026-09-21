extends SceneTree
## Rechnet die Animationen von character2 auf Alex' Skelett um und legt sie als
## AnimationLibrary ab (assets/character/character4/alex_animationen.res).
##
## Warum: Alex kommt aus Meshy und heißt seine Knochen mixamorig_Spine/_Neck/…,
## die anderen Modelle Spine02/neck/… Ausleihen (Figur.leih_animationen) geht
## deshalb nicht — die Spuren zeigen ins Leere und die Figur bleibt in T-Pose.
## Hier werden die Spuren umbenannt und die Drehungen von der Ruhelage des einen
## Skeletts in die des anderen gerechnet.
##
## Aufruf: godot --headless --path . --script res://tools/bake_alex_animationen.gd
## Danach: scenes/figuren/alex.tscn benutzt die Bibliothek als leih_bibliothek.

const QUELLE := "res://assets/character/character2/character2.glb"
const ZIEL := "res://assets/character/character4/Meshy_AI_Blonde_Oktoberfest_Ga_biped_Animation_Walking_withSkin.glb"
const AUSGABE := "res://assets/character/character4/alex_animationen.res"
## Pfad des Skeletts in Alex' Szene (steht in den Spuren der neuen Animationen)
const ZIEL_SKELETT := "target_character/Skeleton3D"

## Knochen von character2 → Knochen von Alex
const KNOCHEN := {
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

func _init() -> void:
	var q_wurzel: Node = (load(QUELLE) as PackedScene).instantiate()
	var z_wurzel: Node = (load(ZIEL) as PackedScene).instantiate()
	var q_skel: Skeleton3D = q_wurzel.find_children("*", "Skeleton3D", true, false)[0]
	var z_skel: Skeleton3D = z_wurzel.find_children("*", "Skeleton3D", true, false)[0]
	var q_spieler: AnimationPlayer = q_wurzel.find_children("*", "AnimationPlayer", true, false)[0]
	var bibliothek := AnimationLibrary.new()
	var gebaut := 0
	for name in q_spieler.get_animation_library("").get_animation_list():
		if name in AUSLASSEN:
			continue
		var neu := _umrechnen(q_spieler.get_animation(name), q_skel, z_skel)
		bibliothek.add_animation(name, neu)
		gebaut += 1
	var fehler := ResourceSaver.save(bibliothek, AUSGABE)
	print("%d Animationen umgerechnet → %s (Fehler %d)" % [gebaut, AUSGABE, fehler])
	q_wurzel.free()
	z_wurzel.free()
	quit()

## Eine Animation auf das Zielskelett umrechnen: Spuren umbenennen, Drehungen
## von der Ruhelage der Quelle in die des Ziels drehen. Positions- und
## Skalierungsspuren fallen weg — die gehören zu den Maßen des anderen Modells,
## Alex behält seine eigenen.
func _umrechnen(alt: Animation, q_skel: Skeleton3D, z_skel: Skeleton3D) -> Animation:
	var neu := Animation.new()
	neu.length = alt.length
	neu.loop_mode = Animation.LOOP_LINEAR
	neu.step = alt.step
	# Die Hüfte braucht ihre Höhenspur — sonst schwebt eine sitzende Figur in
	# Stehhöhe über der Bank. Umgerechnet auf die Beinlänge des Ziels.
	var q_huefte := q_skel.find_bone("Hips")
	var z_huefte := z_skel.find_bone(KNOCHEN["Hips"])
	if q_huefte >= 0 and z_huefte >= 0:
		var q_ruhe_pos := q_skel.get_bone_rest(q_huefte).origin
		var z_ruhe_pos := z_skel.get_bone_rest(z_huefte).origin
		var faktor := z_ruhe_pos.y / q_ruhe_pos.y if absf(q_ruhe_pos.y) > 0.001 else 1.0
		for s in alt.get_track_count():
			if alt.track_get_type(s) != Animation.TYPE_POSITION_3D:
				continue
			if String(alt.track_get_path(s)).get_slice(":", 1) != "Hips":
				continue
			var spur_p := neu.add_track(Animation.TYPE_POSITION_3D)
			neu.track_set_path(spur_p, NodePath("%s:mixamorig_Hips" % ZIEL_SKELETT))
			for k in alt.track_get_key_count(s):
				var pos: Vector3 = alt.track_get_key_value(s, k)
				neu.position_track_insert_key(spur_p, alt.track_get_key_time(s, k), pos * faktor)
	for s in alt.get_track_count():
		if alt.track_get_type(s) != Animation.TYPE_ROTATION_3D:
			continue
		var pfad := String(alt.track_get_path(s))
		var knochen := pfad.get_slice(":", 1)
		if not KNOCHEN.has(knochen):
			continue
		var z_knochen: String = KNOCHEN[knochen]
		var qb := q_skel.find_bone(knochen)
		var zb := z_skel.find_bone(z_knochen)
		if qb < 0 or zb < 0:
			continue
		# Ruhelagen: lokal (davon weicht die Animation ab) und global (in der
		# Weltlage unterscheiden sich die beiden Skelette)
		var q_ruhe := q_skel.get_bone_rest(qb).basis.get_rotation_quaternion()
		var z_ruhe := z_skel.get_bone_rest(zb).basis.get_rotation_quaternion()
		var q_welt := q_skel.get_bone_global_rest(qb).basis.get_rotation_quaternion()
		var z_welt := z_skel.get_bone_global_rest(zb).basis.get_rotation_quaternion()
		var dreh := z_welt.inverse() * q_welt
		var spur := neu.add_track(Animation.TYPE_ROTATION_3D)
		neu.track_set_path(spur, NodePath("%s:%s" % [ZIEL_SKELETT, z_knochen]))
		neu.track_set_interpolation_type(spur, alt.track_get_interpolation_type(s))
		for k in alt.track_get_key_count(s):
			var zeit := alt.track_get_key_time(s, k)
			var wert: Quaternion = alt.track_get_key_value(s, k)
			# Abweichung von der Ruhelage, in die Knochenlage des Ziels gedreht
			var abweichung := q_ruhe.inverse() * wert
			var ziel_wert := z_ruhe * (dreh * abweichung * dreh.inverse())
			neu.rotation_track_insert_key(spur, zeit, ziel_wert.normalized())
	return neu
