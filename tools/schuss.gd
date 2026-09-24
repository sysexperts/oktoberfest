extends RefCounted
## Bildschirmfoto aus einem Testwerkzeug speichern.
##
## Warum das eine eigene Datei ist: `get_viewport().get_texture().get_image()`
## gibt im Headless-Betrieb null zurück. Der Aufruf `.save_png()` darauf ist ein
## Laufzeitfehler, der die laufende Funktion abbricht — und damit oft auch das
## `get_tree().quit()` zwei Zeilen weiter. Der Test hing dann bis zum Zeitlimit
## (gemessen: test_kalender, 420 s) statt in einer Sekunde durchzulaufen.
##
##   const Schuss := preload("res://tools/schuss.gd")
##   Schuss.speichern(get_viewport(), pfad)
##
## Ohne Fenster wird nichts geschrieben und der Test läuft normal weiter.

## true = Bild geschrieben.
static func speichern(vp: Viewport, pfad: String) -> bool:
	if vp == null or pfad == "":
		return false
	# Ohne Fenster gibt es keine Bildquelle. Erst gar nicht danach greifen — die
	# Dummy-Grafik der Engine meldet sonst 'Parameter "t" is null' ins Log.
	if DisplayServer.get_name() == "headless":
		return false
	var tex := vp.get_texture()
	if tex == null:
		return false
	var bild := tex.get_image()
	if bild == null:
		return false
	var ordner := pfad.get_base_dir()
	if ordner != "":
		DirAccess.make_dir_recursive_absolute(ordner)
	return bild.save_png(pfad) == OK
