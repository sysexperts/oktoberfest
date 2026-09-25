extends Node
## Einstellungen des Spielers: laden, speichern, anwenden.
## Wird als Autoload vor allen anderen gestartet, damit Sprache und
## Tastenbelegung schon stehen, bevor irgendein Menü aufgeht.

signal geaendert

const PFAD := "user://einstellungen.cfg"
const SPRACHEN := ["auto", "de", "en", "tr"]

## Aktion -> Standardtaste. Die Reihenfolge ist auch die Reihenfolge im Menü.
const STANDARD_TASTEN := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"interact": KEY_E,
	"sprint": KEY_SHIFT,
	"emote": KEY_Q,
	"costume": KEY_C,
	"help": KEY_F1,
	"screenshot": KEY_F12,
	"ping": KEY_R,
	"springen": KEY_SPACE,
	"trinken": KEY_G,
	"kalender": KEY_K,
}

## Gamepad (Xbox-Layout, so auch auf dem Steam Deck). Fest, nicht umbelegbar —
## siehe _pad_anwenden. A bleibt für „Benutzen" frei, weil das die Taste ist,
## die man in einer Schicht am häufigsten drückt.
const PAD_KNOEPFE := {
	"interact": JOY_BUTTON_A,
	"springen": JOY_BUTTON_B,
	"trinken": JOY_BUTTON_X,
	"ping": JOY_BUTTON_Y,
	"emote": JOY_BUTTON_LEFT_SHOULDER,
	"sprint": JOY_BUTTON_RIGHT_SHOULDER,
	"costume": JOY_BUTTON_DPAD_UP,
	"kalender": JOY_BUTTON_DPAD_DOWN,
	"help": JOY_BUTTON_DPAD_LEFT,
}
## Laufen mit dem linken Stick: Achse und Richtung (-1 = negativ, 1 = positiv).
const PAD_ACHSEN := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	"move_back": [JOY_AXIS_LEFT_Y, 1.0],
}
## Umschauen mit dem rechten Stick.
const BLICK_ACHSEN := {
	"blick_links": [JOY_AXIS_RIGHT_X, -1.0],
	"blick_rechts": [JOY_AXIS_RIGHT_X, 1.0],
	"blick_hoch": [JOY_AXIS_RIGHT_Y, -1.0],
	"blick_runter": [JOY_AXIS_RIGHT_Y, 1.0],
}
## Wie schnell sich der Blick mit dem Stick dreht (Bogenmaß je Sekunde bei vollem
## Ausschlag). Wird mit der Mausempfindlichkeit aus den Einstellungen skaliert.
const PAD_BLICK_TEMPO := 2.8
## Ab hier zaehlt ein Stickausschlag. Godots Vorgabe 0,5 ist fuer Laufen zu grob.
const STICK_TOTZONE := 0.2
## Wie die Knoepfe in Hinweisen heissen. Kurz halten — der Text steht mitten im
## Satz („Krug nehmen [A]").
const PAD_NAMEN := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "↑",
	JOY_BUTTON_DPAD_DOWN: "↓",
	JOY_BUTTON_DPAD_LEFT: "←",
	JOY_BUTTON_DPAD_RIGHT: "→",
}

## Knopf -> Bilddatei in assets/ui/glyphen (ohne Endung).
const GLYPH_DATEI := {
	JOY_BUTTON_A: "pad_a",
	JOY_BUTTON_B: "pad_b",
	JOY_BUTTON_X: "pad_x",
	JOY_BUTTON_Y: "pad_y",
	JOY_BUTTON_LEFT_SHOULDER: "pad_lb",
	JOY_BUTTON_RIGHT_SHOULDER: "pad_rb",
	JOY_BUTTON_DPAD_UP: "pad_hoch",
	JOY_BUTTON_DPAD_DOWN: "pad_runter",
	JOY_BUTTON_DPAD_LEFT: "pad_links",
	JOY_BUTTON_DPAD_RIGHT: "pad_rechts",
}

## Wurde zuletzt am Gamepad gespielt? Steuert die Hinweistexte, sonst nichts.
var am_pad := false

## F12: Bildschirmfoto nach user://screenshots — für Store-Bilder und Fehlerberichte.
signal screenshot_gespeichert(pfad: String)
const FOTO_ORDNER := "user://screenshots"

var sprache := "auto"
var vollbild := false
var vsync := true
## 0 Niedrig, 1 Mittel, 2 Hoch — was das bewirkt, steht in scripts/grafikstufe.gd
var grafik := 2
## Renderauflösung der 3D-Welt (0,5 … 1,0); Menüs bleiben immer scharf
var aufloesung := 1.0
## Darstellung: "forward_plus" (Qualität) oder "gl_compatibility" (Leistung).
## Gilt erst beim nächsten Start — menu_eingang.gd startet dafür neu.
var renderer := "forward_plus"
const RENDERER := ["forward_plus", "gl_compatibility"]
## Lineare Lautstärke 0..1 je Audiobus.
var lautstaerke := {"Master": 1.0, "Musik": 0.8, "SFX": 1.0, "Ambiente": 0.8}
var maus := 1.0
var maus_y_umkehren := false
## Aktion -> physischer Tastencode (nur Abweichungen vom Standard nötig).
var tasten := {}

