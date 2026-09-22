class_name HUD
extends CanvasLayer
## Oyun içi arayüz. Aufbau liegt in scenes/ui/hud.tscn — Leiste oben links
## (Geld · Tag und Uhrzeit · Beliebtheit, darunter Lager und Sauberkeit),
## Aufgabe rechts, Fadenkreuz mit Hinweis, Wiesenbüro, Zelt-Computer,
## Hinweisfenster, Schlaf-Abblende.
## Die Werte kommen vom GameManager; hier wird nur angezeigt. Jeder Wert wird
## gemerkt, damit ein Sprachwechsel alles neu beschriften kann.

const Texte := preload("res://scripts/ui/texte.gd")
const Symbole := preload("res://scripts/ui/symbole.gd")
const Wirtschaft := preload("res://scripts/wirtschaft.gd")
const ROT := Color(1, 0.42, 0.35)
const GOLD := Color(1, 0.839, 0.349)
const WEISS := Color(0.949, 0.933, 0.902)

@onready var _geld: Label = %Geld
@onready var _zeit: Label = %Zeit
@onready var _beliebtheit: ProgressBar = %Beliebtheit
@onready var _beliebtheit_wert: Label = %BeliebtheitWert
@onready var _lager_bier: Label = %LagerBier
@onready var _lager_essen: Label = %LagerEssen
@onready var _sauberkeit: ProgressBar = %Sauberkeit
@onready var _sauberkeit_wert: Label = %SauberkeitWert
@onready var _aufgabe: Control = %Aufgabe
@onready var _meldungen: Control = %Meldungen
@onready var _hinweisfenster: Control = %Hinweisfenster
@onready var _buero: Control = %Wiesenbuero
@onready var _computer: Control = %Zeltcomputer
@onready var _mieten: Control = %ZeltMieten
@onready var _abstimmung: Control = %Abstimmung
@onready var _lobby: Control = %Lobby

# Zuletzt gemeldete Werte
var _money := 0
var _clock := -1.0
var _night := false
var _day := 1
var _pop := 0.0
var _hygiene := 100.0
var _bier := 0
var _essen := 0
var _quest_step := -1
var _quest_total := 0
var _hint_key := ""
var _zustand := {}

var _erledigt_token := 0

func _ready() -> void:
	Symbole.setze(%SymbolGeld, "geld")
	Symbole.setze(%SymbolBier, "bier")
	Symbole.setze(%SymbolEssen, "brezn")
	Symbole.setze(%SymbolZeit, "uhr")
	%HinweisfensterOk.pressed.connect(close_popup)
	_buero.einrichten(get_parent())
	_computer.einrichten(get_parent())
	_mieten.einrichten(get_parent())
	_abstimmung.einrichten(get_parent())
	_lobby.einrichten(get_parent())
	%SchichtIntro.einrichten(get_parent())
	Einstellungen.geaendert.connect(_alles_neu)
	Einstellungen.screenshot_gespeichert.connect(func(pfad: String) -> void:
		melde("MSG_SCREENSHOT", [pfad], 2))
	_alles_neu()
	_einblenden()

# ------------------------------------------------------------ Offene Bestellungen
## Rechts unter der Aufgabe: was die Gäste gerade wollen, z. B. „8× Helles"
## (Test 13.09.). Zählt die Bestellungen der sichtbaren Gäste, auch bei Clients.
const BESTELL_ZEILE := preload("res://scenes/ui/bestell_zeile.tscn")
const BESTELL_TAKT := 0.5
const BIER_NAMEN := {1: "Helles", 2: "Weizen", 3: "Radler", 4: "Festbier"}
const ESSEN_NAMEN := {1: "Brezn", 2: "Würstl", 3: "Hendl"}
var _bestell_t := 0.0
var _bestell_zeilen := {}   # "art_typ" -> Zeile

func _process(delta: float) -> void:
	_bestell_t -= delta
	if _bestell_t > 0.0:
		return
	_bestell_t = BESTELL_TAKT
	_bestellungen_neu()

