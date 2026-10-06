extends Node
## Kapitel-Fortschritt, Quests, Post und Hinweise (Plan: docs/PLAN_STORY.md, Bauplan P1).
## Der Server rechnet (pruefen, tag_wechsel, ereignis, post_antworten …), die Clients bekommen den Stand im
## Büro-Zustand ("story") und zeigen ihn nur an. Ohne class_name (Server-Klassencache), per preload einbinden.
##
## Bedingungen (JSON, siehe docs/DATENFORMAT.md):
##   {"mw": "zelt_stufe", "min": 2}      Messwert des Spiels (Dictionary an pruefen())
##   {"flag": "geschlafen"}              Ereignis gemeldet (ereignis()), bei Zahl: {"flag": "sud", "min": 3}
##   {"quest": "1.9"}                    Quest erfüllt
##   {"alle": [...]} · {"einer": [...]} · {"nicht": {...}}
## Auslöser einer Quest: {"start": true} · {"nach": "1.9"} · {"kapitel": 2} · {"flag": "…"} · {"zufall": {"ab_kapitel": 2, "chance": 0.3}}
## (alle genannten Schlüssel müssen zugleich zutreffen).

const Daten := preload("res://scripts/story/daten.gd")

signal geaendert
signal quest_erfuellt(id: String)
signal quest_verfallen(id: String)
signal post_neu(id: String)
signal kapitel_gewechselt(nr: int)

## Gleichzeitig offen: eine Hauptquest und höchstens drei andere
const MAX_HAUPT := 1
const MAX_ANDERE := 3
## Höchstens so viele Angebote (Neben/Gefallen/Kirmes) warten zugleich auf Antwort
const MAX_ANGEBOTE := 2
const MAIL_VERFALLEN := "M-VERFALLEN"

## Aus: nichts läuft, nichts wird ausgezahlt (das alte Tutorial bleibt, bis P3 umschaltet).
@export var aktiv := true

var kapitel := 1
## id → {"z": "angeboten"|"offen"|"erfuellt"|"verfallen", "start": Tag, "rest": Tage bis Verfall (0 = keine Frist)}
var quests := {}
## [{"id": Mail-ID, "tag": Tag, "gelesen": bool, "antwort": -1 | Nummer}]
var post: Array = []
var hinweise: Array = []
var flags := {}

var _tag := 1
var _mw := {}
## GameManager: nimmt Belohnungen und unbekannte Folgen entgegen (story_belohnung, story_folge)
var _gm: Object = null

func verbinden(gm: Object) -> void:
	_gm = gm

# ------------------------------------------------------------------ Bedingungen
func _bedingung(b: Variant) -> bool:
	if b == null or (b is Dictionary and (b as Dictionary).is_empty()):
		return true
	var d := b as Dictionary
	if d.has("alle"):
		for k: Variant in d["alle"]:
			if not _bedingung(k):
				return false
		return true
	if d.has("einer"):
		for k: Variant in d["einer"]:
			if _bedingung(k):
				return true
		return false
	if d.has("nicht"):
		return not _bedingung(d["nicht"])
	if d.has("mw"):
		var w := float(_mw.get(str(d["mw"]), 0))
		return w >= float(d.get("min", 1)) and w <= float(d.get("max", 1.0e12))
	if d.has("flag"):
		var f: Variant = flags.get(str(d["flag"]), 0)
		if f is bool:
			return f
		return float(f) >= float(d.get("min", 1))
	if d.has("quest"):
		return zustand(str(d["quest"])) == "erfuellt"
	push_warning("Story: unbekannte Bedingung " + str(d))
	return false

func _ausloeser(a: Dictionary) -> bool:
	if a.has("start") and not bool(a["start"]):
		return false
	for k: String in a:
		match k:
			"start":
				pass
			"nach":
				if zustand(str(a["nach"])) != "erfuellt":
					return false
			"kapitel":
				if kapitel < int(a["kapitel"]):
					return false
			"flag":
				if not _bedingung({"flag": a["flag"]}):
					return false
			"mw":
				if not _bedingung({"mw": a["mw"], "min": a.get("min", 1)}):
					return false
			"zufall", "mail", "ereignis":
				pass   # zufall: tag_wechsel(); mail: Aktion beim Freischalten; ereignis: ereignis() setzt die Flagge
			_:
				push_warning("Story: unbekannter Auslöser " + k)
	return true

# ------------------------------------------------------------------ Abfragen
func zustand(id: String) -> String:
	return str((quests.get(id, {}) as Dictionary).get("z", ""))

func _typ(id: String) -> String:
	return str(Daten.quest(id).get("typ", ""))

## Offene Quests nach Typ ("haupt" oder alle anderen)
func offene(haupt: bool) -> Array:
	var r := []
	for id: String in quests:
		if zustand(id) == "offen" and (_typ(id) == "haupt") == haupt:
			r.append(id)
	return r

func haupt_offen() -> String:
	var h := offene(true)
	return str(h[0]) if not h.is_empty() else ""

func platz_frei(typ: String) -> bool:
	if typ == "haupt":
		return offene(true).size() < MAX_HAUPT
	return offene(false).size() < MAX_ANDERE

