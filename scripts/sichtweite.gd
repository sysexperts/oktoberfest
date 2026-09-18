extends RefCounted
## Leistung: kleine Teile in der Ferne nicht mehr zeichnen, Lichter ausblenden.
## Die Karte besteht aus zehntausenden Einzel-Meshes (Buden, Deko, Bäume) — ohne
## Sichtweite zeichnet jedes Bild alle davon (Messung 18.09.: 59.000 Aufrufe am Tor).
## Nur Darstellung: Knoten, Kollision und Skripte bleiben unberührt.
##
## Größe = längste Kante des Meshes (mit Skalierung) → Sichtweite in Metern.
const STUFEN := [[0.35, 22.0], [1.0, 40.0], [2.5, 75.0], [6.0, 140.0]]
const LICHT_AB := 30.0
const LICHT_UEBER := 12.0

static func anwenden(wurzel: Node) -> void:
	for n in wurzel.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if g.visibility_range_end > 0.0:
			continue   # schon von Hand gesetzt
		var groesse := _groesse(g)
		for s: Array in STUFEN:
			if groesse <= float(s[0]):
				g.visibility_range_end = float(s[1])
				g.visibility_range_end_margin = 2.0
				break
	for n in wurzel.find_children("*", "Light3D", true, false):
		var l := n as Light3D
		if l is DirectionalLight3D:
			continue
		l.distance_fade_enabled = true
		l.distance_fade_begin = LICHT_AB
		l.distance_fade_length = LICHT_UEBER

static func _groesse(g: GeometryInstance3D) -> float:
	var box := g.get_aabb()
	var s := g.global_transform.basis.get_scale() if g.is_inside_tree() else Vector3.ONE
	return maxf(box.size.x * absf(s.x), maxf(box.size.y * absf(s.y), box.size.z * absf(s.z)))