func _bestellungen_neu() -> void:
	var gm := get_parent()
	var zaehler := {}
	if gm and "_guests" in gm:
		for c in (gm._guests as Dictionary).values():
			if is_instance_valid(c) and int(c.order_state) == 1:
				var k := "%d_%d" % [int(c.order_kind), int(c.order_type)]
				zaehler[k] = int(zaehler.get(k, 0)) + 1
	for k: String in _bestell_zeilen.keys():
		if not zaehler.has(k):
			(_bestell_zeilen[k] as Node).call("weg")
			_bestell_zeilen.erase(k)
	var reihenfolge: Array = zaehler.keys()
	reihenfolge.sort_custom(func(a: String, b: String) -> bool: return int(zaehler[a]) > int(zaehler[b]))
	var liste: Node = %BestellListe
	for i in reihenfolge.size():
		var k: String = reihenfolge[i]
		var teile := k.split("_")
		var art := int(teile[0])
		var typ := int(teile[1])
		var zeile: Node = _bestell_zeilen.get(k)
		if zeile == null:
			zeile = BESTELL_ZEILE.instantiate()
			liste.add_child(zeile)
			_bestell_zeilen[k] = zeile
		if art == 2:
			zeile.setzen("brezn", Customer.FOOD_COLORS.get(typ, Color.WHITE), int(zaehler[k]), ESSEN_NAMEN.get(typ, "?"))
		else:
			zeile.setzen("bier", Customer.BEER_COLORS.get(typ, Color.WHITE), int(zaehler[k]), BIER_NAMEN.get(typ, "?"))
		liste.move_child(zeile, i)
	%Bestellungen.visible = not zaehler.is_empty()

## Beim Spielstart aus dem Schwarz des Ladebildschirms einblenden.
func _einblenden() -> void:
	var fade: ColorRect = %Abblenden
	fade.visible = true
	fade.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.6)
	tw.tween_callback(func() -> void: fade.visible = false)

func _alles_neu() -> void:
	set_money(_money)
	set_time(_clock, _night)
	set_popularity(_pop)
	set_hygiene(_hygiene)
	set_stock(_bier, _essen)
	set_quest(_quest_step, _quest_total)
	set_hint(_hint_key)
	set_buero(_zustand)
	%HilfeHinweis.text = Texte.mit_tasten("HUD_HELP_HINT") + "   ·   " + tr("HUD_DETAILS_HINT")

# ------------------------------------------------------------ Fadenkreuz
## Hinweis unter dem Fadenkreuz. key: Übersetzungsschlüssel, "" = ausblenden.
## Hinweise mit Taste sind Handlungen (hell), ohne Taste nur Auskunft (gedämpft).
func set_hint(key: String) -> void:
	_hint_key = key
	%Hinweis.visible = key != ""
	if key == "":
		return
	var hinweis: Label = %HinweisText
	hinweis.text = Texte.mit_tasten(key)
	var handlung := tr(key).contains("{")
	hinweis.add_theme_color_override("font_color", WEISS if handlung else Color(0.78, 0.73, 0.66))

# ------------------------------------------------------------ Leiste
func set_money(v: int) -> void:
	_money = v
	_geld.text = Texte.euro(v)
	# Dispo: bis -1000 € erlaubt, Rückzahlung kostet 5 % Zinsen
	_geld.add_theme_color_override("font_color", ROT if v < 0 else WEISS)
	_buero.setze_geld(v)

## Punkte werden nicht mehr angezeigt — Geld und Beliebtheit sagen mehr.
func set_score(_v: int) -> void:
	pass

## clock: Spieluhr (7.0 = 07:00). Negativ = Zelt geschlossen.
func set_time(clock: float, night: bool = false) -> void:
	_clock = clock
	_night = night
	# Tag innerhalb der Wiesn, z. B. „Tag 5/16"
	var tag := tr("HUD_DAY_SAISON") % [Wirtschaft.saison_tag(_day), Wirtschaft.SAISON_TAGE]
	if clock < 0.0:
		_zeit.text = "%s · %s" % [tag, tr("HUD_CLOSED")]
		_zeit.add_theme_color_override("font_color", Color(0.82, 0.76, 0.66))
		return
	var h := int(clock)
	var m := int((clock - float(h)) * 60.0)
	Symbole.setze(%SymbolZeit, "mond" if night else "uhr")
	_zeit.text = "%s · %02d:%02d" % [tag, h, m]
	_zeit.add_theme_color_override("font_color", Color(0.86, 0.8, 0.68) if night else WEISS)

func set_day(day: int) -> void:
	_day = day
	set_time(_clock, _night)

