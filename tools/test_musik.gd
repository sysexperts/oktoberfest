extends Node
## Prüft die Musikauswahl: Landen die Stücke aus assets/music auf den richtigen
## Listen, und wann müsste die Schlussnummer anfangen, damit sie vor 22:00 durch
## ist? Rechnet mit den Konstanten aus scripts/game_manager.gd.
##
##   Godot.exe --headless --path . res://tools/test_musik.tscn

const Sfx := preload("res://scripts/sfx.gd")
const GM := preload("res://scripts/game_manager.gd")

var _fehler := 0

func _pruefe(was: String, ok: bool, info: String = "") -> void:
	print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", was, info])
	if not ok:
		_fehler += 1

func _ready() -> void:
	var s: Node = Sfx.new()
	s._musik_einlesen()

	print("  -- Einteilung")
	_pruefe("Instrumentals gefunden", s._instrumental.size() > 0, str(s._instrumental.size()))
	_pruefe("Gesangsstücke gefunden", s._gesang.size() > 0, str(s._gesang.size()))
	_pruefe("Schlussnummer gefunden", s._finale != null,
		"%.1f s" % (s._finale.get_length() if s._finale != null else 0.0))
	# Hauptmusik gehört ins Menü, nicht ins Zelt
	var haupt: AudioStream = load("res://assets/music/Gamesound.mp3")
	_pruefe("Gamesound nicht in der Zeltmusik",
		not s._instrumental.has(haupt) and not s._gesang.has(haupt))
	# Kein Stück darf auf zwei Listen liegen
	var doppelt := false
	for st: AudioStream in s._gesang:
		if s._instrumental.has(st):
			doppelt = true
	_pruefe("keine Überschneidung der Listen", not doppelt)
	_pruefe("Schlussnummer nicht in der normalen Gesangsliste",
		s._finale != null and not s._gesang.has(s._finale))

	print("  -- Listenwahl")
	s._kuenstler = 0
	_pruefe("ohne Künstler laufen Instrumentals", s._aktuelle_liste() == s._instrumental)
	s._kuenstler = 2
	_pruefe("mit Künstler läuft der Gesang", s._aktuelle_liste() == s._gesang)

	print("  -- Schlussnummer")
	var laenge: float = s._finale.get_length()
	s._kuenstler = 1
	s._finale_gespielt = false
	s._restzeit = laenge + 5.0
	_pruefe("noch nicht fällig, solange Zeit bleibt", not s._finale_faellig())
	s._restzeit = laenge - 1.0
	_pruefe("fällig, sobald es knapp wird", s._finale_faellig())
	s._kuenstler = 0
	_pruefe("ohne Künstler nie fällig", not s._finale_faellig())
	s._kuenstler = 1
	s._finale_gespielt = true
	_pruefe("nur einmal je Schicht", not s._finale_faellig())

	# Zur Einordnung: Wann im Spieltag fängt sie damit an?
	var start_rest := laenge
	var vergangen: float = GM.SHIFT_TIME - start_rest
	var stunde: float = GM.DAY_START_HOUR + (vergangen / GM.SHIFT_TIME) * (GM.DAY_END_HOUR - GM.DAY_START_HOUR)
	print("  Schicht %.0f s · Schlussnummer %.1f s → startet bei %02d:%02d Spielzeit" % [
		GM.SHIFT_TIME, laenge, int(stunde), int(fposmod(stunde, 1.0) * 60.0)])
	_pruefe("Schlussnummer passt überhaupt in eine Schicht", laenge < GM.SHIFT_TIME)

	s.free()
	print("ERGEBNIS: %s (%d Fehler)" % ["BESTANDEN" if _fehler == 0 else "FEHLGESCHLAGEN", _fehler])
	get_tree().quit(1 if _fehler > 0 else 0)
