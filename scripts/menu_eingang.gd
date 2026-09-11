extends Control
## Einstiegsszene vor dem Hauptmenü.
##
## Eine .exe liest Autoloads, Projekteinstellungen und Erweiterungen nur beim
## Start, aus ihrem eingebauten Paket. Der Auto-Updater lädt neue Spieldaten
## nach, daran ändert das aber nichts. Passt ein Update nicht mehr zur .exe,
## zeigt diese Szene einen Hinweis zum Neu-Herunterladen.
##
## Früher (v101–v104) startete sie die .exe stattdessen mit --main-pack neu. Das
## kann nicht funktionieren: Die offiziellen Export-Vorlagen erlauben --main-pack
## nicht ("compiled without support for path overrides") und brechen sofort ab —
## für Spieler schloss sich das Spiel direkt nach dem Start. Im Editor fiel das
## nicht auf, weil der die Option erlaubt. Deshalb gibt es tools/test_exe.sh.
##
## Programm-Generation: application/config/programm_generation in project.godot.
## Nur hochzählen (und BENOETIGTE_GENERATION mit), wenn sich Autoloads,
## Projekteinstellungen oder Erweiterungen ändern — reine Inhalts-Updates kommen
## weiter automatisch. Wer eine neue Generation braucht, lädt die ZIP neu.
##
## Außerdem: Der Renderer lässt sich nur beim Start wählen. Steht in den
## Einstellungen ein anderer, startet die Szene mit --rendering-method neu — das
## erlauben die Vorlagen (geprüft).
##
## Absichtlich nur Engine-Funktionen und keine Übersetzungen: In einer alten
## .exe gibt es weder unsere Autoloads noch die Übersetzungstabelle.

const HAUPTMENUE := "res://scenes/ui/hauptmenue.tscn"
const DOWNLOAD_SEITE := "https://survival.vapur-it.de/"
const EINSTELLUNGEN := "user://einstellungen.cfg"
const RENDERER := ["forward_plus", "gl_compatibility"]
## Wird beim Neustart mitgegeben — verhindert eine Endlosschleife.
const NEUSTART_MARKE := "--neu-gestartet"
## Welche Programm-Generation dieses Paket mindestens braucht.
const BENOETIGTE_GENERATION := 2

func _ready() -> void:
	# Alte .exe kennen die Einstellung nicht — sie sind Generation 1
	var exe_generation := int(ProjectSettings.get_setting("application/config/programm_generation", 1))
	if braucht_neue_exe(exe_generation, BENOETIGTE_GENERATION):
		print("[Eingang] Programm-Generation %d, dieses Paket braucht %d — Hinweis zum Neu-Herunterladen" % [
			exe_generation, BENOETIGTE_GENERATION])
		_zeige_hinweis()
		return
	var gesperrt := OS.has_feature("editor") or OS.get_cmdline_user_args().has(NEUSTART_MARKE)
	var args := neustart_argumente(gesperrt, RenderingServer.get_current_rendering_method(), _gewuenschter_renderer())
	if not args.is_empty() and _neu_starten(args):
		return
	if ProjectSettings.has_setting("autoload/Einstellungen"):
		print("[Eingang] weiter ins Hauptmenü")
		# Über den Ladebildschirm — das Menü hat den Kirmesplatz im Hintergrund.
		# Net per Knotenpfad, nicht als Name: Eine alte .exe kennt das Autoload
		# womöglich nicht und würde sonst schon beim Laden dieses Skripts scheitern.
		var net := get_tree().root.get_node_or_null("Net")
		if net and net.has_method("wechsle_zu"):
			net.call_deferred("wechsle_zu", HAUPTMENUE)
		else:
			get_tree().change_scene_to_file.call_deferred(HAUPTMENUE)
		return
	_zeige_hinweis()

## Reicht diese .exe für das geladene Paket?
static func braucht_neue_exe(exe_generation: int, benoetigt: int) -> bool:
	return exe_generation < benoetigt

## Womit neu gestartet werden muss — leer = kein Neustart nötig.
## gesperrt: im Editor oder schon neu gestartet · aktuell/wunsch: laufender und
## gewählter Renderer. Nur --rendering-method — --main-pack verweigern die Vorlagen.
static func neustart_argumente(gesperrt: bool, aktuell: String, wunsch: String) -> PackedStringArray:
	var args := PackedStringArray()
	if gesperrt:
		return args
	if wunsch != "" and wunsch != aktuell:
		args.append_array(["--rendering-method", wunsch])
	return args

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
	print("[Eingang] Neustart mit ", " ".join(args))
	get_tree().quit()
	return true

func _zeige_hinweis() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%UpdateHinweis.visible = true
	%Download.pressed.connect(func() -> void: OS.shell_open(DOWNLOAD_SEITE))
	%Beenden.pressed.connect(func() -> void: get_tree().quit())
	%Download.grab_focus()
