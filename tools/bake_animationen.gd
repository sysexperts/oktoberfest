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
const Messung := preload("res://tools/koerper_messung.gd")

## Ziele: Modell, Pfad des Skeletts im Modell, Ausgabe
const ZIELE := {
	"bean": {
		"modell": "res://assets/character/character/bavarian_bean.glb",
		"skelett": "Armature/Skeleton3D",
		"ausgabe": "res://assets/character/character/bean_animationen.res",
	},
	"standard": {
		"modell": "res://assets/character/standard/basis.glb",
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
const AUSLASSEN := ["restpose", "Fast_Lightning", "Toss_and_Turn", "Touch_and_Run", "Walk_Left_with_Gun_inplace"]

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
	if namen.size() > 0 and namen[0] == "mixamo":
		_mixamo_backen()
		quit()
		return
	if namen.is_empty():
		namen = ZIELE.keys()
	for n in namen:
		_ziel_backen(n)
	quit()

## Mixamo-FBX aus assets/animationen_mixamo (auch Unterordner) auf den Standardkörper umrechnen. Eine Datei = eine Animation;
## Name = Dateiname ohne Endung (Leerzeichen und Sonderzeichen → _). Ergebnis: assets/character/standard/mixamo_animationen.res,
## die Figur hängt sie als Bibliothek "mixamo" ein (basis.tscn).
## Aufruf: godot --headless --path . --script res://tools/bake_animationen.gd -- mixamo
const MIXAMO_ORDNER := "res://assets/animationen_mixamo"
const MIXAMO_AUSGABE := "res://assets/character/standard/mixamo_animationen.res"
## Einmalige Bewegungen (kein Dauerlauf): Name enthält eines davon
const OHNE_SCHLEIFE := ["jump", "ending", "_to_", "start", "freeze", "stand_up", "sit_down", "getting_up"]

func _mixamo_backen() -> void:
	DEBUG_LEAN = "lean" in OS.get_cmdline_user_args()
	var z_wurzel: Node = (load("res://assets/character/standard/basis.glb") as PackedScene).instantiate()
	var z_skel: Skeleton3D = z_wurzel.get_node("Armature/Skeleton3D")
	ZIEL_SKELETT = "Armature/Skeleton3D"
	var bibliothek := AnimationLibrary.new()
	for pfad in _fbx_liste(MIXAMO_ORDNER):
		var e_wurzel: Node = (load(pfad) as PackedScene).instantiate()
		var spieler := e_wurzel.find_children("*", "AnimationPlayer", true, false)
		var skels := e_wurzel.find_children("*", "Skeleton3D", true, false)
		if spieler.is_empty() or skels.is_empty() or (spieler[0] as AnimationPlayer).get_animation_list().is_empty():
			print("übersprungen (keine Animation): ", pfad)
			e_wurzel.free()
			continue
		var e_skel: Skeleton3D = skels[0]
		var e_anim: AnimationPlayer = spieler[0]
		var alt: Animation = null
		for lib in e_anim.get_animation_library_list():
			for an in e_anim.get_animation_library(lib).get_animation_list():
				if alt == null and an != "RESET" and e_anim.get_animation_library(lib).get_animation(an).length > 0.05:
					alt = e_anim.get_animation_library(lib).get_animation(an)
		if alt == null:
			e_wurzel.free()
			continue
		KNOCHEN = {}
		for b in e_skel.get_bone_count():
			var qn := e_skel.get_bone_name(b)
			var zn = KNOCHEN_MIXAMO.find_key(qn)
			if zn != null and z_skel.find_bone(zn) >= 0:
				KNOCHEN[qn] = zn
		HUEFTE_Q = "mixamorig_Hips"
		KOLLISION = true
		_clip = pfad.get_file()
		var neu := _umrechnen(alt, e_skel, z_skel)
		KOLLISION = false
		HUEFTE_Q = "Hips"
		var name := _sauber(pfad.get_file().get_basename())
		var basis_name := name
		var n := 2
		while bibliothek.has_animation(name):
			name = "%s_%d" % [basis_name, n]
			n += 1
		var klein := name.to_lower()
		neu.loop_mode = Animation.LOOP_LINEAR
		for w in OHNE_SCHLEIFE:
			if klein.contains(w):
				neu.loop_mode = Animation.LOOP_NONE
		bibliothek.add_animation(name, neu)
		print("  ", name, "  ", snappedf(neu.length, 0.01), " s, Rumpfneigung ", snappedf(_lean_min, 1.0), " bis ", snappedf(_lean_max, 1.0), "°", "  (einmalig)" if neu.loop_mode == Animation.LOOP_NONE else "")
		if DEBUG_LEAN:
			pass
			_lean_verlauf = []
		_lean_max = 0.0
		_lean_min = 0.0
		e_wurzel.free()
	var fehler := ResourceSaver.save(bibliothek, MIXAMO_AUSGABE)
	print("Mixamo: %d Animationen → %s (Fehler %d)" % [bibliothek.get_animation_list().size(), MIXAMO_AUSGABE, fehler])
	z_wurzel.free()

func _fbx_liste(ordner: String) -> Array[String]:
	var liste: Array[String] = []
	for d in DirAccess.get_files_at(ordner):
		if d.to_lower().ends_with(".fbx") and not d.to_lower().begins_with("x bot"):
			liste.append(ordner + "/" + d)
	for u in DirAccess.get_directories_at(ordner):
		liste.append_array(_fbx_liste(ordner + "/" + u))
	liste.sort()
	return liste

func _sauber(t: String) -> String:
	var r := ""
	for c in t:
		r += c if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") else "_"
	while r.contains("__"):
		r = r.replace("__", "_")
	return r.trim_prefix("_").trim_suffix("_")

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
	KOLLISION = (name == "standard")
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
	KOLLISION = false
	var fehler := ResourceSaver.save(bibliothek, z["ausgabe"])
	print("%s: %d Animationen, %d von %d Knochen zugeordnet → %s (Fehler %d)" % [name, gebaut, KNOCHEN.size(), q_skel.get_bone_count(), z["ausgabe"], fehler])
	q_wurzel.free()
	z_wurzel.free()

## Bilder pro Sekunde, in denen jede Animation abgetastet wird
var TAKT := 60.0

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
	var messung: RefCounted = Messung.new(z_skel) if KOLLISION else null
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
	var zeiten: Array[float] = []
	_arm_von_unterarm = {}
	for seite in ["Left", "Right"]:
		var u := z_skel.find_bone(seite + "ForeArm")
		var a_ := z_skel.find_bone(seite + "Arm")
		if u >= 0 and a_ >= 0:
			_arm_von_unterarm[u] = a_
	var urspruenge: Array = []     # globale Drehungen je Bild vor der Kollisionsprüfung
	var huefte_pos: Array[Vector3] = []
	for i in bilder + 1:
		var zeit := minf(i / TAKT, alt.length)
		zeiten.append(zeit)
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
		var z_ruhe_liste := []
		for zb in z_skel.get_bone_count():
			var eltern := z_skel.get_bone_parent(zb)
			var eltern_welt: Quaternion = z_welt[eltern] if eltern >= 0 else z_s.basis.get_rotation_quaternion()
			var qb: int = paare[zb]
			if qb < 0:
				z_welt.append(eltern_welt * z_skel.get_bone_rest(zb).basis.get_rotation_quaternion())
				z_ruhe_liste.append(Quaternion.IDENTITY)
				continue
			var q_ruhe := q_s.basis.get_rotation_quaternion() * (q_bind[qb] as Transform3D).basis.get_rotation_quaternion()
			var z_ruhe: Quaternion = ausrichtung[zb] * z_s.basis.get_rotation_quaternion() * (z_bind[zb] as Transform3D).basis.get_rotation_quaternion()
			var welt: Quaternion = (q_welt[qb] as Quaternion) * q_ruhe.inverse() * z_ruhe
			z_welt.append(welt)
			z_ruhe_liste.append(z_ruhe)
		var z_pos := Vector3.ZERO
		if huefte_spur >= 0:
			# Verschiebung gegenüber der Ruhelage, im Modell gemessen und skaliert
			var q_ruhe_pos := q_skel.get_bone_rest(q_huefte).origin
			var weg := q_s.basis * (alt.position_track_interpolate(q_pos[q_huefte], zeit) - q_ruhe_pos) * faktor
			z_pos = z_skel.get_bone_rest(z_huefte).origin + z_s.basis.inverse() * weg
			neu.position_track_insert_key(huefte_spur, zeit, z_pos)
		var hip_pos: Vector3 = z_pos if huefte_spur >= 0 else z_skel.get_bone_rest(maxi(z_huefte, 0)).origin
		huefte_pos.append(hip_pos)
		if KOLLISION:
			_korrigieren(z_welt, z_skel, z_huefte, hip_pos, z_ruhe_liste)
		urspruenge.append(z_welt)
	var fertig: Array = urspruenge
	if KOLLISION:
		# Runde 1: Hände auf jedem Bild aus dem Körper drehen. Danach die Korrekturen über die Zeit glätten und noch einmal
		# prüfen (zwei Mal): sonst springt die Hand zwischen zwei Bildern, weil jedes Bild für sich gelöst wird, und läuft
		# beim Überblenden kurz durch den Oberschenkel.
		fertig = []
		for i in urspruenge.size():
			var z: Array = (urspruenge[i] as Array).duplicate()
			_nachkorrigieren(messung, z_skel, z, huefte_pos[i], paare)
			fertig.append(z)
		for runde in 2:
			var geglaettet: Array = []
			for i in urspruenge.size():
				var z: Array = (urspruenge[i] as Array).duplicate()
				for seite in ["Left", "Right"]:
					var ia := z_skel.find_bone(seite + "Arm")
					var iu := z_skel.find_bone(seite + "ForeArm")
					if ia < 0 or iu < 0:
						continue
					var qa := _mittel_delta(fertig, urspruenge, i, ia, null)
					var qf := _mittel_delta(fertig, urspruenge, i, iu, qa)
					for bb in _unterbaum(z_skel, ia):
						z[bb] = qa * (z[bb] as Quaternion)
					for bb in _unterbaum(z_skel, iu):
						z[bb] = qf * (z[bb] as Quaternion)
				_nachkorrigieren(messung, z_skel, z, huefte_pos[i], paare)
				geglaettet.append(z)
			fertig = geglaettet
	for i in fertig.size():
		var z_welt: Array = fertig[i]
		for zb in z_skel.get_bone_count():
			if paare[zb] < 0:
				continue
			var eltern := z_skel.get_bone_parent(zb)
			var eltern_welt: Quaternion = z_welt[eltern] if eltern >= 0 else z_s.basis.get_rotation_quaternion()
			neu.rotation_track_insert_key(spuren[zb], zeiten[i], (eltern_welt.inverse() * (z_welt[zb] as Quaternion)).normalized())
	return neu

## Mit KOLLISION = true: Arme und Kopf so zurechtrücken, dass die Hände nicht in Rumpf oder Kopf der Figur stecken.
## Die Mixamo-Figur hat einen schmalen Körper und einen kleinen Kopf; unsere Figuren sind breit mit großem Kopf (und Haar, Hut,
## Kleidung). Pro Bild: Ellbogen, Hand und Fingerspitze gegen Kopf- und Rumpfform prüfen und Arm bzw. Unterarm herausdrehen;
## die Kopfneigung nach vorn wird begrenzt.
var KOLLISION := false
var DEBUG_LEAN := false
var _anfang_tiefe := 0.0
var _dbg_zeit := -1.0
var _clip := ""
var _lean_verlauf: Array = []
var _lean_max := 0.0
var _lean_min := 0.0
const KOPF_MAX_VORN := 28.0
const KOPF_MAX_HINTEN := 35.0

func _korrigieren(z_welt: Array, z_skel: Skeleton3D, hip: int, hip_pos: Vector3, ruhe: Array) -> void:
	var pos := []
	for b in z_skel.get_bone_count():
		var p := z_skel.get_bone_parent(b)
		if p < 0:
			pos.append(hip_pos if b == hip else z_skel.get_bone_rest(b).origin)
		else:
			pos.append((pos[p] as Vector3) + (z_welt[p] as Quaternion) * z_skel.get_bone_rest(b).origin)
	# Hindernisse im Modellraum aus den animierten Knochen: Rumpf (Kapsel Hüfte → Hals, folgt dem Vorbeugen), Oberschenkel und
	# Schienbeine (Kapseln), Kopf (Ellipsoid entlang der Kopfachse)
	var vol := {"kapseln": [], "kopf": null}
	var i_hips := z_skel.find_bone("Hips")
	var i_hals := z_skel.find_bone("neck")
	if i_hips >= 0 and i_hals >= 0:
		vol["kapseln"].append([pos[i_hips], pos[i_hals] + Vector3(0, 0.03, 0), 0.24])
	for seite in ["Left", "Right"]:
		var iu := z_skel.find_bone(seite + "UpLeg")
		var il := z_skel.find_bone(seite + "Leg")
		var ifu := z_skel.find_bone(seite + "Foot")
		if iu >= 0 and il >= 0:
			vol["kapseln"].append([pos[iu], pos[il], 0.105])
		if il >= 0 and ifu >= 0:
			vol["kapseln"].append([pos[il], pos[ifu], 0.085])
	var i_kopf := z_skel.find_bone("Head")
	var i_ende := z_skel.find_bone("head_end")
	if i_kopf >= 0 and i_ende >= 0:
		var achse_k: Vector3 = ((pos[i_ende] as Vector3) - (pos[i_kopf] as Vector3))
		vol["kopf"] = [(pos[i_kopf] as Vector3) + achse_k * 0.5, achse_k.normalized()]
	if i_hips >= 0 and i_hals >= 0:
		var rumpf_achse: Vector3 = ((pos[i_hals] as Vector3) - (pos[i_hips] as Vector3)).normalized()
		var lean := rad_to_deg(atan2(rumpf_achse.z, rumpf_achse.y))
		if DEBUG_LEAN: _lean_verlauf.append(int(lean))
		_lean_max = maxf(_lean_max, lean)
		_lean_min = minf(_lean_min, lean)
	# Kopfneigung begrenzen
	var kopf := z_skel.find_bone("Head")
	if kopf >= 0:
		var v: Vector3 = ((z_welt[kopf] as Quaternion) * (ruhe[kopf] as Quaternion).inverse()) * Vector3.UP
		var neigung := atan2(v.z, v.y)
		var korr := 0.0
		if neigung > deg_to_rad(KOPF_MAX_VORN):
			korr = -(neigung - deg_to_rad(KOPF_MAX_VORN))
		elif neigung < -deg_to_rad(KOPF_MAX_HINTEN):
			korr = -(neigung + deg_to_rad(KOPF_MAX_HINTEN))
		if korr != 0.0:
			var q := Quaternion(Vector3.RIGHT, korr)
			for b in _unterbaum(z_skel, kopf):
				z_welt[b] = q * (z_welt[b] as Quaternion)
	for seite in ["Left", "Right"]:
		var ia := z_skel.find_bone(seite + "Arm")
		var iu := z_skel.find_bone(seite + "ForeArm")
		var ih := z_skel.find_bone(seite + "Hand")
		var it := z_skel.find_bone(seite + "Hand_End")
		if ia < 0 or iu < 0 or ih < 0:
			continue
		if it < 0:
			it = ih
		var s_: Vector3 = pos[ia]
		var e0: Vector3 = pos[iu]
		var h0: Vector3 = pos[ih]
		var t0: Vector3 = pos[it]
		var qa := Quaternion.IDENTITY
		var qf := Quaternion.IDENTITY
		for durchlauf in 24:
			var e := s_ + qa * (e0 - s_)
			var bewegt := false
			var d := _raus(e, vol)
			if d.length() > 0.003:
				var q := _dreh_um(s_, e, d, 0.9)
				if _winkel(q * qa) < deg_to_rad(85.0):
					qa = q * qa
					bewegt = true
			e = s_ + qa * (e0 - s_)
			var h := e + qf * (qa * (h0 - e0))
			var t := e + qf * (qa * (t0 - e0))
			var dh := _raus(h, vol)
			var dt := _raus(t, vol)
			var dm := dh if dh.length() >= dt.length() else dt
			var pm := h if dh.length() >= dt.length() else t
			if dm.length() > 0.003:
				# erst den Unterarm, dann (wenn der nicht reicht) den ganzen Arm herausdrehen
				var q2 := _dreh_um(e, pm, dm, 0.7)
				if _winkel(q2 * qf) < deg_to_rad(100.0):
					qf = q2 * qf
					bewegt = true
				else:
					var q3 := _dreh_um(s_, pm, dm, 0.6)
					if _winkel(q3 * qa) < deg_to_rad(85.0):
						qa = q3 * qa
						bewegt = true
			if not bewegt:
				break
		if qa != Quaternion.IDENTITY:
			for b in _unterbaum(z_skel, ia):
				z_welt[b] = qa * (z_welt[b] as Quaternion)
		if qf != Quaternion.IDENTITY:
			for b in _unterbaum(z_skel, iu):
				z_welt[b] = qf * (z_welt[b] as Quaternion)

## Zweite Runde gegen das echte Körpernetz: Skelett in die Pose stellen, messen (tools/koerper_messung.gd), Unterarm und Arm
## so herausdrehen, dass der tiefste Punkt aus dem Körper kommt, und das wiederholen, bis nichts mehr stecken bleibt.
func _nachkorrigieren(m: RefCounted, z_skel: Skeleton3D, z_welt: Array, hip_pos: Vector3, paare: Array) -> void:
	# Die beste Lage merken: der Löser kann sich bei eingeklemmten Händen (zwischen Bein und Rumpf) verlaufen und einzelne
	# Bilder verdrehen — dann gilt die Lage mit der kleinsten Eindringtiefe.
	var beste := z_welt.duplicate()
	var beste_tiefe := 1e9
	var original := z_welt.duplicate()
	_anfang_tiefe = 0.0
	for durchlauf in 24:
		var posen := _posen(z_skel, z_welt, hip_pos, paare)
		m.posen_override = posen
		var erg: Dictionary = m.messen()
		var summe: float = erg["links"]["tiefe"] + erg["rechts"]["tiefe"]
		if durchlauf == 0:
			_anfang_tiefe = summe
		if summe < beste_tiefe - 1e-5:
			beste_tiefe = summe
			beste = z_welt.duplicate()
		if erg["links"]["tiefe"] <= 0.004 and erg["rechts"]["tiefe"] <= 0.004:
			break
		var bewegt := false
		for seite in ["links", "rechts"]:
			var r: Dictionary = erg[seite]
			if r["tiefe"] <= 0.004:
				continue
			var vorsilbe := "Left" if seite == "links" else "Right"
			var ia := z_skel.find_bone(vorsilbe + "Arm")
			var iu := z_skel.find_bone(vorsilbe + "ForeArm")
			if ia < 0 or iu < 0:
				continue
			# nicht weiter drehen, wenn der Arm schon sehr weit von der Ausgangslage weg ist
			if _winkel((z_welt[iu] as Quaternion) * (original[iu] as Quaternion).inverse()) > deg_to_rad(130.0):
				continue
			var w: Vector3 = r["punkt"]
			var delta: Vector3 = r["schub"] * 1.15
			var s_: Vector3 = (posen[ia] as Transform3D).origin
			var e: Vector3 = (posen[iu] as Transform3D).origin
			var q2 := _dreh_um(e, w, delta, 0.8)
			if _winkel(q2) > deg_to_rad(25.0):
				q2 = Quaternion(q2.get_axis(), deg_to_rad(25.0))
			var q3 := _dreh_um(s_, w, delta, 0.6)
			if _winkel(q3) > deg_to_rad(20.0):
				q3 = Quaternion(q3.get_axis(), deg_to_rad(20.0))
			for bb in _unterbaum(z_skel, iu):
				z_welt[bb] = q2 * (z_welt[bb] as Quaternion)
			for bb in _unterbaum(z_skel, ia):
				z_welt[bb] = q3 * (z_welt[bb] as Quaternion)
			bewegt = true
		if not bewegt:
			break
	for i in z_welt.size():
		z_welt[i] = beste[i]
	if DEBUG_LEAN and _clip.begins_with("Sitting Yell") and absf(_dbg_zeit - 0.158) < 0.02:
		var pp := _posen(z_skel, z_welt, hip_pos, paare)
		print("   DBG t=%.3f Hand links %s  Hips %s  Anfang %.0f mm  Ende %.0f mm" % [_dbg_zeit, str(pp[z_skel.find_bone("LeftHand")].origin), str(pp[0].origin), _anfang_tiefe * 1000.0, beste_tiefe * 1000.0])
	if DEBUG_LEAN and beste_tiefe > 0.03:
		print("      Rest-Durchstoß %.0f mm (Ausgang %.0f mm)" % [beste_tiefe * 1000.0, _anfang_tiefe * 1000.0])
	m.posen_override.clear()

## Globale Knochenlagen (Skelett-Raum) aus den globalen Drehungen: Position = Elternposition + Elterndrehung * Ruhe-Versatz
func _posen(z_skel: Skeleton3D, z_welt: Array, hip_pos: Vector3, _paare: Array) -> Array[Transform3D]:
	var r: Array[Transform3D] = []
	for b in z_skel.get_bone_count():
		var p := z_skel.get_bone_parent(b)
		var pos := hip_pos if p < 0 else r[p].origin + (z_welt[p] as Quaternion) * z_skel.get_bone_rest(b).origin
		r.append(Transform3D(Basis(z_welt[b] as Quaternion), pos))
	return r

## Gemittelte Korrektur-Drehung eines Knochens um das Bild i (Fenster +-GLAETT_FENSTER Bilder). Für den Unterarm ist `arm_delta`
## die Drehung des Oberarms, die schon im Unterarm steckt (nur die zusätzliche Drehung zählt).
const GLAETT_FENSTER := 3

func _mittel_delta(fertig: Array, urspruenge: Array, i: int, bone: int, arm_delta: Variant) -> Quaternion:
	var summe := Quaternion(0, 0, 0, 0)
	var bezug := Quaternion.IDENTITY
	var n := fertig.size()
	var gewicht_summe := 0.0
	for k in range(-GLAETT_FENSTER, GLAETT_FENSTER + 1):
		var j := clampi(i + k, 0, n - 1)
		var delta: Quaternion = (fertig[j][bone] as Quaternion) * (urspruenge[j][bone] as Quaternion).inverse()
		if arm_delta != null:
			# Unterarm: Gesamtdrehung ohne den Anteil des Oberarms dieses Bildes
			var arm_j := _arm_delta_bild(fertig, urspruenge, j, bone)
			delta = delta * arm_j.inverse()
		if delta.dot(bezug) < 0.0:
			delta = -delta
		var w := 1.0 + float(GLAETT_FENSTER + 1 - absi(k))
		summe += delta * w
		gewicht_summe += w
	return summe.normalized() if summe.length() > 1e-6 else Quaternion.IDENTITY

var _arm_von_unterarm := {}

func _arm_delta_bild(fertig: Array, urspruenge: Array, j: int, unterarm: int) -> Quaternion:
	var skel_arm: int = _arm_von_unterarm.get(unterarm, -1)
	if skel_arm < 0:
		return Quaternion.IDENTITY
	return (fertig[j][skel_arm] as Quaternion) * (urspruenge[j][skel_arm] as Quaternion).inverse()

## Der Knochen und alle, die an ihm hängen
func _unterbaum(skel: Skeleton3D, wurzel: int) -> Array[int]:
	var r: Array[int] = []
	for b in skel.get_bone_count():
		var n := b
		while n >= 0:
			if n == wurzel:
				r.append(b)
				break
			n = skel.get_bone_parent(n)
	return r

func _winkel(q: Quaternion) -> float:
	return 2.0 * acos(clampf(absf(q.w), 0.0, 1.0))

## Drehung um `pivot`, die `punkt` um `delta` weiter heraus bewegt (nur der Teil quer zum Arm zählt)
func _dreh_um(pivot: Vector3, punkt: Vector3, delta: Vector3, gewicht: float) -> Quaternion:
	var r := punkt - pivot
	var laenge := r.length()
	if laenge < 0.01:
		return Quaternion.IDENTITY
	var achse := r.cross(delta)
	if achse.length() < 1e-6:
		return Quaternion.IDENTITY
	var quer := delta - r / laenge * (delta.dot(r) / laenge)
	return Quaternion(achse.normalized(), atan2(quer.length(), laenge) * gewicht)

## Verschiebung, die einen Punkt aus Kopf (Ellipsoid mit Haar/Hut), Rumpf und Beinen (Kapseln mit Kleidung) herausbringt
func _raus(p: Vector3, vol: Dictionary) -> Vector3:
	var best := Vector3.ZERO
	var kopf: Variant = vol["kopf"]
	if kopf != null:
		var c: Vector3 = kopf[0]
		var achse: Vector3 = kopf[1]
		var d := p - c
		var laengs := d.dot(achse)
		var quer := d - achse * laengs
		var f := (laengs / 0.34) * (laengs / 0.34) + quer.length_squared() / (0.29 * 0.29)
		if f < 1.0:
			var push := Vector3(0, 0, 0.3) if f < 1e-6 else d / sqrt(f) - d
			if push.length() > best.length():
				best = push
	for kap: Array in vol["kapseln"]:
		var a: Vector3 = kap[0]
		var b: Vector3 = kap[1]
		var r: float = kap[2]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		var nah := a + ab * t
		var d := p - nah
		var l := d.length()
		if l < r:
			# Richtung: weg von der Achse, bei Punkten auf der Achse nach vorn
			var raus_richtung := d / l if l > 1e-5 else Vector3(0, 0, 1)
			var push := raus_richtung * (r - l)
			if push.length() > best.length():
				best = push
	return best

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
