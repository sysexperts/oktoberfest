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
