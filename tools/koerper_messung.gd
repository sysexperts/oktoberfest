extends RefCounted
## Misst, wie tief Hände und Unterarme in Rumpf, Oberschenkel oder Kopf stecken (mit Abstand für Kleidung, Haar und Hut).
## Gebraucht von tools/test_animationen.gd (Prüfung) und tools/bake_animationen.gd (Nachkorrektur beim Umrechnen).
## Das Skelett steht in der Pose, die geprüft werden soll; die Netze werden auf der CPU geskinnt.

## Abstand (m), den Hände zur Körperoberfläche mindestens haben sollen: Kleidung am Rumpf, Haar/Hut am Kopf
const ABSTAND_RUMPF := 0.03
const ABSTAND_KOPF := 0.07
const ZELLE := 0.05

var sk: Skeleton3D
var koerper: MeshInstance3D
var haende: Array[MeshInstance3D] = []
var _rumpf_namen := ["Hips", "Spine02", "Spine01", "Spine", "neck", "Head", "head_end", "headfront", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg"]
var _kopf_namen := ["neck", "Head", "head_end", "headfront"]
var _arm_namen := ["LeftForeArm", "RightForeArm", "LeftHand", "RightHand", "LeftHand_End", "RightHand_End"]
## Nur jeder n-te Punkt der Handnetze wird geprüft (Tempo)
var hand_schritt := 7
## Wenn gesetzt: globale Knochenlagen (Skelett-Raum) statt der vom Skelett gemeldeten (für Skelette außerhalb des Baums, deren
## Lage sich nach set_bone_pose_* nicht zuverlässig aktualisiert)
var posen_override: Array[Transform3D] = []

func _init(skelett: Skeleton3D) -> void:
	sk = skelett
	for mi: MeshInstance3D in sk.find_children("*", "MeshInstance3D", false, false):
		if mi.name == "Koerper":
			koerper = mi
		elif String(mi.name).begins_with("Hand"):
			haende.append(mi)

## Ergebnis je Seite ("links", "rechts"): {tiefe (m), punkt, schub (Vektor, der den Punkt aus dem Körper bringt), hand (bool), wo}
func messen() -> Dictionary:
	var k := skinnen(koerper)
	var P: Array = k[0]
	var N: Array = k[1]
	var I: Array = k[2]
	var D: Array = k[3]
	var dreiecke: Array = []
	var gitter := {}
	for t in range(0, I.size(), 3):
		var d0: String = sk.get_bone_name(D[I[t]])
		if not (d0 in _rumpf_namen and sk.get_bone_name(D[I[t + 1]]) in _rumpf_namen and sk.get_bone_name(D[I[t + 2]]) in _rumpf_namen):
			continue
		var a: Vector3 = P[I[t]]
		var b: Vector3 = P[I[t + 1]]
		var c: Vector3 = P[I[t + 2]]
		var n := (b - a).cross(c - a)
		if n.length() < 1e-12:
			continue
		n = n.normalized()
		if n.dot((N[I[t]] as Vector3) + (N[I[t + 1]] as Vector3) + (N[I[t + 2]] as Vector3)) < 0.0:
			n = -n
		var idx := dreiecke.size()
		dreiecke.append([a, b, c, n, ABSTAND_KOPF if d0 in _kopf_namen else ABSTAND_RUMPF, d0])
		var z := Vector3i(((a + b + c) / 3.0 / ZELLE).floor())
		if not gitter.has(z):
			gitter[z] = []
		gitter[z].append(idx)
	var punkte: Array = []
	for h in haende:
		var hp: Array = skinnen(h)[0]
		var seite := "links" if String(h.name).contains("Left") else "rechts"
		for i in range(0, hp.size(), hand_schritt):
			punkte.append([hp[i], seite, true])
	for i in range(0, P.size(), 2):
		var bn: String = sk.get_bone_name(D[i])
		if bn in _arm_namen:
			punkte.append([P[i], "links" if bn.begins_with("Left") else "rechts", false])
	var erg := {"links": {"tiefe": 0.0, "punkt": Vector3.ZERO, "schub": Vector3.ZERO, "hand": true, "wo": ""},
		"rechts": {"tiefe": 0.0, "punkt": Vector3.ZERO, "schub": Vector3.ZERO, "hand": true, "wo": ""}}
	for e: Array in punkte:
		var w: Vector3 = e[0]
		var z := Vector3i((w / ZELLE).floor())
		var bestabs := 0.15
		var bestp := 1.0
		var best_m := ABSTAND_RUMPF
		var best_n := Vector3.UP
		var best_bone := ""
		var best_c := Vector3.ZERO
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for dz in range(-1, 2):
					var lst: Variant = gitter.get(z + Vector3i(dx, dy, dz))
					if lst == null:
						continue
					for i: int in lst:
						var d: Array = dreiecke[i]
						var c := naechster(w, d[0], d[1], d[2])
						var abstand := w.distance_to(c)
						if abstand >= bestabs:
							continue
						bestabs = abstand
						var vorz := (w - c).dot(d[3] as Vector3)
						bestp = abstand if vorz >= 0.0 else -abstand
						best_m = d[4]
						best_n = d[3]
						best_bone = d[5]
						best_c = c
		if bestp < 1.0 and bestp < best_m:
			var tiefe := best_m - bestp
			var r: Dictionary = erg[e[1]]
			if tiefe > r["tiefe"]:
				r["tiefe"] = tiefe
				r["punkt"] = w
				r["schub"] = best_n * tiefe
				# Hand zwischen den Beinen: nicht in das andere Bein hineinschieben, sondern zur eigenen Seite herausführen
				if best_bone.ends_with("UpLeg") or best_bone.ends_with("Leg"):
					if absf(w.x) < 0.14:
						r["schub"] = Vector3(1.0 if e[1] == "links" else -1.0, 0.0, 0.0) * (tiefe + 0.12)
				r["hand"] = e[2]
				r["wo"] = "%s %s %s [%s, Dreieck bei %s, p=%.0f mm]" % ["Hand" if e[2] else "Unterarm", e[1], "im Kopf" if best_m == ABSTAND_KOPF else "im Körper", best_bone, str(snapped(best_c, Vector3(0.01, 0.01, 0.01))), bestp * 1000.0]
	return erg

## Nächster Punkt eines Dreiecks zu p (Ericson, Real-Time Collision Detection)
func naechster(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b - a
	var ac := c - a
	var ap := p - a
	var d1 := ab.dot(ap)
	var d2 := ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp := p - b
	var d3 := ab.dot(bp)
	var d4 := ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc := d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / (d1 - d3))
	var cp := p - c
	var d5 := ab.dot(cp)
	var d6 := ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb := d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6))
	var va := d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))
	var denom := 1.0 / (va + vb + vc)
	return a + ab * (vb * denom) + ac * (vc * denom)

