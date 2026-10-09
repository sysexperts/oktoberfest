extends RefCounted
## Zusätzliche Q-Rad-Einträge aus Animationsclips (Mixamo u. a.). Ausgesucht wird in der Animationen-Ansicht
## (scenes/werkzeuge/animationen_ansicht.tscn), gespeichert in daten/emote_clips.json:
##   {"clips": [{"clip": "mixamo/Silly Dancing", "name": "Albern tanzen", "symbol": "tanzen"},
##               {"clips": ["geliehen/Hip_Hop_Dance", "mixamo/flair_2"], "name": "Tanzen", "symbol": "tanzen"}]}
## Ein Eintrag mit "clips" (Liste) ist eine Gruppe: bei jedem Start läuft ein zufälliger Clip daraus.
## Die Emote-Nummer ist AB + Position * GRUPPE + Nummer des Clips in der Gruppe (läuft wie alle Emotes über
## Player.emote, so sehen Mitspieler denselben Clip). Im Rad steht je Eintrag die Nummer mit Clip 0.

const DATEI := "res://daten/emote_clips.json"
const AB := 100
const GRUPPE := 10   # so viele Clips passen in eine Gruppe

static func laden() -> Array:
	var f := FileAccess.open(DATEI, FileAccess.READ)
	if f == null:
		return []
	var d: Variant = JSON.parse_string(f.get_as_text())
	return (d as Dictionary).get("clips", []) if d is Dictionary else []

static func speichern(liste: Array) -> bool:
	var f := FileAccess.open(DATEI, FileAccess.WRITE)
	if f == null:
		return false
	var zeilen: Array[String] = []
	for e: Dictionary in liste:
		zeilen.append("\t\t" + JSON.stringify(e))
	f.store_string('{\n\t"clips": [\n%s\n\t]\n}\n' % ",\n".join(zeilen))
	f.close()
	return true

## Alle Clips eines Eintrags (einzeln oder Gruppe)
static func clips_von(e: Dictionary) -> Array:
	if e.has("clips"):
		return e["clips"]
	return [e["clip"]] if e.has("clip") else []

## Rad-Nummer eines Eintrags
static func nummer(index: int) -> int:
	return AB + index * GRUPPE

## Bei Gruppen einen zufälligen Clip wählen: gibt die Emote-Nummer mit Clip zurück
static func zufall(emote: int) -> int:
	var liste := laden()
	var i := (emote - AB) / GRUPPE
	if i < 0 or i >= liste.size():
		return emote
	var n := clips_von(liste[i] as Dictionary).size()
	return nummer(i) + (randi() % n if n > 1 else 0)

## Clipname zu einer Emote-Nummer ("" = keiner)
static func clip_von(emote: int) -> String:
	var liste := laden()
	var i := (emote - AB) / GRUPPE
	var k := (emote - AB) % GRUPPE
	if emote < AB or i >= liste.size():
		return ""
	var clips := clips_von(liste[i] as Dictionary)
	return str(clips[k]) if k < clips.size() else ""