## Geöffnet/geschlossen steckt schon in der Uhrzeit (set_time mit -1).
## Beim ersten Schichtbeginn: kurze Einführung, wer was macht.
func set_phase(offen: bool) -> void:
	if offen:
		%SchichtIntro.beim_schichtbeginn()

func set_popularity(v: float) -> void:
	_pop = v
	_beliebtheit.value = v
	_beliebtheit_wert.text = "%d %%" % roundi(v)

func set_hygiene(v: float) -> void:
	_hygiene = v
	_sauberkeit.value = v
	_sauberkeit_wert.text = "%d %%" % roundi(v)
	var schmutzig := v <= 40.0
	_sauberkeit_wert.add_theme_color_override("font_color", ROT if schmutzig else WEISS)
	_balken_farbe(_sauberkeit, ROT if schmutzig else GOLD)

func set_stock(bier: int, essen: int) -> void:
	_bier = bier
	_essen = essen
	_lager_bier.text = str(bier)
	_lager_essen.text = str(essen)
	var leer := bier <= 0 and essen <= 0
	for l: Label in [_lager_bier, _lager_essen]:
		l.add_theme_color_override("font_color", ROT if leer else WEISS)

## Füllfarbe eines Balkens, ohne das Theme für alle anderen zu ändern.
func _balken_farbe(balken: ProgressBar, farbe: Color) -> void:
	var box := balken.get_theme_stylebox("fill")
	if not balken.has_theme_stylebox_override("fill"):
		box = box.duplicate()
		balken.add_theme_stylebox_override("fill", box)
	if box is StyleBoxFlat:
		(box as StyleBoxFlat).bg_color = farbe

# ------------------------------------------------------------ Zustand vom Server
## Zelt, Personal, Lizenzen, Bierpreis … (GameManager._buero_state).
func set_buero(z: Dictionary) -> void:
	_zustand = z
	_buero.setze_zustand(z)
	_computer.setze_zustand(z)
	_ziel_anzeigen()
	# Heutiges Tagesereignis in der Leiste
	var ereignis := str(z.get("ereignis", ""))
	%Ereignis.visible = ereignis != ""
	if ereignis != "":
		%Ereignis.text = tr("EREIGNIS_%s_TITEL" % ereignis.to_upper())

## Großer Text oben (z. B. Feierabend): einblenden, stehen lassen, ausblenden.
var _gross_tween: Tween

func grosser_text(schluessel: String) -> void:
	var l: Label = %GrosserText
	l.text = Texte.meldung(schluessel)
	l.visible = true
	l.modulate.a = 0.0
	if _gross_tween:
		_gross_tween.kill()
	_gross_tween = create_tween()
	_gross_tween.tween_property(l, "modulate:a", 1.0, 0.5)
	_gross_tween.tween_interval(3.5)
	_gross_tween.tween_property(l, "modulate:a", 0.0, 1.2)
	_gross_tween.tween_callback(func() -> void: l.visible = false)

## Kombo beim Bedienen: kurz groß unter dem Fadenkreuz, dann ausblenden.
var _kombo_tween: Tween

func zeige_kombo(n: int) -> void:
	var l: Label = %Kombo
	l.text = tr("HUD_KOMBO") % n
	l.visible = true
	l.modulate.a = 1.0
	l.scale = Vector2(1.35, 1.35)
	if _kombo_tween:
		_kombo_tween.kill()
	_kombo_tween = create_tween()
	_kombo_tween.tween_property(l, "scale", Vector2.ONE, 0.15)
	_kombo_tween.tween_interval(1.2)
	_kombo_tween.tween_property(l, "modulate:a", 0.0, 0.5)

## Tagesbilanz (Zahlen, übersetzt wird hier).
func set_report(b: Dictionary) -> void:
	_buero.setze_bilanz(b)
	_computer.setze_bilanz(b)
	# Nach Feierabend: der Wiesn-Kurier (scenes/ui/zeitung.tscn), kurz nach der Bilanz
	var zeitung := get_parent().get_node_or_null("Zeitung")
	var im_test := Array(OS.get_cmdline_args()).any(func(a: String) -> bool: return a.begins_with("res://tools/") and not a.contains("zeitung"))
	if zeitung and b.has("day") and not im_test:
		get_tree().create_timer(3.0).timeout.connect(func() -> void: zeitung.zeigen(b, _zustand))