## Geskinnte Punkte, Normalen, Indizes und Hauptknochen eines Netzes (Skelett-Raum)
func skinnen(mi: MeshInstance3D) -> Array:
	var skin := mi.skin
	var matr: Array[Transform3D] = []
	var knochen: Array[int] = []
	for i in skin.get_bind_count():
		var bn := skin.get_bind_name(i)
		var idx := skin.get_bind_bone(i) if bn == "" else sk.find_bone(bn)
		knochen.append(idx)
		var gp := (posen_override[idx] if not posen_override.is_empty() else sk.get_bone_global_pose(idx)) if idx >= 0 else Transform3D()
		matr.append(gp * skin.get_bind_pose(i) if idx >= 0 else Transform3D())
	var P: Array = []
	var N: Array = []
	var I: Array = []
	var D: Array = []
	for s in mi.mesh.get_surface_count():
		var a := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var nr: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var b: PackedInt32Array = a[Mesh.ARRAY_BONES]
		var w: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
		var ind: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		var off := P.size()
		for x in ind:
			I.append(x + off)
		var pro := b.size() / v.size()
		for i in v.size():
			var bas := Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)
			var org := Vector3.ZERO
			var wmax := 0.0
			var dom := -1
			for q in pro:
				var wi := w[i * pro + q]
				if wi <= 0.0:
					continue
				if wi > wmax:
					wmax = wi
					dom = knochen[b[i * pro + q]]
				var m := matr[b[i * pro + q]]
				bas = Basis(bas.x + m.basis.x * wi, bas.y + m.basis.y * wi, bas.z + m.basis.z * wi)
				org += m.origin * wi
			P.append(bas * v[i] + org)
			N.append((bas * nr[i]).normalized())
			D.append(dom)
	return [P, N, I, D]