func _ready() -> void:
	_lade()
	anwenden()

func _unhandled_input(event: InputEvent) -> void:
	_eingabeart_merken(event)
	_pad_klick(event)
	if event.is_action_pressed("screenshot") and not event.is_echo():
		bildschirmfoto()

# ------------------------------------------------------- Zeigen mit dem Stick
## Steam verlangt fuer „Xbox-Controller-Unterstuetzung", dass sich alles ohne
## Tastatur und Maus bedienen laesst — auch die Kirmesspiele und der Baumodus.
## Die zeigen und klicken aber mit der Maus.
##
## Statt siebzehn Stellen einzeln umzubauen, uebersetzt dieses Autoload den
## Controller in Mauseingaben:
##
##   sichtbarer Zeiger (Menues, Baumodus)  rechter Stick schiebt den echten
##                                         Zeiger (Input.warp_mouse)
##   gefangene Maus (Kirmesspiele im       rechter Stick erzeugt Mausbewegung,
##   Ego-Blick)                            damit Zielen und Schwenken gehen
##   A-Knopf                               wird zum Linksklick
##
## Der Klick entsteht nur, wenn kein Bedienelement den Fokus hat. In Menues
## fuehrt A sonst zweimal etwas aus: einmal ueber den Fokus, einmal ueber den
## Zeiger, der gerade woanders steht.
const ZEIGER_TEMPO := 1100.0
## Erzeugte Ereignisse laufen durch dieselbe Schleife wie echte. Ohne diese
## Sperre wuerde die kuenstliche Mausbewegung am_pad sofort wieder auf false
## setzen — der Stick haette sich selbst abgeschaltet.
var _eigene_eingabe := false
var _pad_maus_unten := false

func _process(delta: float) -> void:
	if not am_pad or DisplayServer.get_name() == "headless":
		return
	var richtung := Input.get_vector("blick_links", "blick_rechts", "blick_hoch", "blick_runter")
	if richtung.length() < 0.01:
		return
	var modus := Input.mouse_mode
	if modus == Input.MOUSE_MODE_VISIBLE or modus == Input.MOUSE_MODE_CONFINED:
		var fenster := Vector2(get_viewport().get_visible_rect().size)
		var ziel := get_viewport().get_mouse_position() + richtung * ZEIGER_TEMPO * delta
		_eigene_eingabe = true
		Input.warp_mouse(ziel.clamp(Vector2.ZERO, fenster))
		_eigene_eingabe = false
	elif modus == Input.MOUSE_MODE_CAPTURED:
		# Im Ego-Blick zielt man ueber die Mausbewegung. Der Wert muss klein
		# bleiben: die Spiele rechnen ihn mit ihrer eigenen Empfindlichkeit hoch.
		var ev := InputEventMouseMotion.new()
		ev.relative = richtung * ZEIGER_TEMPO * delta * 0.35
		ev.screen_relative = ev.relative
		_senden(ev)

## A wird zum Linksklick — aber nur, wenn nichts den Fokus hat (siehe oben).
func _pad_klick(event: InputEvent) -> void:
	if _eigene_eingabe or not (event is InputEventJoypadButton):
		return
	var knopf := event as InputEventJoypadButton
	if knopf.button_index != JOY_BUTTON_A:
		return
	if get_viewport().gui_get_focus_owner() != null:
		return
	if knopf.pressed == _pad_maus_unten:
		return
	_pad_maus_unten = knopf.pressed
	var klick := InputEventMouseButton.new()
	klick.button_index = MOUSE_BUTTON_LEFT
	klick.pressed = knopf.pressed
	klick.position = get_viewport().get_mouse_position()
	klick.global_position = klick.position
	_senden(klick)

func _senden(ev: InputEvent) -> void:
	_eigene_eingabe = true
	Input.parse_input_event(ev)
	_eigene_eingabe = false

## Woran wird gerade gespielt? Steuert, ob in Hinweisen „[E]" oder „[A]" steht.
## Ein Stick driftet im Ruhezustand leicht — darum erst ab halbem Ausschlag.
func _eingabeart_merken(event: InputEvent) -> void:
	if _eigene_eingabe:
		return   # selbst erzeugte Maus zaehlt nicht als „spielt mit der Maus"
	var vorher := am_pad
	if event is InputEventJoypadButton:
		am_pad = true
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		am_pad = true
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		am_pad = false
	if am_pad != vorher:
		# Schilder in der Welt (Fass, Lager, Ausgabe) beschriften sich beim
		# gleichen Signal neu wie nach einer Tastenumbelegung — sonst stünde
		# dort weiter "[E]", nachdem man zum Gamepad gegriffen hat.
		geaendert.emit()

