extends SkeletonModifier3D
## Richtet Rücken, Nacken und Kopf nach der laufenden Animation auf. Die
## gemeinsamen Clips (Idle, Gehen) lassen den Kopf hängen — mit diesem Modifier
## stehen alle Figuren aufrechter. Gedreht wird im Figur-Raum um die Querachse, damit
## es auf jedem Rig gleich wirkt. Figur.haltung_an() hängt ihn ans Skelett.
## Ohne class_name (neue Klassennamen brauchen auf dem Server eine Neuindizierung).

## Winkel in Grad, positiv = aufrichten (Oberkörper/Kopf nach hinten)
var ruecken := 0.0
var nacken := 0.0
var kopf := 0.0
## Becken kippen (die Oberschenkel gleichen es aus) und Oberschenkel zusätzlich neigen
var huefte := 0.0
var beine := 0.0
## Oberarme nach außen (Grad)
var arme := 0.0
## Zusätzlich nach außen (Grad), aber nur solange die Hand hoch oben ist (Kopf kratzen)
var arme_hoch := 0.0
## Ellbogen öffnen (Grad), solange die Hand oben am Kopf ist: die Hand landet vor dem Gesicht statt darin
var ellbogen_auf := 0.0
## Schultern waagerecht richten (0 = aus, 1 = ganz): der Idle-Clip lässt den Körper schief stehen
var waage := 0.0
## Figur-Wurzel: +Z vorn, X = Querachse
var figur: Node3D

const ROLLEN := ["huefte", "oberschenkel_l", "oberschenkel_r", "wirbel_unten", "wirbel_mitte", "wirbel_oben", "nacken", "kopf"]

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or figur == null:
		return
	# Gestellte Posen (Würgen, Winken …) schalten die Animation ab — dann nichts ändern
	if figur.anim and not figur.anim.active:
		return
	var achse := (sk.global_basis.orthonormalized().inverse() * figur.global_basis.orthonormalized() * Vector3.RIGHT).normalized()
	# Rücken auf drei Wirbel verteilt, Kopfneigung auf Nacken und Kopf
	if waage > 0.0:
		_waage(sk, achse)
	var winkel := {
		"wirbel_unten": ruecken / 3.0, "wirbel_mitte": ruecken / 3.0, "wirbel_oben": ruecken / 3.0,
		"nacken": nacken, "kopf": kopf, "huefte": huefte,
		# Das gekippte Becken nimmt die Beine mit — hier wieder zurückdrehen
		"oberschenkel_l": -huefte + beine, "oberschenkel_r": -huefte + beine,
	}
	for rolle: String in ROLLEN:
		var b := _knochen(sk, rolle)
		if b < 0 or is_zero_approx(winkel[rolle]):
			continue
		var eltern := sk.get_bone_parent(b)
		var eltern_rot := Quaternion.IDENTITY if eltern < 0 else sk.get_bone_global_pose(eltern).basis.orthonormalized().get_rotation_quaternion()
		var jetzt := sk.get_bone_global_pose(b).basis.orthonormalized().get_rotation_quaternion()
		var dreh := Quaternion(achse, -deg_to_rad(winkel[rolle]))
		sk.set_bone_pose_rotation(b, eltern_rot.inverse() * dreh * jetzt)

	if not is_zero_approx(arme) or not is_zero_approx(arme_hoch) or not is_zero_approx(ellbogen_auf):
		var vor := (sk.global_basis.orthonormalized().inverse() * figur.global_basis.orthonormalized() * Vector3.BACK).normalized()
		# Links liegt bei +X (Figur schaut nach +Z): dort nach +X, rechts nach -X
		_ellbogen(sk, "unterarm_l", "arm_l", "hand_l", 1.0)
		_ellbogen(sk, "unterarm_r", "arm_r", "hand_r", 1.0)
		_arm(sk, "arm_l", vor, deg_to_rad(arme + arme_hoch * _hand_hoch(sk, "arm_l", "hand_l")))
		_arm(sk, "arm_r", vor, -deg_to_rad(arme + arme_hoch * _hand_hoch(sk, "arm_r", "hand_r")))

