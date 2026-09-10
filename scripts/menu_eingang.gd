extends Control
## Einstiegsszene vor dem Hauptmenü.
##
## Das Problem: Eine .exe liest Autoloads und Projekteinstellungen (Theme,
## Übersetzungen, Audiobusse) nur beim Start — und zwar aus ihrem eingebauten
## Paket. Der Auto-Updater lädt neue Spieldaten zwar nach, an Autoloads und
## Einstellungen ändert das aber nichts. Mit Version 100 hatten alte .exe-Dateien
## deshalb ein Hauptmenü ohne Skript und tote Knöpfe.
##
## Die Lösung: Diese Szene kommt immer aus dem heruntergeladenen Paket, auch bei
## alten .exe-Dateien. Ist das geladene Paket neuer als die .exe, startet sie das
## Programm einmal neu und übergibt das Paket als Hauptpaket (--main-pack). Dann
## gilt alles aus dem Update. Klappt das nicht, zeigt sie einen Hinweis.
##
## Absichtlich nur Engine-Funktionen und keine Übersetzungen: in einer alten
## .exe gibt es weder unsere Autoloads noch die Übersetzungstabelle.

const HAUPTMENUE := "res://scenes/ui/hauptmenue.tscn"
const DOWNLOAD_SEITE := "https://survival.vapur-it.de/"
const PAKET := "user://game.pck"
const VERSION_DATEI := "user://version.txt"
## Wird beim Neustart mitgegeben — verhindert eine Endlosschleife.
const NEUSTART_MARKE := "--neu-gestartet"

func _ready() -> void:
	if _neustart_noetig() and _neu_starten():
		return
	if ProjectSettings.has_setting("autoload/Einstellungen"):
		get_tree().change_scene_to_file.call_deferred(HAUPTMENUE)
		return
	_zeige_hinweis()

## Nur neu starten, wenn wirklich ein neueres Paket vorliegt als das, womit die
## .exe gerade läuft — sonst würden wir auf einen alten Stand zurückfallen.
func _neustart_noetig() -> bool:
	if OS.has_feature("editor") or OS.get_cmdline_user_args().has(NEUSTART_MARKE):
		return false
	if not FileAccess.file_exists(PAKET) or not FileAccess.file_exists(VERSION_DATEI):
		return false
	var geladen := FileAccess.get_file_as_string(VERSION_DATEI).strip_edges().to_int()
	var laufend := str(ProjectSettings.get_setting("application/config/version", "0")).to_int()
	return geladen > laufend

func _neu_starten() -> bool:
	var paket := ProjectSettings.globalize_path(PAKET)
	var pid := OS.create_process(OS.get_executable_path(), ["--main-pack", paket, "--", NEUSTART_MARKE])
	if pid <= 0:
		return false
	get_tree().quit()
	return true

func _zeige_hinweis() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%UpdateHinweis.visible = true
	%Download.pressed.connect(func() -> void: OS.shell_open(DOWNLOAD_SEITE))
	%Beenden.pressed.connect(func() -> void: get_tree().quit())
	%Download.grab_focus()
