extends Node
## Prüft alle Animationen auf Durchstöße der Hände und Unterarme in Rumpf, Oberschenkel und Kopf (mit Abstand für Kleidung,
## Haar und Hut): für jede Animation werden mehrere Zeitpunkte abgetastet, die Körpernetze auf der CPU geskinnt (wie sie das
## Spiel zeichnet, auch mit dem Aufrichten-Modifier der älteren Clips) und mit tools/koerper_messung.gd gemessen.
## Ergebnis: Liste, schlimmste zuerst; build/animationen_clipping.txt.
## godot --headless --path . res://tools/test_animationen.tscn                  (alle)
## godot --headless --path . res://tools/test_animationen.tscn -- mixamo/Idle   (nur diese, mit Einzelheiten)
const Look := preload("res://scripts/charakter_look.gd")
const Messung := preload("res://tools/koerper_messung.gd")

var PROBEN := 60
const TOLERANZ_MM := 8.0

var _m: RefCounted

func _ready() -> void:
	var l := Look.standard("m")
	for a in Look.KLEIDER:
		l[a] = "ohne"
	var f := Look.bauen(l)
	add_child(f)
	await get_tree().process_frame
	await get_tree().process_frame
	_m = Messung.new(f.skelett)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		PROBEN = 160
	var namen: Array[String] = []
	if args.is_empty():
		for n in f.anim.get_animation_list():
			if String(n) != "RESET":
				namen.append(String(n))
		namen.sort()
	else:
		namen.append(args[0])
	var ergebnis: Array = []
	for n in namen:
		var r := await _pruefen(f, n, not args.is_empty())
		if not r.is_empty():
			ergebnis.append(r)
	ergebnis.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["mm"] > b["mm"])
	var text := ""
	var schlecht := 0
	for r: Dictionary in ergebnis:
		var zeile := "%-42s %6.1f mm  bei %.0f %%  (%s)%s" % [r["name"], r["mm"], r["t"] * 100.0, r["wo"], "" if r["mm"] <= TOLERANZ_MM else "   <-- Durchstoß"]
		text += zeile + "\n"
		if r["mm"] > TOLERANZ_MM:
			schlecht += 1
		print(zeile)
	var datei := FileAccess.open("res://build/animationen_clipping.txt", FileAccess.WRITE)
	datei.store_string(text)
	datei.close()
	print("Animationen mit Durchstoß: ", schlecht, " von ", ergebnis.size())
	get_tree().quit()

func _pruefen(f: Figur, name: String, genau: bool) -> Dictionary:
	f.anim.stop()
	if not f.abspielen(name):
		return {}
	f.anim.pause()
	var laenge := f.anim.get_animation(name).length
	var schlimm := 0.0
	var wann := 0.0
	var wo := ""
	var zeiten: Array[float] = []
	var args := OS.get_cmdline_user_args()
	if args.size() > 2:
		# explizite Zeiten in Sekunden: -- <Animation> von bis schritt
		var z0 := float(args[1])
		while z0 <= float(args[2]) + 1e-6:
			zeiten.append(z0 / laenge)
			z0 += float(args[3]) if args.size() > 3 else 0.005
	else:
		for i in PROBEN:
			zeiten.append(float(i) / PROBEN)
	for t in zeiten:
		f.anim.seek(t * laenge, true)
		await get_tree().process_frame
		f.skelett.advance(0.0)
		var erg: Dictionary = _m.messen()
		if genau:
			print("   DBG t=%.3f Hand links %s Hips %s" % [t * laenge, str(f.skelett.get_bone_global_pose(f.skelett.find_bone("LeftHand")).origin), str(f.skelett.get_bone_global_pose(0).origin)])
		for seite in ["links", "rechts"]:
			var r: Dictionary = erg[seite]
			if genau and r["tiefe"] > 0.0:
				print("  t=%.2f  %.1f mm  %s  bei %s" % [t, r["tiefe"] * 1000.0, r["wo"], str(snapped(r["punkt"], Vector3(0.01, 0.01, 0.01)))])
			if r["tiefe"] > schlimm:
				schlimm = r["tiefe"]
				wann = t
				wo = r["wo"]
	return {"name": name, "mm": schlimm * 1000.0, "t": wann, "wo": wo}