## Neigung der Schulterlinie messen und mit dem unteren Wirbel ausgleichen
func _waage(sk: Skeleton3D, _quer: Vector3) -> void:
	var l := _knochen(sk, "arm_l")
	var r := _knochen(sk, "arm_r")
	var w := _knochen(sk, "wirbel_unten")
	if l < 0 or r < 0 or w < 0:
		return
	var zu_figur := figur.global_basis.orthonormalized().inverse() * sk.global_basis.orthonormalized()
	var linie: Vector3 = zu_figur * (sk.get_bone_global_pose(l).origin - sk.get_bone_global_pose(r).origin)
	# Links liegt bei +X: ist die Linie geneigt, steht y(links) höher oder tiefer als y(rechts)
	var neigung := atan2(linie.y, linie.x) * waage
	var achse_z := (sk.global_basis.orthonormalized().inverse() * figur.global_basis.orthonormalized() * Vector3.BACK).normalized()
	var eltern := sk.get_bone_parent(w)
	var eltern_rot := Quaternion.IDENTITY if eltern < 0 else sk.get_bone_global_pose(eltern).basis.orthonormalized().get_rotation_quaternion()
	var jetzt := sk.get_bone_global_pose(w).basis.orthonormalized().get_rotation_quaternion()
	sk.set_bone_pose_rotation(w, eltern_rot.inverse() * Quaternion(achse_z, -neigung) * jetzt)

## 0 = Hand hängt unten, 1 = Hand ist auf Kopfhöhe (gemessen im Figur-Raum über der Schulter)
func _hand_hoch(sk: Skeleton3D, arm_rolle: String, hand_rolle: String) -> float:
	var a := _knochen(sk, arm_rolle)
	var h := _knochen(sk, hand_rolle)
	if a < 0 or h < 0:
		return 0.0
	var zu_figur := figur.global_basis.orthonormalized().inverse() * sk.global_basis.orthonormalized()
	var dy: float = (zu_figur * (sk.get_bone_global_pose(h).origin - sk.get_bone_global_pose(a).origin)).y
	return clampf((dy + 0.25) / 0.3, 0.0, 1.0)

func _ellbogen(sk: Skeleton3D, unterarm: String, arm: String, hand: String, richtung: float) -> void:
	if is_zero_approx(ellbogen_auf):
		return
	var f := _hand_hoch(sk, arm, hand)
	if f <= 0.0:
		return
	var b := _knochen(sk, unterarm)
	if b < 0:
		return
	var quer := (sk.global_basis.orthonormalized().inverse() * figur.global_basis.orthonormalized() * Vector3.RIGHT).normalized()
	var eltern := sk.get_bone_parent(b)
	var eltern_rot := Quaternion.IDENTITY if eltern < 0 else sk.get_bone_global_pose(eltern).basis.orthonormalized().get_rotation_quaternion()
	var jetzt := sk.get_bone_global_pose(b).basis.orthonormalized().get_rotation_quaternion()
	sk.set_bone_pose_rotation(b, eltern_rot.inverse() * Quaternion(quer, deg_to_rad(ellbogen_auf) * f * richtung) * jetzt)

func _arm(sk: Skeleton3D, rolle: String, achse: Vector3, winkel: float) -> void:
	var b := _knochen(sk, rolle)
	if b < 0:
		return
	var eltern := sk.get_bone_parent(b)
	var eltern_rot := Quaternion.IDENTITY if eltern < 0 else sk.get_bone_global_pose(eltern).basis.orthonormalized().get_rotation_quaternion()
	var jetzt := sk.get_bone_global_pose(b).basis.orthonormalized().get_rotation_quaternion()
	sk.set_bone_pose_rotation(b, eltern_rot.inverse() * Quaternion(achse, winkel) * jetzt)

func _knochen(sk: Skeleton3D, rolle: String) -> int:
	for name: String in Figur.KNOCHEN_NAMEN[rolle]:
		var b := sk.find_bone(name)
		if b >= 0:
			return b
	return -1
