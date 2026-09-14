extends SkeletonModifier3D
## Kampfbewegungen über die Knochen der Figur: Deckung, Faustschläge links und
## rechts, Treffer-Reaktion (Oberkörper und Kopf fliegen zurück) und Zappeln beim
## Gepacktwerden. Legt sich über die laufende Animation (stehen, gehen, rennen).
##
## Vorläufig, bis echte Kampfanimationen aus Meshy da sind — die Figuren haben alle
## dasselbe Skelett (RightArm, RightForeArm, Spine01, neck …). Die Knochen werden
## über Richtungen ausgerichtet („Oberarm zeigt nach vorn"), nicht über feste
## Winkel — so passt es zu allen drei Modellen, egal wie ihre Knochenachsen liegen.
## Wird zur Laufzeit an das Skelett gehängt (die Figur wird erst dann gewählt).

## 0 … 1: Fäuste hoch vor dem Gesicht
var haltung := 0.0
## 0 … 1: Arm ausgestreckt nach vorn
var schlag_rechts := 0.0
var schlag_links := 0.0
## -1 … 1: Oberkörper nach hinten (Treffer) bzw. vorn
var treffer := 0.0
## 0 … 1: Arme rudern wild (gepackt, fliegt)
var zappeln := 0.0

var _t := 0.0
var _figur: Node3D

func _ready() -> void:
	var n := get_parent()
	while n != null and not n is Figur:
		n = n.get_parent()
	_figur = n as Node3D

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or _figur == null:
		return
	_t += get_process_delta_time()
	# Richtungen der Figur im Skelettraum (Modelle schauen in Ruhe nach +Z)
	var inv := sk.global_transform.basis.inverse()
	var vorn := (inv * _figur.global_transform.basis.z).normalized()
	var oben := (inv * _figur.global_transform.basis.y).normalized()
	var links := oben.cross(vorn).normalized()
	if absf(treffer) > 0.001:
		_kippen(sk, "Spine01", links, -0.5 * treffer)
		_kippen(sk, "neck", links, -0.55 * treffer)
	_arm(sk, "Right", -1.0, schlag_rechts, vorn, oben, links)
	_arm(sk, "Left", 1.0, schlag_links, vorn, oben, links)

func _arm(sk: Skeleton3D, seite: String, sx: float, stoss: float, vorn: Vector3, oben: Vector3, links: Vector3) -> void:
	var gewicht := maxf(maxf(haltung, stoss), zappeln)
	if gewicht <= 0.001:
		return
	var ober := sk.find_bone(seite + "Arm")
	var unter := sk.find_bone(seite + "ForeArm")
	var hand := sk.find_bone(seite + "Hand")
	# Deckung: Oberarm leicht nach vorn-unten, Unterarm hoch vors Gesicht
	var ober_ziel := (links * (0.35 * sx) - oben * 0.55 + vorn * 0.75).normalized()
	var unter_ziel := (links * (-0.4 * sx) + oben * 0.8 + vorn * 0.45).normalized()
	# Schlag: ganzer Arm gerade nach vorn zur Mitte
	var stoss_ziel := (links * (-0.12 * sx) + oben * 0.12 + vorn).normalized()
	ober_ziel = ober_ziel.slerp(stoss_ziel, stoss)
	unter_ziel = unter_ziel.slerp(stoss_ziel, stoss)
	if zappeln > 0.001:
		var w := sin(_t * 15.0 + sx * 1.3)
		var ober_wild := (links * (0.8 * sx) + oben * (0.7 * w) + vorn * 0.2).normalized()
		var unter_wild := (links * (0.4 * sx) - oben * (0.8 * w) + vorn * 0.4).normalized()
		ober_ziel = ober_ziel.slerp(ober_wild, zappeln)
		unter_ziel = unter_ziel.slerp(unter_wild, zappeln)
	_richte(sk, ober, unter, ober_ziel, gewicht)
	_richte(sk, unter, hand, unter_ziel, gewicht)

## Knochen so drehen, dass er (Richtung zum Kindknochen) zum Ziel zeigt.
func _richte(sk: Skeleton3D, knochen: int, kind: int, ziel: Vector3, gewicht: float) -> void:
	if knochen < 0 or kind < 0:
		return
	var g := sk.get_bone_global_pose(knochen)
	var ist := sk.get_bone_global_pose(kind).origin - g.origin
	if ist.length() < 0.00001:
		return
	var q := Quaternion(ist.normalized(), ziel)
	q = Quaternion.IDENTITY.slerp(q, clampf(gewicht, 0.0, 1.0))
	sk.set_bone_global_pose(knochen, Transform3D(Basis(q) * g.basis, g.origin))

func _kippen(sk: Skeleton3D, name_knochen: String, achse: Vector3, winkel: float) -> void:
	var b := sk.find_bone(name_knochen)
	if b < 0:
		return
	var g := sk.get_bone_global_pose(b)
	sk.set_bone_global_pose(b, Transform3D(Basis(achse, winkel) * g.basis, g.origin))
