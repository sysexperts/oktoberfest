extends Node
## Misst, ob Kleidungsschichten sich durchstoßen (Körper < Hemd < Hose < Jacke): für jede Kombination und
## mehrere Posen werden die Netze auf der CPU geskinnt. Wie weit eine innere Schicht die äußere durchstößt, muss
## kleiner sein als der Tiefenvorrang-Unterschied beider (Look.TIEFE) — den macht der Kleidungs-Shader unsichtbar. godot --headless --path . res://tools/test_clipping.tscn
## Optional: -- hemd_karo jacke_janker hose_leder  (nur diese Kombination)
const Look := preload("res://scripts/charakter_look.gd")

const MIN_ABSTAND := 0.004
const ZELLE := 0.04
const POSEN := ["Idle_12", "Casual_Walk", "Run_02", "Hip_Hop_Dance", "Sit_and_Drink", "Unsteady_Walk", "ymca_dance", "Confused_Scratch"]
const ZEITEN := [0.0, 0.2, 0.4, 0.6, 0.8]
const REIHENFOLGE := ["koerper", "hemd", "hose", "jacke"]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var kombis: Array = []
	if args.size() == 3:
		kombis.append([args[0], args[1], args[2]])
	else:
		for h: Dictionary in Look.liste("hemd", "m"):
			for j: Dictionary in Look.liste("jacke", "m"):
				for o: Dictionary in Look.liste("hose", "m"):
					kombis.append([h["id"], j["id"], o["id"]])
	if args.is_empty():
		for d: Dictionary in Look.Assets.DIRNDLE:
			kombis.append([d["hemd"], d["jacke"], d["hose"], "w"])
	var schlecht := {}
	var worst := {}
	var worst_pose := {}
	var geprueft := 0
	for k: Array in kombis:
		var l := Look.standard("w" if k.size() > 3 else "m")
		l["hemd"] = k[0]; l["jacke"] = k[1]; l["hose"] = k[2]
		var f := Look.bauen(l)
		add_child(f)
		Look.faerben(f, l)
		await get_tree().process_frame
		_sk = f.skelett
		f.anim.stop()
		f.skelett.reset_bone_poses()
		var ruhe := _schichten(f)
		var paar_cache := {}
		for i in REIHENFOLGE.size():
			for j in range(i + 1, REIHENFOLGE.size()):
				if ruhe.has(REIHENFOLGE[i]) and ruhe.has(REIHENFOLGE[j]):
					paar_cache["%d_%d" % [i, j]] = _paare(ruhe[REIHENFOLGE[i]], ruhe[REIHENFOLGE[j]])
		for pose: String in POSEN:
			if not f.anim.has_animation(pose):
				var ersatz := ""
				for n in f.anim.get_animation_list():
					if String(n).ends_with(pose):
						ersatz = n
				if ersatz == "":
					continue
				pose = ersatz
			var laenge := f.anim.get_animation(pose).length
			for z: float in ZEITEN:
				f.anim.play(pose)
				f.anim.seek(z * laenge, true)
				var schichten := _schichten(f)
				for i in REIHENFOLGE.size():
					for j in range(i + 1, REIHENFOLGE.size()):
						var innen: Array = schichten.get(REIHENFOLGE[i], [])
						var aussen: Array = schichten.get(REIHENFOLGE[j], [])
						if innen.is_empty() or aussen.is_empty():
							continue
						ruhe_ort = ruhe[REIHENFOLGE[j]][0]
						var m := -_messen(innen, aussen, paar_cache["%d_%d" % [i, j]])
						var paar := "%s unter %s" % [REIHENFOLGE[i], REIHENFOLGE[j]]
						if m > worst.get(paar, -1e9):
							worst[paar] = m
						geprueft += 1
						if m > 0.036 and paar == "koerper unter hemd" and k[0] == "bluse":
							print("   DETAIL ", pose.get_file(), "@", z, " ", snappedf(m * 1000, 0.1), "mm bei ", _ort, " ", _knochen)
						var pk := paar + " | " + pose.get_file()
						if m > worst_pose.get(pk, -1e9):
							worst_pose[pk] = m
						var erlaubt: float = _tiefe(REIHENFOLGE[j], k, REIHENFOLGE[i] == "koerper") - _tiefe(REIHENFOLGE[i], k, false) - 0.002
						if m > erlaubt:
							var s := "%s/%s/%s" % [k[0], k[1], k[2]]
							schlecht[s] = schlecht.get(s, "") + " [%s %s@%.2f: %.1f mm]" % [paar, pose, z, m * 1000.0]
		f.queue_free()
		await get_tree().process_frame
	print("Messungen: ", geprueft)
	for p: String in worst:
		print("  schlimmster Wert %-22s %6.1f mm" % [p, worst[p] * 1000.0])
	var ks: Array = worst_pose.keys()
	ks.sort()
	for pk: String in ks:
		var teile := pk.split(" | ")[0].split(" unter ")
		if worst_pose[pk] > _tiefe(teile[1], ["bluse"], teile[0] == "koerper") - _tiefe(teile[0], ["bluse"], false) - 0.002:
			print("   ", pk, ": ", snappedf(worst_pose[pk] * 1000.0, 0.1), " mm")
	print("Kombinationen mit Durchstoß: ", schlecht.size(), " von ", kombis.size())
	for sk: String in schlecht:
		print("  ", sk, schlecht[sk].left(300))
	print("ERGEBNIS: ", "BESTANDEN" if schlecht.is_empty() else "DURCHSTOSS")
	get_tree().quit()

