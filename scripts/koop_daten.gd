extends RefCounted
## Koop-Daten, die mit dem Update-Paket mitkommen müssen.
##
## Eine .exe nimmt Autoloads (Net) und Projekteinstellungen aus ihrem eingebauten
## Paket — neue Felder in Net und eine neue config/version kommen bei Spielern
## mit älterer .exe nicht an (v136: Warteraum meldete „neue Version", obwohl das
## Update geladen war). Deshalb liegt hier, was der Client braucht, als statische
## Werte in einem normalen Skript. Einbinden per preload, ohne class_name.

const LOBBY_URL := "https://survival.vapur-it.de/lobby/"
## boot.gd merkt sich je Paket die geladene Version; maßgeblich ist spiel.pck,
## weil dort Skripte und Szenen liegen. Vor v205 hieß das user://version.txt und
## das Paket user://game.pck — wer die alten Namen liest, bekommt seit der
## Aufteilung die Version der .exe statt der geladenen Spieldaten (v206: der
## Server meldete 206, der Client 205, und jeder Beitritt flog raus).
const VERSION_DATEI := "user://spiel.txt"
const PAKET_DATEI := "user://spiel.pck"

## Wahl aus dem Warteraum {name, figur, abt} — nach dem Beitritt an den Server
static var lobby_wahl := {}
## Warteraum → „Offizieller Server / IP": Hauptmenü öffnet gleich das Koop-Feld
static var menue_koop := false

## Version der Spieldaten, die wirklich laufen: in exportierten Spielen die höhere
## aus eingebauter Version und nachgeladenem Update (boot.gd schreibt spiel.txt
## und lädt das Paket nur, wenn es mindestens so neu ist). Server und Editor:
## die Projekteinstellung.
static func version() -> String:
	var eingebaut := str(ProjectSettings.get_setting("application/config/version", "dev"))
	if not OS.has_feature("template") or not FileAccess.file_exists(PAKET_DATEI):
		return eingebaut
	var f := FileAccess.open(VERSION_DATEI, FileAccess.READ)
	if f == null:
		return eingebaut
	var geladen := int(f.get_as_text().strip_edges())
	return str(maxi(geladen, int(eingebaut)))
