extends SceneTree
## Legt auf jedem Platz der Ausgabe (scenes/ausgabe.tscn) 16 Stellplätze an —
## vorher waren es 3 Krüge bzw. 2 Teller. Angeordnet als 4 × 4 auf dem Tresen,
## vorderste Reihe dort, wo bisher die erste Reihe stand.
##
## Die Szene wird als Text bearbeitet und nicht neu gepackt: beim Packen einer
## instanzierten Szene ging das Skript der Wurzel verloren, und damit die ganze
## Ausgabe (kein set_inhalt mehr, nichts mehr sichtbar zu steuern).
##
## Aufruf: godot --headless --path . --script res://tools/bake_ausgabe.gd
## Nochmal aufrufen ist gefahrlos — vorhandene Stellplätze werden ersetzt.

const SZENE := "res://scenes/ausgabe.tscn"
## 4 × 4 Stück je Platz
const SPALTEN := 4
const REIHEN := 4
const ABSTAND_X := 0.13
const ABSTAND_Z := 0.13
## Vorderste Reihe — dort stand die alte Reihe auch
const ERSTE_Z := -0.1
const HOEHE := 0.03
## Teller sind viel breiter als Krüge; ungeschrumpft lägen 16 Brezn ineinander
const TELLER_GROESSE := 0.55

func _init() -> void:
	var datei := FileAccess.open(SZENE, FileAccess.READ)
	if datei == null:
		print("Szene nicht lesbar")
		quit()
		return
	var zeilen := datei.get_as_text().split("\n")
	datei.close()
	# Erst die alten Krüge und Teller herausnehmen und die Plätze sammeln
	var behalten: Array[String] = []
	var plaetze: Array[Dictionary] = []
	var im_stueck := false
	for zeile: String in zeilen:
		if zeile.begins_with("[node "):
			var eltern := _wert(zeile, "parent")
			var name := _wert(zeile, "name")
			im_stueck = eltern.begins_with("Plaetze/") and (name.begins_with("K") or name.begins_with("T")) \
				and name != "Aufsteller"
			if eltern == "Plaetze":
				plaetze.append({"name": name, "art": 1})
		if not im_stueck:
			behalten.append(zeile)
	# Art je Platz aus den Metadaten
	for p: Dictionary in plaetze:
		for i in behalten.size():
			if behalten[i].begins_with("[node ") and _wert(behalten[i], "name") == p["name"] \
					and _wert(behalten[i], "parent") == "Plaetze":
				for k in range(i + 1, mini(i + 5, behalten.size())):
					if behalten[k].begins_with("metadata/art"):
						p["art"] = int(behalten[k].get_slice("=", 1).strip_edges())
				break
	# Neue Stellplätze hinten anhängen — in einer .tscn darf ein Kind überall
	# nach seinem Elternteil stehen
	var text := "\n".join(behalten).strip_edges() + "\n"
	for p: Dictionary in plaetze:
		var art := int(p["art"])
		var kuerzel := "K" if art == 1 else "T"
		var quelle := "2_krug" if art == 1 else "3_teller"
		for i in SPALTEN * REIHEN:
			var spalte := i % SPALTEN
			var reihe := i / SPALTEN
			var x := (float(spalte) - float(SPALTEN - 1) * 0.5) * ABSTAND_X
			var z := ERSTE_Z - float(reihe) * ABSTAND_Z
			var s := 1.0 if art == 1 else TELLER_GROESSE
			text += "\n[node name=\"%s%d\" parent=\"Plaetze/%s\" instance=ExtResource(\"%s\")]\n" % [
				kuerzel, i, p["name"], quelle]
			text += "transform = Transform3D(%s, 0, 0, 0, %s, 0, 0, 0, %s, %s, %s, %s)\n" % [
				s, s, s, x, HOEHE, z]
		print("  %s (art %d): %d Stellplätze" % [p["name"], art, SPALTEN * REIHEN])
	var raus := FileAccess.open(SZENE, FileAccess.WRITE)
	raus.store_string(text)
	raus.close()
	print("gespeichert")
	quit()

## Wert eines Feldes aus einer [node …]-Zeile, etwa name="K0" → K0
func _wert(zeile: String, feld: String) -> String:
	var suche := feld + "=\""
	var von := zeile.find(suche)
	if von < 0:
		return ""
	von += suche.length()
	var bis := zeile.find("\"", von)
	return zeile.substr(von, bis - von) if bis > von else ""