# ------------------------------------------------------------ Aufgabe
## step: aktueller Tutorialschritt, total: Anzahl. step >= total = fertig.
func set_quest(step: int, total: int) -> void:
	var vorher := _quest_step
	_quest_step = step
	_quest_total = total
	# Haken nur für echten Fortschritt — nicht beim ersten Setzen nach dem Laden
	# und nicht, wenn Überspringen mitten im Tutorial ans Ende springt.
	var uebersprungen := step == total and vorher < total - 1
	if vorher >= 0 and vorher < total and step > vorher and not uebersprungen:
		_aufgabe_erledigt(vorher)
	_buero.tutorial_schritt(step)
	_aufgabe.visible = step >= 0 and step < total
	if step >= total:
		_ziel_anzeigen()
		return
	if not _aufgabe.visible:
		return
	%AufgabeSkip.visible = true
	%AufgabeNummer.text = tr("HUD_TASK") % [step + 1, total]
	%AufgabeTitel.text = tr("QUEST_%d_TITLE" % step)
	%AufgabeText.text = Texte.mit_tasten("QUEST_%d_TEXT" % step)

## Grüner Haken mit Ton, ein paar Sekunden über der nächsten Aufgabe.
func _aufgabe_erledigt(schritt: int) -> void:
	%ErledigtText.text = tr("HUD_TASK_DONE") % tr("QUEST_%d_TITLE" % schritt)
	%Erledigt.visible = true
	var sfx := get_parent().get_node_or_null("Sfx")
	if sfx:
		sfx.play("ding")
	_erledigt_token += 1
	var mein := _erledigt_token
	await get_tree().create_timer(3.0).timeout
	if mein == _erledigt_token:
		%Erledigt.visible = false

# ------------------------------------------------------------ Meldungen
const MELDUNG := preload("res://scenes/ui/meldung.tscn")
const MAX_MELDUNGEN := 4

## Meldung unten in der Mitte. Neue kommen unten dazu, ältere rutschen hoch;
## mehr als vier auf einmal verdrängen die ältesten.
## art: 0 Info, 1 Problem, 2 Erfolg.
func melde(schluessel: String, werte: Array = [], art := 0) -> void:
	var m := MELDUNG.instantiate()
	_meldungen.add_child(m)
	m.zeige(Texte.meldung(schluessel, werte), art)
	while _meldungen.get_child_count() > MAX_MELDUNGEN:
		var alt := _meldungen.get_child(0)
		_meldungen.remove_child(alt)
		alt.queue_free()

## Modales Hinweisfenster (z. B. "erst Ware kaufen").
func show_popup(text: String) -> void:
	%HinweisfensterText.text = text
	_hinweisfenster.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%HinweisfensterOk.grab_focus()

func close_popup() -> void:
	_hinweisfenster.visible = false
	if not _computer.ist_offen() and not _buero.ist_offen() and not _mieten.ist_offen() and not _lobby.ist_offen():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_popup_open() -> bool:
	return _hinweisfenster.visible

## Kurze Schwarzblende beim Schlafen.
## Schwarzblende beim Schlafen. Danach steht kurz der neue Tag im Bild — vorher
## wechselte die Zahl oben in der Leiste einfach lautlos, und zwar schon nach
## Feierabend statt nach dem Aufstehen.
func play_sleep_fade(tag: int = 0) -> void:
	var fade: ColorRect = %Abblenden
	var zzz: Label = %Zzz
	var titel: Control = %Tagstitel
	fade.visible = true
	fade.color.a = 0.0
	zzz.modulate.a = 0.0
	titel.modulate.a = 0.0
	if tag > 0:
		(%Tag as Label).text = tr("HUD_TAG_GROSS") % tag
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.7)
	tw.parallel().tween_property(zzz, "modulate:a", 1.0, 0.7)
	tw.tween_interval(0.6)
	# Einschlafen aus, Tag ein — beides im Schwarzen
	tw.tween_property(zzz, "modulate:a", 0.0, 0.3)
	if tag > 0:
		tw.tween_property(titel, "modulate:a", 1.0, 0.5)
		tw.tween_interval(1.1)
		tw.tween_property(titel, "modulate:a", 0.0, 0.5)
	tw.tween_property(fade, "color:a", 0.0, 0.9)
	tw.tween_callback(func() -> void: fade.visible = false)

# ------------------------------------------------------------ Fenster (player.gd ruft das)
func open_booking() -> void:
	_buero.oeffnen()

