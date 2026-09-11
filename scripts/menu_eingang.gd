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
## Seit 4.4 auch für die Darstellung: Der Renderer lässt sich nur beim Start
## wählen. Steht in den Einstellungen ein anderer als der laufende, startet die
## Szene mit --rendering-method neu — im selben Neustart wie das Paket.
##
## Absichtlich nur Engine-Funktionen und keine Übersetzungen: in einer alten
## .exe gibt es weder unsere Autoloads noch die Übersetzungstabelle.

const HAUPTMENUE := "res://scenes/ui/hauptmenue.tscn"
const DOWNLOAD_SEITE := "https://survival.vapur-it.de/"
const PAKET := "user://game.pck"
const VERSION_DATEI := "user://version.txt"
const EINSTELLUNGEN := "user://einstellungen.cfg"
const RENDERER := ["forward_plus", "gl_compatibility"]
## Wird beim Neustart mitgegeben — verhindert eine Endlosschleife.
const NEUSTART_MARKE := "--neu-gestartet"

func _ready() -> void:
	var gesperrt := OS.has_feature("editor") or OS.get_cmdline_user_args().has(NEUSTART_MARKE)
	# Im Steam-Build nie mit einem heruntergeladenen Paket neu starten (Plan 5.1)
	var paket_neuer := _paket_neuer() and not OS.has_feature("steam")
	var args := neustart_argumente(gesperrt, paket_neuer, ProjectSettings.globalize_path(PAKET),
		RenderingServer.get_current_rendering_method(), _gewuenschter_renderer())
	if not args.is_empty() and _neu_starten(args):
		return
	if ProjectSettings.has_setting("autoload/Einstellungen"):
		# Über den Ladebildschirm — das Menü hat jetzt den Kirmesplatz im Hintergrund.
		# Net per Knotenpfad, nicht als Name: alte .exe kennen das Autoload nicht
		# und würden sonst schon beim Laden dieses Skripts scheitern.
		var net := get_tree().root.get_node_or_null("Net")
		if net and net.has_method("wechsle_zu"):
			net.call_deferred("wechsle_zu", HAUPTMENUE)
		else:
			get_tree().change_scene_to_file.call_deferred(HAUPTMENUE)
		return
	_zeige_hinweis()

## Womit neu gestartet werden muss — leer = kein Neustart nötig.
## gesperrt: im Editor oder schon neu gestartet · paket_neuer: heruntergeladenes
## Paket ist neuer als die .exe · aktuell/wunsch: laufender und gewählter Renderer.
static func neustart_argumente(gesperrt: bool, paket_neuer: bool, paket: String,
		aktuell: String, wunsch: String) -> PackedStringArray:
	var args := PackedStringArray()
	if gesperrt:
		return args
	if paket_neuer:
		args.append_array(["--main-pack", paket])
	if wunsch != "" and wunsch != aktuell:
		args.append_array(["--rendering-method", wunsch])
	return args

## Nur neu starten, wenn wirklich ein neueres Paket vorliegt als das, womit die
## .exe gerade läuft — sonst würden wir auf einen alten Stand zurückfallen.
func _paket_neuer() -> bool:
	if not FileAccess.file_exists(PAKET) or not FileAccess.file_exists(VERSION_DATEI):
		return false
	var geladen := FileAccess.get_file_as_string(VERSION_DATEI).strip_edges().to_int()
	var laufend := str(ProjectSettings.get_setting("application/config/version", "0")).to_int()
	return geladen > laufend

## Gewählte Darstellung direkt aus der Einstellungsdatei (ohne Autoload).
func _gewuenschter_renderer() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(EINSTELLUNGEN) != OK:
		return ""
	var r := str(cfg.get_value("grafik", "renderer", ""))
	return r if r in RENDERER else ""

func _neu_starten(args: PackedStringArray) -> bool:
	var alle := args.duplicate()
	alle.append_array(["--", NEUSTART_MARKE])
	var pid := OS.create_process(OS.get_executable_path(), alle)
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
