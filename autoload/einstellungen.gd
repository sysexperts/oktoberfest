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
}

var sprache := "auto"
var vollbild := false
var vsync := true
## Lineare Lautstärke 0..1 je Audiobus.
var lautstaerke := {"Master": 1.0, "Musik": 0.8, "SFX": 1.0, "Ambiente": 0.8}
var maus := 1.0
var maus_y_umkehren := false
## Aktion -> physischer Tastencode (nur Abweichungen vom Standard nötig).
var tasten := {}

func _ready() -> void:
	_lade()
	anwenden()

func anwenden() -> void:
	TranslationServer.set_locale(aktive_sprache())
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if vollbild else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
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

## Anzeigename einer Taste, z. B. "E" oder "Shift".
func tasten_name(aktion: String) -> String:
	return OS.get_keycode_string(taste(aktion))

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

func speichern() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("allgemein", "sprache", sprache)
	cfg.set_value("grafik", "vollbild", vollbild)
	cfg.set_value("grafik", "vsync", vsync)
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
	for bus: String in lautstaerke.keys():
		lautstaerke[bus] = float(cfg.get_value("ton", bus, lautstaerke[bus]))
	maus = clampf(float(cfg.get_value("steuerung", "maus", maus)), 0.1, 3.0)
	maus_y_umkehren = bool(cfg.get_value("steuerung", "maus_y_umkehren", maus_y_umkehren))
	if cfg.has_section("tasten"):
		for aktion in cfg.get_section_keys("tasten"):
			if STANDARD_TASTEN.has(aktion):
				tasten[aktion] = int(cfg.get_value("tasten", aktion))
