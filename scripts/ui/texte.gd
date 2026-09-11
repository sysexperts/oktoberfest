extends RefCounted
## Kleine Helfer für sichtbare Texte, von HUD und Menüs gemeinsam genutzt.
## Bewusst ohne class_name (siehe Deploy-Notiz: neue Klassennamen brauchen auf
## dem Server eine Neuindizierung) — Einbinden per preload.

## 12345 -> "12.345" (Deutsch/Türkisch) bzw. "12,345" (Englisch).
static func geld(betrag: int) -> String:
	var trenner := "," if Einstellungen.aktive_sprache() == "en" else "."
	var s := str(absi(betrag))
	var out := ""
	while s.length() > 3:
		out = trenner + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if betrag < 0 else "") + s + out

## Betrag mit Währung in der Schreibweise der Sprache: "1.200 €" bzw. "€1,200".
static func euro(betrag: int) -> String:
	if Einstellungen.aktive_sprache() == "en":
		return ("-€" if betrag < 0 else "€") + geld(absi(betrag))
	return geld(betrag) + " €"

static func _t(schluessel: String) -> String:
	return String(TranslationServer.translate(schluessel))

## Meldung vom Server: Schlüssel plus Werte. Texte unter den Werten sind selbst
## Schlüssel (z. B. "LIC_WEIZEN") und werden übersetzt, {"euro": n} wird zum
## Betrag in der Schreibweise der Sprache, Zahlen bleiben Zahlen.
static func meldung(schluessel: String, werte: Array = []) -> String:
	var fertig := []
	for w in werte:
		if w is Dictionary and (w as Dictionary).has("euro"):
			fertig.append(euro(int(w["euro"])))
		elif w is String or w is StringName:
			fertig.append(_t(str(w)))
		else:
			fertig.append(w)
	var t := _t(schluessel)
	return t % fertig if not fertig.is_empty() else t

## Kopfzeile von Wiesenbüro und Zelt-Computer aus GameManager._buero_state.
static func buero_status(z: Dictionary) -> String:
	var text := _t("OFFICE_STATUS") % [
		_t("TENT_STAGE_%d" % int(z.get("stage", 0))), int(z.get("tables", 0)), int(z.get("limit", 0)),
		int(z.get("seats", 0)), euro(int(z.get("rent", 0)))]
	# Ab Tag 2 steigen Kosten und Preise — damit das nicht heimlich passiert
	var tag := int(z.get("day", 1))
	if tag > 1:
		text += "\n" + _t("OFFICE_SEASON") % [tag,
			roundi((Wirtschaft.kosten_faktor(tag) - 1.0) * 100.0),
			roundi((Wirtschaft.preis_faktor(tag) - 1.0) * 100.0)]
	var kredit := int(z.get("kredit", 0))
	if kredit > 0:
		text += "\n" + _t("OFFICE_LOAN") % [euro(kredit), roundi(Wirtschaft.KREDIT_ANTEIL * 100.0)]
	return text

const Wirtschaft := preload("res://scripts/wirtschaft.gd")

## Tagesbilanz aus den Zahlen, die GameManager._end_shift schickt.
static func bilanz(b: Dictionary) -> String:
	if b.is_empty():
		return _t("REPORT_NONE")
	var kopf: String
	match int(b.get("reason", 0)):
		1:
			kopf = _t("REPORT_END_COMPLAINTS")
		2:
			kopf = _t("REPORT_END_EARLY") % [int(b.get("closed_at", 0)), roundi(float(b.get("pop_penalty", 0.0)))]
		_:
			kopf = _t("REPORT_END_NORMAL")
	var netto := int(b.get("net", 0))
	var zeilen := [
		kopf,
		"",
		"📊 " + _t("HUD_DAY") % int(b.get("day", 1)),
		"%s: %s" % [_t("REPORT_REVENUE"), euro(int(b.get("earn", 0)))],
		"      " + _t("REPORT_TIPS") % euro(int(b.get("tips", 0))),
		"%s: %s" % [_t("REPORT_RENT"), euro(-int(b.get("rent", 0)))],
		"%s: %s" % [_t("REPORT_WAGES"), euro(-int(b.get("wages", 0)))],
		"%s: %s" % [_t("REPORT_GOODS"), euro(-int(b.get("goods", 0)))],
		"%s: %s" % [_t("REPORT_INTEREST"), euro(-int(b.get("interest", 0)))],
		"───────────────",
		"%s: %s%s" % [_t("REPORT_NET"), "+" if netto > 0 else "", euro(netto)],
		"",
		_t("REPORT_SERVED") % [int(b.get("served", 0)), int(b.get("missed", 0))],
		_t("REPORT_MESS") % [int(b.get("urin", 0)), int(b.get("complaints", 0)), int(b.get("left", 0))],
	]
	# Kredittilgung direkt unter den Zinsen, nur wenn es sie gab
	if int(b.get("loan", 0)) > 0:
		zeilen.insert(9, "%s: %s" % [_t("REPORT_LOAN"), euro(-int(b.get("loan", 0)))])
	var tipp_liste := tipps(b)
	if not tipp_liste.is_empty():
		zeilen.append("")
		zeilen.append(_t("TIPP_TITEL"))
		for t in tipp_liste:
			zeilen.append("• " + t)
	return "\n".join(zeilen)

## Höchstens 3 Tipps für morgen aus der Tagesbilanz — sagt, woran es hakte.
static func tipps(b: Dictionary) -> Array:
	var aus := []
	var verpasst := int(b.get("missed", 0))
	if int(b.get("ohne_ware", 0)) >= 20:
		aus.append(_t("TIPP_WARE"))
	if verpasst >= 10 and not bool(b.get("kellner", true)):
		aus.append(_t("TIPP_KELLNER"))
	elif verpasst >= 10 and not bool(b.get("zapfer", true)):
		aus.append(_t("TIPP_ZAPFER"))
	elif verpasst >= 25:
		aus.append(_t("TIPP_MEHR_PERSONAL"))
	if int(b.get("urin", 0)) >= 3 and not bool(b.get("toilet", true)):
		aus.append(_t("TIPP_TOILETTE"))
	if int(b.get("complaints", 0)) >= 5 and not bool(b.get("reinigung", true)):
		aus.append(_t("TIPP_REINIGUNG"))
	if int(b.get("net", 0)) < 0 and aus.size() < 3:
		aus.append(_t("TIPP_VERLUST"))
	if int(b.get("pop", 100)) >= 55 and aus.is_empty():
		aus.append(_t("TIPP_LAEUFT"))
	return aus.slice(0, 3)

## Übersetzt einen Schlüssel und ersetzt {aktion} durch die aktuell belegte
## Taste, z. B. "{interact}" -> "[E]". So bleiben Hinweise nach dem Umbelegen
## richtig.
static func mit_tasten(schluessel: String) -> String:
	var t := TranslationServer.translate(schluessel)
	for aktion: String in Einstellungen.STANDARD_TASTEN:
		var platzhalter := "{%s}" % aktion
		if t.contains(platzhalter):
			t = t.replace(platzhalter, "[%s]" % Einstellungen.tasten_name(aktion))
	return t