func angebote() -> Array:
	var r := []
	for id: String in quests:
		if zustand(id) == "angeboten":
			r.append(id)
	return r

func ungelesen() -> int:
	var n := 0
	for m: Dictionary in post:
		if not bool(m.get("gelesen", false)):
			n += 1
	return n

# ------------------------------------------------------------------ Server: Takt
## Wird nach jeder Zustandsänderung aufgerufen. mw: Messwerte des Spiels (zelt_stufe, tische, personal_kellner …)
func pruefen(mw: Dictionary, tag: int) -> void:
	if not aktiv:
		return
	_mw = mw
	_tag = tag
	var geaendert_ := false
	for _runde in 12:
		var wieder := false
		for q: Dictionary in Daten.quests():
			var id := str(q.get("id", ""))
			if quests.has(id):
				continue
			var a: Dictionary = q.get("ausloeser", {})
			if a.has("zufall"):
				continue
			if _ausloeser(a):
				_freischalten(q)
				wieder = true
				geaendert_ = true
		for id: String in quests.keys():
			if zustand(id) != "offen":
				continue
			var q := Daten.quest(id)
			if _bedingung(q.get("bedingung", {})):
				_erfuellen(id)
				wieder = true
				geaendert_ = true
		if not wieder:
			break
	if geaendert_:
		geaendert.emit()

func _freischalten(q: Dictionary) -> void:
	var id := str(q.get("id", ""))
	var typ := str(q.get("typ", "haupt"))
	var frist := int(q.get("frist_tage", 0))
	var a: Dictionary = q.get("ausloeser", {})
	if typ == "haupt":
		quests[id] = {"z": "offen", "start": _tag, "rest": 0}
	else:
		quests[id] = {"z": "angeboten", "start": _tag, "rest": frist}
	if a.has("mail"):
		post_senden(str(a["mail"]))

func _erfuellen(id: String) -> void:
	var q := Daten.quest(id)
	(quests[id] as Dictionary)["z"] = "erfuellt"
	_belohnen(q.get("belohnung", {}))
	for m: Variant in q.get("mail_erfuellt", []):
		post_senden(str(m))
	for h: Variant in q.get("hinweis_erfuellt", []):
		hinweis_gesehen(str(h))
	if q.has("kapitelabschluss"):
		kapitel_setzen(int(q["kapitelabschluss"]) + 1)
	quest_erfuellt.emit(id)

func _belohnen(b: Variant) -> void:
	if not b is Dictionary or (b as Dictionary).is_empty():
		return
	if _gm != null and _gm.has_method("story_belohnung"):
		_gm.call("story_belohnung", b)

func kapitel_setzen(nr: int) -> void:
	if nr == kapitel:
		return
	kapitel = nr
	kapitel_gewechselt.emit(nr)

## Neuer Spieltag: Fristen zählen herunter, zufällige Angebote kommen dazu
func tag_wechsel(tag: int, wuerfel: Callable = Callable()) -> void:
	if not aktiv:
		return
	_tag = tag
	for id: String in quests.keys():
		var e: Dictionary = quests[id]
		var z := str(e.get("z", ""))
		if (z == "offen" or z == "angeboten") and int(e.get("rest", 0)) > 0:
			e["rest"] = int(e["rest"]) - 1
			if int(e["rest"]) <= 0:
				_verfallen(id)
	# zufällige Angebote: höchstens eins pro Tag, nie mehr als MAX_ANGEBOTE wartende
	if angebote().size() >= MAX_ANGEBOTE:
		geaendert.emit()
		return
	var kandidaten := []
	for q: Dictionary in Daten.quests():
		var id := str(q.get("id", ""))
		var a: Dictionary = q.get("ausloeser", {})
		if quests.has(id) or not a.has("zufall"):
			continue
		var z: Dictionary = a["zufall"]
		if kapitel < int(z.get("ab_kapitel", 1)) or kapitel > int(z.get("bis_kapitel", 99)):
			continue
		var rest := a.duplicate()
		rest.erase("zufall")
		if _ausloeser(rest):
			kandidaten.append(q)
	if not kandidaten.is_empty():
		var wurf: float = wuerfel.call() if wuerfel.is_valid() else randf()
		var wahl: Dictionary = kandidaten[int(wurf * kandidaten.size()) % kandidaten.size()]
		var chance := float((wahl["ausloeser"]["zufall"] as Dictionary).get("chance", 0.3))
		var w2: float = wuerfel.call() if wuerfel.is_valid() else randf()
		if w2 <= chance:
			_freischalten(wahl)
	geaendert.emit()

func _verfallen(id: String) -> void:
	(quests[id] as Dictionary)["z"] = "verfallen"
	post_senden(MAIL_VERFALLEN)
	quest_verfallen.emit(id)

## Spieler nimmt ein Angebot an. false = Platz voll oder Quest unbekannt.
func annehmen(id: String) -> bool:
	if zustand(id) != "angeboten" or not platz_frei(_typ(id)):
		return false
	(quests[id] as Dictionary)["z"] = "offen"
	geaendert.emit()
	return true

