extends RefCounted
## Lädt die Story-Daten (daten/quests.json, daten/mails.json, daten/hinweise.json, Format: docs/DATENFORMAT.md).
## Ohne class_name (Server-Klassencache), Einbinden per preload. Nur Struktur und Bedingungen stehen in den JSON-Dateien,
## alle Texte liegen unter Schlüsseln in locale/texte.csv.

const QUESTS := "res://daten/quests.json"
const MAILS := "res://daten/mails.json"
const HINWEISE := "res://daten/hinweise.json"

static var _quests: Array = []
static var _mails := {}
static var _hinweise := {}
static var _geladen := false

static func _lesen(pfad: String) -> Variant:
	if not FileAccess.file_exists(pfad):
		push_error("Story-Daten fehlen: " + pfad)
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(pfad)) != OK:
		push_error("Story-Daten kaputt: %s (Zeile %d)" % [pfad, json.get_error_line()])
		return null
	return json.data

static func laden(neu := false) -> void:
	if _geladen and not neu:
		return
	_quests = []
	_mails = {}
	_hinweise = {}
	var q: Variant = _lesen(QUESTS)
	if q is Array:
		_quests = q
	var m: Variant = _lesen(MAILS)
	if m is Array:
		for e: Dictionary in m:
			_mails[str(e.get("id", ""))] = e
	var h: Variant = _lesen(HINWEISE)
	if h is Array:
		for e: Dictionary in h:
			_hinweise[str(e.get("id", ""))] = e
	_geladen = true

static func quests() -> Array:
	laden()
	return _quests

static func quest(id: String) -> Dictionary:
	for q: Dictionary in quests():
		if str(q.get("id", "")) == id:
			return q
	return {}

static func mail(id: String) -> Dictionary:
	laden()
	return _mails.get(id, {})

static func hinweis(id: String) -> Dictionary:
	laden()
	return _hinweise.get(id, {})

## Hinweise, die zu einem Auslöser passen (z. B. "erste_pfuetze")
static func hinweise_fuer(ausloeser: String) -> Array:
	laden()
	var r := []
	for h: Dictionary in _hinweise.values():
		if str(h.get("ausloeser", "")) == ausloeser:
			r.append(h)
	return r
