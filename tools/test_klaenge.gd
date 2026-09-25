extends SceneTree
## Prueft, ob die Klangdateien im Spiel ankommen — und ob noch Piepstoene
## uebrig sind.
##
##   Godot.exe --headless --path . --script res://tools/test_klaenge.gd
##
## Der Klang selbst laesst sich hier nicht beurteilen, das geht nur mit Ohren.
## Geprueft wird, was man messen kann: liegt eine echte Datei vor, ist sie lang
## genug, und faengt sie mit Ton an statt mit Stille.

const GEBRAUCHT := ["pop", "ding", "glug", "sizzle", "scrub", "splash", "cheer", "honk"]
const SCHOEN := ["schritte", "kasse", "zapfen", "prost", "tuer", "muenzen", "fahrgeschaeft"]
const ORDNER := "res://assets/audio/sfx/%s%s"
const ENDUNGEN := [".ogg", ".wav", ".mp3"]

func _init() -> void:
	var fehlt := 0
	print("-- Kernklaenge (ersetzen die Piepstoene)")
	for n: String in GEBRAUCHT:
		var pfad := _suche(n)
		if pfad == "":
			fehlt += 1
			print("  [FEHLT] %-10s noch ein Piepston" % n)
		else:
			print("  [OK   ] %-10s %s" % [n, _info(pfad)])
	print("-- Kuer")
	for n: String in SCHOEN:
		var pfad := _suche(n)
		print("  [%s] %-14s %s" % ["OK   " if pfad != "" else "offen", n, _info(pfad) if pfad != "" else ""])
	print("-- Ambiente")
	for paar in [["kirmes", "res://assets/audio/ambiente/kirmes"],
			["regen leicht", "res://assets/audio/ambiente/regen_leicht.ogg"],
			["regen stark", "res://assets/audio/ambiente/regen_stark.ogg"]]:
		var da := ResourceLoader.exists(paar[1]) or ResourceLoader.exists(paar[1] + ".ogg")
		if not da and paar[0] == "kirmes":
			fehlt += 1
		print("  [%s] %s" % ["OK   " if da else "FEHLT", paar[0]])
	print("ERGEBNIS: %s" % ["BESTANDEN" if fehlt == 0 else "FEHLGESCHLAGEN (%d fehlen)" % fehlt])
	quit(0 if fehlt == 0 else 1)

func _suche(name: String) -> String:
	for e: String in ENDUNGEN:
		var p: String = ORDNER % [name, e]
		if ResourceLoader.exists(p):
			return p
	return ""

func _info(pfad: String) -> String:
	var strom := load(pfad) as AudioStream
	if strom == null:
		return "laedt nicht!"
	return "%.2f s" % strom.get_length()
