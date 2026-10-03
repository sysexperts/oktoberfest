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
	"spielerliste": KEY_TAB,
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
	## Back/View halten: Spielerliste und Tagesereignisse (wie die Tabelle in anderen Spielen)
	"spielerliste": JOY_BUTTON_BACK,
}
## Laufen mit dem linken Stick: Achse und Richtung (-1 = negativ, 1 = positiv).
const PAD_ACHSEN := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	"move_back": [JOY_AXIS_LEFT_Y, 1.0],
}
## Linker Abzug gehalten (nur Controller) — siehe _pad_anwenden.
const PAD_HALTEN := "pad_halten"
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
	JOY_BUTTON_BACK: "Back",
}

## Knopf -> Zeichen in der Glyphenschrift, je Geraetesatz. Kenney legt die
## Glyphen in den Privatbereich von Unicode (U+E000 aufwaerts); welcher Knopf
## auf welchem Zeichen sitzt, steht in den *_map.txt des Packs und ist je Satz
## verschieden. Damit zeigt jedes Label das Symbol — auch die Schilder in der
## Welt, wo ein Bild nicht ginge.
const GLYPH_ZEICHEN := {
	"xbox": {
		JOY_BUTTON_A: "", JOY_BUTTON_B: "", JOY_BUTTON_X: "", JOY_BUTTON_Y: "",
		JOY_BUTTON_LEFT_SHOULDER: "", JOY_BUTTON_RIGHT_SHOULDER: "",
		JOY_BUTTON_DPAD_UP: "", JOY_BUTTON_DPAD_DOWN: "",
		JOY_BUTTON_DPAD_LEFT: "", JOY_BUTTON_DPAD_RIGHT: "",
	},
	"playstation": {
		JOY_BUTTON_A: "", JOY_BUTTON_B: "", JOY_BUTTON_X: "", JOY_BUTTON_Y: "",
		JOY_BUTTON_LEFT_SHOULDER: "", JOY_BUTTON_RIGHT_SHOULDER: "",
		JOY_BUTTON_DPAD_UP: "", JOY_BUTTON_DPAD_DOWN: "",
		JOY_BUTTON_DPAD_LEFT: "", JOY_BUTTON_DPAD_RIGHT: "",
	},
	"deck": {
		JOY_BUTTON_A: "", JOY_BUTTON_B: "", JOY_BUTTON_X: "", JOY_BUTTON_Y: "",
		JOY_BUTTON_LEFT_SHOULDER: "", JOY_BUTTON_RIGHT_SHOULDER: "",
		JOY_BUTTON_DPAD_UP: "", JOY_BUTTON_DPAD_DOWN: "",
		JOY_BUTTON_DPAD_LEFT: "", JOY_BUTTON_DPAD_RIGHT: "",
	},
}
## Die Schriften dazu (CC0, Kenney). Eine davon haengt als Ersatzschrift hinter
## der normalen — sonst erschiene nur ein leeres Kaestchen.
const GLYPH_SCHRIFT := {
	"xbox": "res://assets/fonts/glyphen/xbox.ttf",
	"playstation": "res://assets/fonts/glyphen/playstation.ttf",
	"deck": "res://assets/fonts/glyphen/deck.ttf",
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

## Controller: eigene Werte, nicht die der Maus. Wer die Maus schnell eingestellt
## hat, bekam sonst einen ueberdrehten Stick.
var pad_empfindlichkeit := 1.0
var pad_y_umkehren := false
## Ab hier zaehlt ein Stickausschlag (Godots Vorgabe 0,5 ist fuers Laufen zu grob)
var pad_totzone := 0.2
## Welche Knopfbilder gezeigt werden: "auto" richtet sich nach dem Geraet.
var glyph_stil := "auto"
const GLYPH_STILE := ["auto", "xbox", "playstation", "deck"]
## Woran ein PlayStation-Pad zu erkennen ist. Godot meldet je nach Treiber
## unterschiedliche Namen — deshalb mehrere Stichwoerter statt eines Vergleichs.
## Godot/SDL melden je nach Treiber und Verbindungsart (USB oder Bluetooth)
## verschiedene Namen fuer dasselbe Geraet — deshalb Stichwoerter statt eines
## Vergleichs. Diese Liste ist der Rueckfall, wenn Steam nicht laeuft.
const PS_NAMEN := ["playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5",
	"wireless controller", "sony", "dual shock", "dual sense", "scuf", "nacon"]

## F12: Bildschirmfoto nach user://screenshots — für Store-Bilder und Fehlerberichte.
signal screenshot_gespeichert(pfad: String)
const FOTO_ORDNER := "user://screenshots"

var sprache := "auto"
var vollbild := true
## Anzeigemodus: randloses Vollbild, exklusives Vollbild oder Fenster.
## vollbild bleibt als Kurzform (alles außer Fenster) für ältere Stellen.
const MODI := ["vollbild", "exklusiv", "fenster"]
var modus := "vollbild"
## Fenstergröße im Fenstermodus
var fenster_groesse := Vector2i(1600, 900)
## Bildschirm (Index), -1 = der, auf dem das Spiel gerade ist
var monitor := -1
## Bildrate begrenzen, 0 = unbegrenzt
const FPS_GRENZEN := [0, 30, 60, 120, 144, 165, 240]
var fps_grenze := 0
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
## Die Sperre allein reicht nicht: Godot stellt erzeugte Ereignisse erst im
## nächsten Bild zu, und der verschobene Zeiger meldet sich als echte
## Mausbewegung vom Betriebssystem. Beides kam als „Maus" an, schaltete am_pad
## ab, und der Stick blieb stehen, bis er sich wieder rührte — bei vollem
## Ausschlag also gar nicht (gemessen: 3°/s statt 48°/s beim Zielen).
## Darum tragen erzeugte Ereignisse die Gerätenummer für Nachgebildetes, und
## Mausbewegung zählt kurz nach dem Schieben nicht als Wechsel zur Maus.
var _pad_maus_bis := 0
## Wo der Stick den Zeiger zuletzt hingeschoben hat (Bildkoordinaten). Von hier
## geht es weiter und hier landet der Klick — das Betriebssystem meldet die neue
## Stelle erst ein Bild später, bei schnellem Schieben also die falsche.
## INF = der Stick führt den Zeiger gerade nicht (echte Maus bewegt).
var _zeiger := Vector2.INF

func _zeiger_ort() -> Vector2:
	return _zeiger if _zeiger.is_finite() else get_viewport().get_mouse_position()
var _pad_maus_unten := false

## Am Controller soll kein Mauszeiger im Bild hängen: Menüs und Fenster (Zeitung,
## Gespräche, Glücksrad) laufen über den Fokus, der Zeiger stünde nur sinnlos herum.
## Er verschwindet, sobald der Stick eine Weile nicht benutzt wurde, und kommt sofort
## wieder, wenn man mit dem Stick zeigt oder zur Maus greift (Baumodus, Kirmesspiele).
const ZEIGER_VERSTECKEN_NACH_MS := 2500
var _zeiger_weg := false
var _leeres_bild: ImageTexture

func zeiger_versteckt() -> bool:
	return _zeiger_weg

func _zeiger_pruefen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var soll := am_pad and Time.get_ticks_msec() > _pad_maus_bis + ZEIGER_VERSTECKEN_NACH_MS
	if soll == _zeiger_weg:
		return
	_zeiger_weg = soll
	if _leeres_bild == null:
		_leeres_bild = ImageTexture.create_from_image(Image.create_empty(2, 2, false, Image.FORMAT_RGBA8))
	for form in range(0, 17):
		Input.set_custom_mouse_cursor(_leeres_bild if soll else null, form as Input.CursorShape)

func _process(delta: float) -> void:
	_zeiger_pruefen()
	if not am_pad or DisplayServer.get_name() == "headless":
		return
	var richtung := Input.get_vector("blick_links", "blick_rechts", "blick_hoch", "blick_runter")
	if richtung.length() < 0.01:
		return
	_pad_maus_bis = Time.get_ticks_msec() + 250
	var modus := Input.mouse_mode
	if modus == Input.MOUSE_MODE_VISIBLE or modus == Input.MOUSE_MODE_CONFINED:
		var fenster := Vector2(get_viewport().get_visible_rect().size)
		var ziel := (_zeiger_ort() + richtung * ZEIGER_TEMPO * pad_empfindlichkeit * delta).clamp(Vector2.ZERO, fenster)
		_zeiger = ziel
		_eigene_eingabe = true
		# Über das Bild, nicht über Input: die Stelle ist in Bildkoordinaten
		# gerechnet. Input.warp_mouse nimmt Fensterpixel — bei jeder Auflösung
		# ausser der Grundgrösse sprang der Zeiger damit an die falsche Stelle.
		get_viewport().warp_mouse(ziel.clamp(Vector2.ZERO, fenster))
		_eigene_eingabe = false
	elif modus == Input.MOUSE_MODE_CAPTURED:
		# Im Ego-Blick zielt man ueber die Mausbewegung. Der Wert muss klein
		# bleiben: die Spiele rechnen ihn mit ihrer eigenen Empfindlichkeit hoch.
		var ev := InputEventMouseMotion.new()
		ev.relative = richtung * ZEIGER_TEMPO * pad_empfindlichkeit * delta * 0.35
		# Godot rechnet eingespeiste Mausbewegung von Fensterpixeln auf das Bild
		# um. Ohne Ausgleich zielte der Stick auf einem 4K-Bildschirm halb so
		# schnell wie auf Full HD und am Steam Deck schneller als beides.
		ev.relative *= get_viewport().get_final_transform().get_scale().x
		if pad_y_umkehren:
			ev.relative.y = -ev.relative.y
		ev.screen_relative = ev.relative
		_senden(ev)

## A und der rechte Abzug werden zum Linksklick — aber nur, wenn nichts den
## Fokus hat (siehe oben).
func _pad_klick(event: InputEvent) -> void:
	if _eigene_eingabe or event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var unten := false
	if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == JOY_BUTTON_A:
		unten = (event as InputEventJoypadButton).pressed
	elif event is InputEventJoypadMotion and (event as InputEventJoypadMotion).axis == JOY_AXIS_TRIGGER_RIGHT:
		unten = (event as InputEventJoypadMotion).axis_value > 0.5
	else:
		return
	if get_viewport().gui_get_focus_owner() != null:
		return
	if unten == _pad_maus_unten:
		return
	_pad_maus_unten = unten
	var klick := InputEventMouseButton.new()
	klick.button_index = MOUSE_BUTTON_LEFT
	klick.pressed = unten
	# Eingespeiste Ereignisse erwartet Godot in Fensterpixeln und rechnet sie
	# selbst aufs Bild um — mit Bildkoordinaten landete der Klick bei jeder
	# Auflösung ausser der Grundgrösse daneben (Maulwurf: falsches Loch).
	klick.position = get_viewport().get_final_transform() * _zeiger_ort()
	klick.global_position = klick.position
	_senden(klick)

func _senden(ev: InputEvent) -> void:
	ev.device = InputEvent.DEVICE_ID_EMULATION
	_eigene_eingabe = true
	Input.parse_input_event(ev)
	_eigene_eingabe = false

## Woran wird gerade gespielt? Steuert, ob in Hinweisen „[E]" oder „[A]" steht.
## Ein Stick driftet im Ruhezustand leicht — darum erst ab halbem Ausschlag.
func _eingabeart_merken(event: InputEvent) -> void:
	if _eigene_eingabe or event.device == InputEvent.DEVICE_ID_EMULATION:
		return   # selbst erzeugte Maus zaehlt nicht als „spielt mit der Maus"
	if event is InputEventMouseMotion and Time.get_ticks_msec() < _pad_maus_bis:
		return   # der vom Stick geschobene Zeiger
	if event is InputEventMouseMotion:
		_zeiger = Vector2.INF   # echte Maus: ab jetzt gilt wieder ihr Ort
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
		_anzeige_anwenden()
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	get_tree().root.scaling_3d_scale = aufloesung
	Engine.max_fps = fps_grenze
	for bus: String in lautstaerke:
		_bus_anwenden(bus)
	_tasten_anwenden()
	geaendert.emit()

## Bildschirm, Modus und Fenstergröße setzen. Reihenfolge zählt: erst auf den
## richtigen Bildschirm, dann Modus, im Fenster dann Größe und Mitte.
func _anzeige_anwenden() -> void:
	vollbild = modus != "fenster"
	var anzahl := DisplayServer.get_screen_count()
	var ziel := monitor if monitor >= 0 and monitor < anzahl else DisplayServer.window_get_current_screen()
	var soll := DisplayServer.WINDOW_MODE_WINDOWED
	if modus == "vollbild":
		soll = DisplayServer.WINDOW_MODE_FULLSCREEN
	elif modus == "exklusiv":
		soll = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if DisplayServer.window_get_current_screen() != ziel:
		# Bildschirm wechseln geht nur im Fenster sauber
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_current_screen(ziel)
	if DisplayServer.window_get_mode() != soll:
		DisplayServer.window_set_mode(soll)
	if soll == DisplayServer.WINDOW_MODE_WINDOWED:
		var bild := DisplayServer.screen_get_usable_rect(ziel)
		var g := Vector2i(mini(fenster_groesse.x, bild.size.x), mini(fenster_groesse.y, bild.size.y))
		DisplayServer.window_set_size(g)
		DisplayServer.window_set_position(bild.position + (bild.size - g) / 2)

## Gängige Fenstergrößen, die auf den Bildschirm passen (größte zuerst).
func fenster_groessen() -> Array[Vector2i]:
	const ALLE := [Vector2i(3840, 2160), Vector2i(2560, 1440), Vector2i(1920, 1080),
		Vector2i(1600, 900), Vector2i(1366, 768), Vector2i(1280, 720), Vector2i(1024, 576)]
	var scr := DisplayServer.window_get_current_screen()
	var max_g := DisplayServer.screen_get_size(scr)
	var aus: Array[Vector2i] = []
	for g: Vector2i in ALLE:
		if g.x <= max_g.x and g.y <= max_g.y:
			aus.append(g)
	if not fenster_groesse in aus:
		aus.append(fenster_groesse)
	return aus

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

## Spielsprache aus Steam (Eigenschaften → Sprache), "" ohne Steam. Setzt SteamDienst.
var steam_sprache := ""

## "auto" wird zur Steam-Sprache aufgelöst, ohne Steam zur Systemsprache —
## Deutsch, Türkisch, sonst Englisch.
func aktive_sprache() -> String:
	if sprache != "auto":
		return sprache
	if steam_sprache != "":
		return steam_sprache
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
	var satz := glyph_stil
	if satz == "auto":
		satz = erkannter_stil()
	var pfad := "res://assets/ui/glyphen/%s/%s.svg" % [satz, datei]
	return pfad if ResourceLoader.exists(pfad) else ""

## Welcher Satz Knopfbilder passt zum angeschlossenen Geraet? Auf dem Steam Deck
## dessen eigene Tasten, bei einem PlayStation-Pad Kreuz/Kreis/Viereck/Dreieck,
## sonst Xbox — das ist die Belegung, die auch Windows meldet.
func erkannter_stil() -> String:
	# Steam weiss es am genauesten: Steam Input meldet ein PlayStation-Pad an das
	# Spiel oft als Xbox, kennt den echten Typ aber selbst.
	var von_steam := SteamDienst.pad_typ() if SteamDienst.aktiv else ""
	if von_steam != "":
		return von_steam
	if auf_deck():
		return "deck"
	var name := pad_name().to_lower()
	for wort: String in PS_NAMEN:
		if name.contains(wort):
			return "playstation"
	return "xbox"

## Name des ersten angeschlossenen Controllers, "" wenn keiner da ist. Fuer die
## Anzeige in den Einstellungen — ohne sie weiss niemand, ob das Spiel das Geraet
## ueberhaupt sieht.
func pad_name() -> String:
	var pads := Input.get_connected_joypads()
	return Input.get_joy_name(pads[0]) if not pads.is_empty() else ""

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
	if not am_pad or not PAD_KNOEPFE.has(aktion):
		return tasten_name(aktion)
	var knopf := int(PAD_KNOEPFE[aktion])
	var zeichen: String = GLYPH_ZEICHEN.get(aktiver_stil(), {}).get(knopf, "")
	if zeichen != "" and _glyph_schrift_da:
		return zeichen
	return PAD_NAMEN.get(knopf, tasten_name(aktion))

## Welcher Geraetesatz gerade gilt — Einstellung, sonst erkannt.
func aktiver_stil() -> String:
	return erkannter_stil() if glyph_stil == "auto" else glyph_stil

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
## Haengt die Glyphenschrift als Ersatz hinter die normale Schrift. Ohne das
## zeigt jedes Label nur ein leeres Kaestchen, wo ein Knopf stehen soll.
var _glyph_schrift_da := false
var _glyph_schrift_stil := ""

func _glyph_schrift_setzen() -> void:
	var stil := aktiver_stil()
	if stil == _glyph_schrift_stil:
		return
	var pfad: String = GLYPH_SCHRIFT.get(stil, "")
	if pfad == "" or not ResourceLoader.exists(pfad):
		_glyph_schrift_da = false
		return
	var schrift := load(pfad) as Font
	if schrift == null:
		_glyph_schrift_da = false
		return
	# ThemeDB.fallback_font ist die Schrift, die alles nimmt, was keine eigene
	# gesetzt hat — im Projekt ist das die gesamte Oberflaeche und die Welt.
	var basis: Font = _grundschrift if _grundschrift != null else ThemeDB.fallback_font
	_grundschrift = basis
	var variante := FontVariation.new()
	variante.base_font = basis
	variante.fallbacks = [schrift]
	ThemeDB.fallback_font = variante
	_glyph_schrift_da = true
	_glyph_schrift_stil = stil

var _grundschrift: Font = null

func _pad_anwenden() -> void:
	_glyph_schrift_setzen()
	for aktion: String in PAD_KNOEPFE:
		_pad_knopf(aktion, int(PAD_KNOEPFE[aktion]))
	for aktion: String in PAD_ACHSEN:
		var a: Array = PAD_ACHSEN[aktion]
		_pad_achse(aktion, int(a[0]), float(a[1]))
		# Godots Vorgabe ist 0,5 — damit müsste man den Stick halb durchdrücken,
		# bevor sich die Figur bewegt.
		InputMap.action_set_deadzone(aktion, pad_totzone)
	# Zweiter Sprint-Knopf: linken Stick eindrücken (L3) — in den meisten Spielen üblich
	_pad_knopf("sprint", JOY_BUTTON_LEFT_STICK)
	# Menüführung: Godots eingebaute ui_accept/ui_cancel haben hier nur Tasten,
	# keinen Knopf (geprüft mit tools/test_pad). Ohne diese zwei Zeilen käme man
	# am Steam Deck in kein Menü hinein und aus keinem wieder heraus.
	if not _hat_pad_knopf("ui_accept"):
		_pad_knopf("ui_accept", JOY_BUTTON_A)
	if not _hat_pad_knopf("ui_cancel"):
		_pad_knopf("ui_cancel", JOY_BUTTON_B)
	# Rechter Abzug = zweites „Benutzen": der Daumen bleibt dabei am rechten
	# Stick. Mit A allein kann man nicht gleichzeitig zielen und auslösen.
	_pad_achse("interact", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	# Linker Abzug zum Halten: Bestellungen als Text (Strg), Luft anhalten an der
	# Schießbude (Leertaste — am Controller liegt dort B, und B verlässt die Bude).
	if not InputMap.has_action(PAD_HALTEN):
		InputMap.add_action(PAD_HALTEN, 0.5)
	InputMap.action_erase_events(PAD_HALTEN)
	_pad_achse(PAD_HALTEN, JOY_AXIS_TRIGGER_LEFT, 1.0)
	# Blick mit dem rechten Stick — als eigene Aktionen, damit player.gd sie wie
	# die Maus auswerten kann.
	for aktion: String in BLICK_ACHSEN:
		if not InputMap.has_action(aktion):
			InputMap.add_action(aktion)
		InputMap.action_erase_events(aktion)
		var a: Array = BLICK_ACHSEN[aktion]
		_pad_achse(aktion, int(a[0]), float(a[1]))
		InputMap.action_set_deadzone(aktion, pad_totzone)

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
	cfg.set_value("grafik", "vollbild", modus != "fenster")
	cfg.set_value("grafik", "modus", modus)
	cfg.set_value("grafik", "fenster_groesse", fenster_groesse)
	cfg.set_value("grafik", "monitor", monitor)
	cfg.set_value("grafik", "fps_grenze", fps_grenze)
	cfg.set_value("grafik", "vollbild_seit_v276", true)
	cfg.set_value("grafik", "vsync", vsync)
	cfg.set_value("grafik", "qualitaet", grafik)
	cfg.set_value("grafik", "aufloesung", aufloesung)
	cfg.set_value("grafik", "renderer", renderer)
	for bus: String in lautstaerke:
		cfg.set_value("ton", bus, lautstaerke[bus])
	cfg.set_value("steuerung", "maus", maus)
	cfg.set_value("steuerung", "maus_y_umkehren", maus_y_umkehren)
	cfg.set_value("steuerung", "pad_empfindlichkeit", pad_empfindlichkeit)
	cfg.set_value("steuerung", "pad_y_umkehren", pad_y_umkehren)
	cfg.set_value("steuerung", "pad_totzone", pad_totzone)
	cfg.set_value("steuerung", "glyph_stil", glyph_stil)
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
	# Seit v276 ist Vollbild Standard: ältere Einstellungen einmalig umstellen
	if cfg.has_section_key("grafik", "vollbild_seit_v276"):
		vollbild = bool(cfg.get_value("grafik", "vollbild", vollbild))
	modus = str(cfg.get_value("grafik", "modus", "vollbild" if vollbild else "fenster"))
	if not modus in MODI:
		modus = "vollbild"
	var fg: Variant = cfg.get_value("grafik", "fenster_groesse", fenster_groesse)
	if fg is Vector2i:
		fenster_groesse = fg
	monitor = int(cfg.get_value("grafik", "monitor", monitor))
	fps_grenze = int(cfg.get_value("grafik", "fps_grenze", fps_grenze))
	if not fps_grenze in FPS_GRENZEN:
		fps_grenze = 0
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
	pad_empfindlichkeit = clampf(float(cfg.get_value("steuerung", "pad_empfindlichkeit", pad_empfindlichkeit)), 0.2, 3.0)
	pad_y_umkehren = bool(cfg.get_value("steuerung", "pad_y_umkehren", pad_y_umkehren))
	pad_totzone = clampf(float(cfg.get_value("steuerung", "pad_totzone", pad_totzone)), 0.05, 0.6)
	glyph_stil = str(cfg.get_value("steuerung", "glyph_stil", glyph_stil))
	if glyph_stil not in GLYPH_STILE:
		glyph_stil = "auto"
	if cfg.has_section("tasten"):
		for aktion in cfg.get_section_keys("tasten"):
			if STANDARD_TASTEN.has(aktion):
				tasten[aktion] = int(cfg.get_value("tasten", aktion))
