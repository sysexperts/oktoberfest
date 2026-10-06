extends Node
const Story := preload("res://scripts/story/story.gd")
const Daten := preload("res://scripts/story/daten.gd")
## Story-System prüfen (Kapitel, Quests, Fristen, Post, Hinweise, Speichern, Netz) ohne das ganze Spiel.
## godot --headless --path . res://tools/test_story.tscn

var fehler := 0
func _check(n: String, ok: bool, info := "") -> void:
	print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
	if not ok:
		fehler += 1

func _ready() -> void:
	var s: Node = Story.new()
	add_child(s)
	s.aktiv = true
	_check("Daten geladen", Daten.quests().size() >= 19 and not Daten.mail("M1-01").is_empty(), str(Daten.quests().size()))
	var mw := {}
	s.pruefen(mw, 1)
	_check("Start: Quest 1.0 offen", s.zustand("1.0") == "offen" and s.kapitel == 1, str(s.quests.keys()))
	_check("Nur eine Hauptquest offen", s.offene(true).size() == 1, str(s.offene(true)))
	# Kapitel 1 durchspielen
	s.ereignis("horst_zusage")
	mw["zelt_stufe"] = 1
	s.pruefen(mw, 1)
	_check("1.0 und 1.1 erfüllt, 1.2 offen", s.zustand("1.0") == "erfuellt" and s.zustand("1.1") == "erfuellt" and s.zustand("1.2") == "offen")
	mw["zelt_sauber"] = true
	s.pruefen(mw, 1)
	_check("Mail M1-01 beim Start von 1.3", s.post.any(func(m: Dictionary) -> bool: return m.id == "M1-01"), str(s.post.size()))
	mw.merge({"tische": 2, "bier_bestellt": true, "lieferung_da": true, "pakete_eingeraeumt": true, "geschlafen": true, "gaeste_bedient": 1}, true)
	s.pruefen(mw, 1)
	_check("1.9 offen, Kapitel noch 1", s.zustand("1.9") == "offen" and s.kapitel == 1, s.zustand("1.9"))
	mw["feierabend"] = true
	s.pruefen(mw, 1)
	_check("Kapitel 2 beginnt", s.kapitel == 2, str(s.kapitel))
	var ids: Array = s.post.map(func(m: Dictionary) -> String: return m.id)
	_check("Abendmails M1-02, M1-03, M2-01", ids.has("M1-02") and ids.has("M1-03") and ids.has("M2-01"), str(ids))
	_check("2.1 offen (Kellner)", s.zustand("2.1") == "offen", s.zustand("2.1"))
	# Kapitel 2 mit Belohnung (ohne GameManager gibt es keine Auszahlung, aber auch keinen Absturz)
	mw["personal_kellner"] = 1
	s.pruefen(mw, 2)
	_check("2.1 erfüllt, 2.2 offen, Mail M2-02", s.zustand("2.1") == "erfuellt" and s.zustand("2.2") == "offen"
		and s.post.any(func(m: Dictionary) -> bool: return m.id == "M2-02"))
	# Zufallsangebote, Fristen, Limit
	s.tag_wechsel(3, func() -> float: return 0.0)
	_check("Nebenquest als Angebot", s.angebote().size() == 1, str(s.angebote()))
	var angebot: String = s.angebote()[0]
	_check("Annehmen klappt", s.annehmen(angebot) and s.zustand(angebot) == "offen")
	var frist: int = s.quests[angebot].rest
	s.tag_wechsel(4, func() -> float: return 1.0)
	_check("Frist zählt runter", int(s.quests[angebot].rest) == frist - 1, str(s.quests[angebot]))
	for tag in range(5, 12):
		s.tag_wechsel(tag, func() -> float: return 1.0)
	_check("Quest verfällt, Mail 'Zu spät'", s.zustand(angebot) == "verfallen" and s.post.any(func(m: Dictionary) -> bool: return m.id == "M-VERFALLEN"), s.zustand(angebot))
	# Post antworten (Anfrage mit Antworten)
	s.post_senden("M2-13")
	var nr: int = s.post.size() - 1
	_check("Antwort 0 nimmt Quest an (falls Angebot vorhanden)", s.post_antworten(nr, 5) == false, "ungültige Antwort wird abgelehnt")
	_check("Doppelt senden verhindert", s.post_senden("M1-01") == false)
	_check("Ungelesen gezählt", s.ungelesen() >= 1, str(s.ungelesen()))
	s.post_lesen(0)
	# Speichern und Netz
	var d: Dictionary = s.speichern()
	var s2: Node = Story.new()
	add_child(s2)
	s2.netz_setzen(d)
	_check("Speichern/Laden gleich", s2.kapitel == s.kapitel and s2.quests.size() == s.quests.size() and s2.post.size() == s.post.size()
		and s2.flags.has("horst_zusage") and s2.aktiv == s.aktiv)
	# Hinweise
	var h: String = s.hinweis_zeigen("erste_pfuetze")
	_check("Hinweis einmal", h == "HINT_PFUETZE_1" and s.hinweis_zeigen("erste_pfuetze") == "", h)
	# JSON-Struktur: jede Quest hat Titel, Text, Bedingung und ist eindeutig
	var einmalig := {}
	var ok_struktur := true
	for q: Dictionary in Daten.quests():
		if einmalig.has(q.id) or not q.has("titel") or not q.has("bedingung") or not q.has("ausloeser"):
			ok_struktur = false
		einmalig[q.id] = true
	_check("Quest-Daten vollständig", ok_struktur)
	var mail_ok := true
	for q: Dictionary in Daten.quests():
		for key in ["mail_erfuellt"]:
			for m: String in q.get(key, []):
				if Daten.mail(m).is_empty():
					mail_ok = false
					print("    Mail fehlt:", m)
		var a: Dictionary = q.get("ausloeser", {})
		if a.has("mail") and Daten.mail(str(a.mail)).is_empty():
			mail_ok = false
			print("    Mail fehlt:", a.mail)
	_check("Alle Mails der Quests existieren", mail_ok)
	print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
	get_tree().quit()