## Speichert das aktuelle Bild. Gibt den Dateipfad zurück, "" wenn es nicht ging.
func bildschirmfoto() -> String:
	if DisplayServer.get_name() == "headless":
		return ""
	var bild := get_viewport().get_texture().get_image()
	if bild == null:
		return ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOTO_ORDNER))
	var datei := "oktoberfest_%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
	var pfad := "%s/%s" % [FOTO_ORDNER, datei]
	if bild.save_png(pfad) != OK:
		return ""
	var echt := ProjectSettings.globalize_path(pfad)
	print("[Bildschirmfoto] ", echt)
	screenshot_gespeichert.emit(echt)
	return echt

func anwenden() -> void:
	TranslationServer.set_locale(aktive_sprache())
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if vollbild else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	get_tree().root.scaling_3d_scale = aufloesung
	for bus: String in lautstaerke:
		_bus_anwenden(bus)
	_tasten_anwenden()
	geaendert.emit()

## Einzelnen Regler setzen, ohne das ganze Menü neu aufzubauen.
func setze_lautstaerke(bus: String, wert: float) -> void:
	lautstaerke[bus] = clampf(wert, 0.0, 1.0)
	_bus_anwenden(bus)

func _bus_anwenden(bus: String) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	var v := clampf(float(lautstaerke.get(bus, 1.0)), 0.0, 1.0)
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))

## "auto" wird zur Systemsprache aufgelöst — Deutsch, Türkisch, sonst Englisch.
func aktive_sprache() -> String:
	if sprache != "auto":
		return sprache
	var sys := OS.get_locale_language()
	return sys if sys in ["de", "tr", "en"] else "en"

func taste(aktion: String) -> int:
	return int(tasten.get(aktion, STANDARD_TASTEN.get(aktion, KEY_NONE)))

## Anzeigename einer Taste, z. B. "E" oder "Shift". Immer die Tastatur — das
## Belegungsmenü zeigt damit, was umbelegt wird.
func tasten_name(aktion: String) -> String:
	return OS.get_keycode_string(taste(aktion))

## Bild des Knopfes für eine Aktion, "" wenn gerade mit Tastatur gespielt wird
## oder es für die Aktion kein Bild gibt.
##
## Zwei Sätze, beide von Kenney (CC0, siehe docs/lizenzen): auf dem Steam Deck
## die Deck-Knöpfe, sonst die vom Xbox-Controller. Wer am Deck spielt, sieht dort
## seine eigenen Tasten — genau das verlangt Steams Prüfliste.
func glyph_pfad(aktion: String) -> String:
	if not am_pad or not PAD_KNOEPFE.has(aktion):
		return ""
	var datei: String = GLYPH_DATEI.get(int(PAD_KNOEPFE[aktion]), "")
	if datei == "":
		return ""
	var pfad := "res://assets/ui/glyphen/%s/%s.svg" % ["deck" if auf_deck() else "xbox", datei]
	return pfad if ResourceLoader.exists(pfad) else ""

## Läuft das Spiel auf einem Steam Deck? Steam setzt dort diese Umgebungsvariable;
## GodotSteam hat dafür keine eigene Abfrage.
var _deck := -1
func auf_deck() -> bool:
	if _deck < 0:
		_deck = 1 if OS.get_environment("SteamDeck") == "1" else 0
	return _deck == 1

## Was in Hinweisen steht („Krug nehmen [E]"). Wer zuletzt am Gamepad gedrückt
## hat, bekommt den Knopf gezeigt — sonst stünde am Steam Deck überall eine
## Taste, die es dort nicht gibt.
func anzeige_name(aktion: String) -> String:
	if am_pad and PAD_KNOEPFE.has(aktion):
		return PAD_NAMEN.get(int(PAD_KNOEPFE[aktion]), tasten_name(aktion))
	return tasten_name(aktion)

func setze_taste(aktion: String, keycode: int) -> void:
	tasten[aktion] = keycode
	speichern()
	anwenden()

func tasten_zuruecksetzen() -> void:
	tasten.clear()
	speichern()
	anwenden()

func _tasten_anwenden() -> void:
	for aktion: String in STANDARD_TASTEN:
		if not InputMap.has_action(aktion):
			InputMap.add_action(aktion)
		InputMap.action_erase_events(aktion)
		var ev := InputEventKey.new()
		ev.physical_keycode = taste(aktion)
		InputMap.action_add_event(aktion, ev)
	_pad_anwenden()