## Tiefenvorrang einer Schicht (Haut = 0) bei dieser Kleidungskombination (Bluse hat mehr)
func _tiefe(schicht: String, k: Array, mit_skala: bool) -> float:
	if schicht == "koerper":
		return 0.0
	var skala := 1.0
	if schicht == "hemd" and mit_skala:
		skala = float(Look._eintrag("hemd", str(k[0])).get("tiefe_skala", 1.0))
	return Look.TIEFE.get(schicht, 0.0) * skala

## Geskinnte Punkte + Normalen je Schicht (Skelett-Raum)
func _schichten(f: Figur) -> Dictionary:
	var sk := f.skelett
	var res := {}
	for mi: MeshInstance3D in sk.find_children("*", "MeshInstance3D", false, false):
		var n := String(mi.name)
		var schicht := ""
		for art in ["hemd", "jacke", "hose"]:
			if n == art + "_farbe":
				schicht = art
		if schicht == "":
			if n.contains("_fest") or mi.skin == null or not (n.to_lower().contains("body") or n.to_lower().contains("koerper") or n.to_lower().contains("körper") or n.to_lower().contains("mesh")):
				continue
			schicht = "koerper"
		if mi.skin == null:
			continue
		var punkte := _skinnen(mi, sk)
		if not punkte.is_empty():
			if res.has(schicht):
				res[schicht][0].append_array(punkte[0])
				res[schicht][1].append_array(punkte[1])
				var off: int = res[schicht][0].size() - punkte[0].size()
				for x: int in punkte[2]:
					res[schicht][2].append(x + off)
				res[schicht][3].append_array(punkte[3])
			else:
				res[schicht] = punkte
	return res

func _skinnen(mi: MeshInstance3D, sk: Skeleton3D) -> Array:
	var skin := mi.skin
	var matr: Array[Transform3D] = []
	for i in skin.get_bind_count():
		var bn := skin.get_bind_name(i)
		var idx := skin.get_bind_bone(i) if bn == "" else sk.find_bone(bn)
		matr.append(sk.get_bone_global_pose(idx) * skin.get_bind_pose(i) if idx >= 0 else Transform3D())
	var P: Array = []
	var N: Array = []
	var I: Array = []
	var D: Array = []
	var knochen: Array[int] = []
	for i in skin.get_bind_count():
		var bn2 := skin.get_bind_name(i)
		knochen.append(skin.get_bind_bone(i) if bn2 == "" else sk.find_bone(bn2))
	for s in mi.mesh.get_surface_count():
		var a := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var nr: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var b: PackedInt32Array = a[Mesh.ARRAY_BONES]
		var w: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
		if b.is_empty() or nr.is_empty():
			return []
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

## Paare (innerer Punkt, äußerer Punkt), die in der Ruhepose übereinander liegen: der äußere Punkt hat
## innen entlang seiner Normalen einen Gegenpart. Offene Stellen (Ausschnitt, Saum) bilden keine Paare.
func _paare(innen: Array, aussen: Array) -> Array:
	var IP: Array = innen[0]
	var gitter := {}
	for i in IP.size():
		var z := Vector3i(((IP[i] as Vector3) / ZELLE).floor())
		if not gitter.has(z):
			gitter[z] = []
		gitter[z].append(i)
	var paare: Array = []
	var AP: Array = aussen[0]
	var AN: Array = aussen[1]
	for o in AP.size():
		var po: Vector3 = AP[o]
		var no: Vector3 = AN[o]
		var z := Vector3i((po / ZELLE).floor())
		var best := 0.05 * 0.05
		var bi := -1
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for dz in range(-1, 2):
					var l: Variant = gitter.get(z + Vector3i(dx, dy, dz))
					if l == null:
						continue
					for i: int in l:
						if innen[3][i] != aussen[3][o]:
							continue
						var v: Vector3 = (IP[i] as Vector3) - po
						var nk := v.dot(no)
						if nk >= 0.0 or absf(nk) < 0.7 * v.length():
							continue
						var d := v.length_squared()
						if d < best:
							best = d
							bi = i
		if bi >= 0:
			paare.append([bi, o])
	return paare

## Kleinster Abstand (innen → außen entlang der äußeren Normalen) über alle Paare; negativ = durchgestoßen
var _ort := Vector3.ZERO
var _knochen := ""
var _sk: Skeleton3D
var ruhe_ort: Array = []
func _messen(innen: Array, aussen: Array, paare: Array) -> float:
	var IP: Array = innen[0]
	var AP: Array = aussen[0]
	var AN: Array = aussen[1]
	var kleinst := 1e9
	for pr: Array in paare:
		var tiefe: float = ((AP[pr[1]] as Vector3) - (IP[pr[0]] as Vector3)).dot(AN[pr[1]] as Vector3)
		if tiefe < kleinst:
			kleinst = tiefe
			_ort = ruhe_ort[pr[1]] if ruhe_ort.size() > pr[1] else Vector3.ZERO
			_knochen = _sk.get_bone_name(aussen[3][pr[1]])
	return kleinst