func ablehnen(id: String) -> void:
	if zustand(id) == "angeboten":
		quests.erase(id)
		flags["abgelehnt_" + id] = true
		geaendert.emit()

## Ereignis aus dem Spiel melden: Wahrheitswert setzt die Flagge, eine Zahl zählt hoch.
func ereignis(name: String, wert: Variant = true) -> void:
	if wert is bool:
		flags[name] = wert
	else:
		flags[name] = int(flags.get(name, 0)) + int(wert)
	geaendert.emit()

# ------------------------------------------------------------------ Post
func post_senden(id: String) -> bool:
	if id == "" or Daten.mail(id).is_empty():
		push_warning("Story: Mail unbekannt " + id)
		return false
	if not bool(Daten.mail(id).get("mehrfach", false)):
		for m: Dictionary in post:
			if str(m.get("id", "")) == id:
				return false
	post.append({"id": id, "tag": _tag, "gelesen": false, "antwort": -1})
	post_neu.emit(id)
	return true

func post_lesen(nr: int) -> void:
	if nr >= 0 and nr < post.size():
		(post[nr] as Dictionary)["gelesen"] = true
		geaendert.emit()

## Antwort Nummer a (0, 1 …) auf die Mail an Stelle nr im Postfach. false = ungültig oder schon beantwortet.
func post_antworten(nr: int, a: int) -> bool:
	if nr < 0 or nr >= post.size():
		return false
	var eintrag: Dictionary = post[nr]
	if int(eintrag.get("antwort", -1)) >= 0:
		return false
	var m := Daten.mail(str(eintrag.get("id", "")))
	var antworten: Array = m.get("antworten", [])
	if a < 0 or a >= antworten.size():
		return false
	eintrag["antwort"] = a
	eintrag["gelesen"] = true
	_folge((antworten[a] as Dictionary).get("folge", {}))
	geaendert.emit()
	return true

## Folgen einer Antwort: was hier bekannt ist, passiert hier, der Rest geht an den GameManager
func _folge(f: Variant) -> void:
	if not f is Dictionary:
		return
	var rest := {}
	for k: String in f:
		match k:
			"quest_annehmen":
				annehmen(str(f[k]))
			"quest_starten":
				var q := Daten.quest(str(f[k]))
				if not q.is_empty() and not quests.has(str(f[k])):
					_freischalten(q)
					(quests[str(f[k])] as Dictionary)["z"] = "offen"
			"quest_ablehnen":
				ablehnen(str(f[k]))
			"flag":
				flags[str(f[k])] = true
			"mail":
				post_senden(str(f[k]))
			"kapitel":
				kapitel_setzen(int(f[k]))
			_:
				rest[k] = f[k]
	if not rest.is_empty():
		_belohnen(rest)
		if _gm != null and _gm.has_method("story_folge"):
			_gm.call("story_folge", rest)

# ------------------------------------------------------------------ Hinweise
## Gibt den Text-Schlüssel eines einmaligen Hinweises zurück, wenn er noch nicht gezeigt wurde ("" sonst)
func hinweis_zeigen(ausloeser: String) -> String:
	for h: Dictionary in Daten.hinweise_fuer(ausloeser):
		var id := str(h.get("id", ""))
		if not hinweise.has(id):
			hinweise.append(id)
			geaendert.emit()
			return str(h.get("text", ""))
	return ""

func hinweis_gesehen(id: String) -> void:
	if id != "" and not hinweise.has(id):
		hinweise.append(id)

# ------------------------------------------------------------------ Speichern und Netz
func speichern() -> Dictionary:
	return {"kapitel": kapitel, "quests": quests.duplicate(true), "post": post.duplicate(true),
		"hinweise": hinweise.duplicate(), "flags": flags.duplicate(), "aktiv": aktiv}

func laden(d: Variant) -> void:
	quests = {}
	post = []
	hinweise = []
	flags = {}
	kapitel = 1
	if not d is Dictionary:
		return
	var s := d as Dictionary
	kapitel = maxi(1, int(s.get("kapitel", 1)))
	for id: String in (s.get("quests", {}) as Dictionary):
		var e: Dictionary = (s["quests"] as Dictionary)[id]
		quests[id] = {"z": str(e.get("z", "offen")), "start": int(e.get("start", 1)), "rest": int(e.get("rest", 0))}
	for m: Variant in s.get("post", []):
		if m is Dictionary:
			post.append({"id": str(m.get("id", "")), "tag": int(m.get("tag", 1)), "gelesen": bool(m.get("gelesen", false)),
				"antwort": int(m.get("antwort", -1))})
	for h: Variant in s.get("hinweise", []):
		hinweise.append(str(h))
	var f: Variant = s.get("flags", {})
	if f is Dictionary:
		for k: String in f:
			flags[k] = f[k]
	aktiv = bool(s.get("aktiv", aktiv))

## Stand für die Clients (gleiche Form wie speichern)
func netz() -> Dictionary:
	return speichern()

func netz_setzen(d: Variant) -> void:
	var vorher := kapitel
	laden(d)
	geaendert.emit()
	if kapitel != vorher:
		kapitel_gewechselt.emit(kapitel)