## Gamepad fest dazu (Steam Deck, Xbox-Layout). Kommt nach den Tasten, weil
## _tasten_anwenden alle Ereignisse einer Aktion löscht.
##
## Die Belegung ist nicht umbelegbar — wer am Deck spielt, kann sie über Steams
## eigene Controller-Einstellungen ändern, und ein zweiter Belegungsdialog im
## Spiel wäre doppelte Arbeit für denselben Zweck.
func _pad_anwenden() -> void:
	for aktion: String in PAD_KNOEPFE:
		_pad_knopf(aktion, int(PAD_KNOEPFE[aktion]))
	for aktion: String in PAD_ACHSEN:
		var a: Array = PAD_ACHSEN[aktion]
		_pad_achse(aktion, int(a[0]), float(a[1]))
		# Godots Vorgabe ist 0,5 — damit müsste man den Stick halb durchdrücken,
		# bevor sich die Figur bewegt.
		InputMap.action_set_deadzone(aktion, STICK_TOTZONE)
	# Menüführung: Godots eingebaute ui_accept/ui_cancel haben hier nur Tasten,
	# keinen Knopf (geprüft mit tools/test_pad). Ohne diese zwei Zeilen käme man
	# am Steam Deck in kein Menü hinein und aus keinem wieder heraus.
	if not _hat_pad_knopf("ui_accept"):
		_pad_knopf("ui_accept", JOY_BUTTON_A)
	if not _hat_pad_knopf("ui_cancel"):
		_pad_knopf("ui_cancel", JOY_BUTTON_B)
	# Blick mit dem rechten Stick — als eigene Aktionen, damit player.gd sie wie
	# die Maus auswerten kann.
	for aktion: String in BLICK_ACHSEN:
		if not InputMap.has_action(aktion):
			InputMap.add_action(aktion)
		InputMap.action_erase_events(aktion)
		var a: Array = BLICK_ACHSEN[aktion]
		_pad_achse(aktion, int(a[0]), float(a[1]))
		InputMap.action_set_deadzone(aktion, STICK_TOTZONE)

func _hat_pad_knopf(aktion: String) -> bool:
	if not InputMap.has_action(aktion):
		return false
	for ev in InputMap.action_get_events(aktion):
		if ev is InputEventJoypadButton:
			return true
	return false

func _pad_knopf(aktion: String, knopf: int) -> void:
	if not InputMap.has_action(aktion):
		InputMap.add_action(aktion)
	var ev := InputEventJoypadButton.new()
	ev.button_index = knopf
	InputMap.action_add_event(aktion, ev)

func _pad_achse(aktion: String, achse: int, richtung: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = achse
	ev.axis_value = richtung
	InputMap.action_add_event(aktion, ev)

func speichern() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("allgemein", "sprache", sprache)
	cfg.set_value("grafik", "vollbild", vollbild)
	cfg.set_value("grafik", "vsync", vsync)
	cfg.set_value("grafik", "qualitaet", grafik)
	cfg.set_value("grafik", "aufloesung", aufloesung)
	cfg.set_value("grafik", "renderer", renderer)
	for bus: String in lautstaerke:
		cfg.set_value("ton", bus, lautstaerke[bus])
	cfg.set_value("steuerung", "maus", maus)
	cfg.set_value("steuerung", "maus_y_umkehren", maus_y_umkehren)
	for aktion: String in tasten:
		cfg.set_value("tasten", aktion, tasten[aktion])
	cfg.save(PFAD)

func _lade() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PFAD) != OK:
		return
	sprache = str(cfg.get_value("allgemein", "sprache", sprache))
	if not sprache in SPRACHEN:
		sprache = "auto"
	vollbild = bool(cfg.get_value("grafik", "vollbild", vollbild))
	vsync = bool(cfg.get_value("grafik", "vsync", vsync))
	grafik = clampi(int(cfg.get_value("grafik", "qualitaet", grafik)), 0, 2)
	aufloesung = clampf(float(cfg.get_value("grafik", "aufloesung", aufloesung)), 0.5, 1.0)
	renderer = str(cfg.get_value("grafik", "renderer", renderer))
	if not renderer in RENDERER:
		renderer = "forward_plus"
	for bus: String in lautstaerke.keys():
		lautstaerke[bus] = float(cfg.get_value("ton", bus, lautstaerke[bus]))
	maus = clampf(float(cfg.get_value("steuerung", "maus", maus)), 0.1, 3.0)
	maus_y_umkehren = bool(cfg.get_value("steuerung", "maus_y_umkehren", maus_y_umkehren))
	if cfg.has_section("tasten"):
		for aktion in cfg.get_section_keys("tasten"):
			if STANDARD_TASTEN.has(aktion):
				tasten[aktion] = int(cfg.get_value("tasten", aktion))