func close_booking() -> void:
	_buero.schliessen()

func is_booking_open() -> bool:
	return _buero.ist_offen()

func open_computer() -> void:
	_computer.oeffnen()

func close_computer() -> void:
	_computer.schliessen()

func is_computer_open() -> bool:
	return _computer.ist_offen()

## Zelt mieten mit Namenseingabe (scenes/ui/zelt_mieten.tscn)
func open_rent() -> void:
	_mieten.oeffnen()

func close_rent() -> void:
	_mieten.schliessen()

func is_rent_open() -> bool:
	return _mieten.ist_offen()

## Abstimmung „Nächster Tag?" (scenes/ui/abstimmung.tscn)
func zeige_abstimmung(aktiv: bool, starter: String, ja: int, nein: int, gesamt: int, rest: int, schon_gestimmt: bool) -> void:
	_abstimmung.zeige(aktiv, starter, ja, nein, gesamt, rest, schon_gestimmt)

func is_vote_open() -> bool:
	return _abstimmung.ist_offen()

## Lobby: Name, Farbe, Abteilung (scenes/ui/lobby.tscn)
func open_lobby() -> void:
	_lobby.oeffnen()

func close_lobby() -> void:
	_lobby.schliessen()

func is_lobby_open() -> bool:
	return _lobby.ist_offen()

func lobby_aktualisieren(info: Dictionary) -> void:
	_lobby.aktualisieren(info)

func close_vote() -> void:
	_abstimmung.schliessen()

# ------------------------------------------------------------ Tagesziel
## Nach dem Tutorial zeigt die Aufgabenkarte das Tagesziel und Sepps Schulden
## (GameManager._tagesziel, bank_naechste). Der Stand kommt laufend per net_ziel_stand.
var _ziel_stand := -1

func set_ziel_stand(stand: int) -> void:
	_ziel_stand = stand
	_ziel_anzeigen()

func _ziel_anzeigen() -> void:
	if _quest_total <= 0 or _quest_step < _quest_total:
		return
	var ziel: Dictionary = _zustand.get("tagesziel", {})
	var bank: Array = _zustand.get("bank_naechste", [])
	_aufgabe.visible = not ziel.is_empty() or not bank.is_empty() or not (_zustand.get("huber_wette", {}) as Dictionary).is_empty()
	if not _aufgabe.visible:
		return
	%AufgabeSkip.visible = false
	%AufgabeNummer.text = tr("HUD_TAGESZIEL") % int(_zustand.get("day", 1))
	if ziel.is_empty():
		%AufgabeTitel.text = tr("HUD_ZIEL_MORGEN")
	else:
		var titel := Texte.tagesziel_text(ziel)
		var z := int(ziel.get("ziel", 0))
		if _ziel_stand >= 0:
			match str(ziel.get("typ", "")):
				"bedienen": titel += "  (%d/%d)" % [_ziel_stand, z]
				"umsatz": titel += "  (%s)" % Texte.euro(_ziel_stand)
				_: titel += "  (%d)" % _ziel_stand
		%AufgabeTitel.text = titel
	var zeilen: Array[String] = []
	if not ziel.is_empty():
		zeilen.append(tr("HUD_ZIEL_LOHN") % Texte.euro(int(ziel.get("lohn", 0))))
	if not bank.is_empty():
		zeilen.append(tr("HUD_BANK") % [Texte.euro(int(bank[1])), int(bank[0]), Texte.euro(int(_zustand.get("bank_rest", 0)))])
	var wette: Dictionary = _zustand.get("huber_wette", {})
	if not wette.is_empty():
		if bool(wette.get("angenommen", false)):
			zeilen.append(tr("HUD_HUBER_WETTE") % [Texte.huber_wette_text(wette), Texte.euro(int(wette.get("einsatz", 0)))])
		else:
			zeilen.append(tr("HUD_HUBER_ANGEBOT"))
	%AufgabeText.text = "\n".join(zeilen)

## Fertiger Text als Meldung (schon übersetzt)
func melde_text(text: String, art := 0) -> void:
	var m := MELDUNG.instantiate()
	_meldungen.add_child(m)
	m.zeige(text, art)
	while _meldungen.get_child_count() > MAX_MELDUNGEN:
		var alt := _meldungen.get_child(0)
		_meldungen.remove_child(alt)
		alt.queue_free()
