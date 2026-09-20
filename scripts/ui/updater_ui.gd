extends Control
## Oberfläche des Updaters (scenes/ui/updater.tscn). boot.gd sagt nur, was gerade
## passiert — wie es aussieht, steckt hier und in der Szene.
##
## Beim Paketdownload sind es mehrere hundert Megabyte. Ohne Anzeige sieht das
## aus wie ein hängendes Fenster, deshalb Balken und Prozent aus den wirklich
## geladenen Bytes statt eines Wartetextes.

## Megabyte hübsch schreiben, damit man die Größe einordnen kann
const MB := 1024.0 * 1024.0

var _mit_fortschritt := false

func _ready() -> void:
	%Balken.visible = false
	%Prozent.visible = false

func status(text: String) -> void:
	%Status.text = text

## Ab hier läuft ein Download — Balken und Prozent einblenden
func fortschritt_an() -> void:
	_mit_fortschritt = true
	%Balken.visible = true
	%Prozent.visible = true
	%Balken.value = 0.0
	%Prozent.text = "0 %"

func fortschritt_aus() -> void:
	_mit_fortschritt = false
	%Balken.visible = false
	%Prozent.visible = false

## geladen und gesamt in Bytes; gesamt <= 0 heißt, der Server nennt keine Größe
func fortschritt(geladen: int, gesamt: int) -> void:
	if not _mit_fortschritt:
		return
	if gesamt > 0:
		var anteil := float(geladen) / float(gesamt) * 100.0
		%Balken.value = anteil
		%Prozent.text = "%d %%" % roundi(anteil)
		%Status.text = "%s  (%.0f / %.0f MB)" % [
			%Status.text.get_slice("  (", 0), geladen / MB, gesamt / MB]
	else:
		# Ohne bekannte Gesamtgröße wenigstens zeigen, dass etwas ankommt
		%Balken.value = 0.0
		%Prozent.text = "%.0f MB" % (geladen / MB)
