class_name HUD
extends CanvasLayer
## Oyun içi arayüz. Aufbau liegt in scenes/ui/hud.tscn — Leiste oben links
## (Geld · Tag und Uhrzeit · Beliebtheit, darunter Lager und Sauberkeit),
## Aufgabe rechts, Fadenkreuz mit Hinweis, Festbüro, Zelt-Computer,
## Hinweisfenster, Schlaf-Abblende.
## Die Werte kommen vom GameManager; hier wird nur angezeigt. Jeder Wert wird
## gemerkt, damit ein Sprachwechsel alles neu beschriften kann.

const Texte := preload("res://scripts/ui/texte.gd")
const Symbole := preload("res://scripts/ui/symbole.gd")
const Wirtschaft := preload("res://scripts/wirtschaft.gd")
const ROT := Color(1, 0.42, 0.35)
const GOLD := Color(1, 0.839, 0.349)
const WEISS := Color(0.949, 0.933, 0.902)

@onready var _geld: Label = %GeldWert
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
@onready var _buero: Control = %Festbuero
@onready var _computer: Control = %Zeltcomputer
@onready var _mieten: Control = %ZeltMieten
@onready var _abstimmung: Control = %Abstimmung
@onready var _lobby: Control = %Lobby
@onready var _krug: Control = %Krug
@onready var _krug_balken: ProgressBar = %KrugBalken
@onready var _krug_text: Label = %KrugText

# Zuletzt gemeldete Werte
var _money := 0
var _clock := -1.0
var _night := false
var _day := 1
var _pop := 0.0
var _hygiene := 100.0
var _krug_fuellung := 0.0
var _krug_sichtbar := false
var _krug_fuellt_stil: StyleBox = null
var _krug_voll_stil: StyleBoxFlat = null
var _bier := 0
var _essen := 0
var _quest_step := -1
var _quest_total := 0
var _hint_key := ""
var _zustand := {}

var _erledigt_token := 0

# ------------------------------------------------------------ Bewegung
## „Schicke Animationen" (Wunsch des Nutzers): die Leiste fliegt beim Start von
## links herein, Beträge zählen mit statt zu springen, Balken gleiten, und bei
## Geldänderungen stößt der Betrag kurz auf.
const EINFLUG_DAUER := 0.55
const EINFLUG_WEG := 48.0
const GELD_DAUER := 0.45
const BALKEN_DAUER := 0.5

var _geld_lauf: Tween = null
var _geld_puls: Tween = null
var _balken_laeuft := {}

func _ready() -> void:
	Symbole.setze(%SymbolGeld, "geld")
	Symbole.setze(%SymbolBier, "bier")
	Symbole.setze(%SymbolEssen, "topf")
	Symbole.setze(%SymbolBeliebtheit, "stern")
	Symbole.setze(%SymbolSauber, "besen")
	Symbole.setze(%SymbolEreignis, "ausruf")
	Symbole.setze(%SymbolLiefer, "warnung")
	Symbole.setze(%SymbolAufgabe, "haken")
	%HinweisfensterOk.pressed.connect(close_popup)
	_einfliegen()
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

## Leiste und Aufgabenseite kommen beim Start hereingeglitten statt einfach da
## zu sein. Nur Optik — Werte stehen sofort richtig.
func _einfliegen() -> void:
	# Die Inseln oben kommen versetzt von oben herab (je 70 ms später),
	# die Aufgabenseite von rechts.
	var i := 0
	for insel in (%Oben as Control).get_children():
		var feld := insel as Control
		if feld == null:
			continue
		var ziel := feld.position
		feld.position = ziel - Vector2(0.0, EINFLUG_WEG)
		feld.modulate.a = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(feld, "position", ziel, EINFLUG_DAUER) 			.set_delay(float(i) * 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(feld, "modulate:a", 1.0, EINFLUG_DAUER * 0.6).set_delay(float(i) * 0.07)
		i += 1
	var rechts: Control = %Rechts
	var ziel_r := rechts.position
	rechts.position = ziel_r + Vector2(EINFLUG_WEG, 0.0)
	rechts.modulate.a = 0.0
	var tw_r := create_tween().set_parallel(true)
	tw_r.tween_property(rechts, "position", ziel_r, EINFLUG_DAUER).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_r.tween_property(rechts, "modulate:a", 1.0, EINFLUG_DAUER * 0.7)

func _alles_neu() -> void:
	set_money(_money)
	set_time(_clock, _night)
	set_popularity(_pop)
	set_hygiene(_hygiene)
	set_stock(_bier, _essen)
	set_quest(_quest_step, _quest_total)
	set_hint(_hint_key)
	set_krug(_krug_fuellung, _krug_sichtbar)
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
	var hinweis: RichTextLabel = %HinweisText
	# Mit Glyphen: am Gamepad steht hier das Knopfbild statt eines Buchstabens.
	hinweis.text = "[center]%s[/center]" % Texte.mit_glyphen(key)
	var handlung := tr(key).contains("{")
	# RichTextLabel nennt die Schriftfarbe "default_color" — ein font_color
	# waere hier wirkungslos geblieben.
	hinweis.add_theme_color_override("default_color", WEISS if handlung else Color(0.78, 0.73, 0.66))

## Bierzuschlag bei Lieferproblemen — Wert steht im GameManager
func _gm_zuschlag() -> float:
	var gm := get_parent()
	return float(gm.LIEFERPROBLEM_ZUSCHLAG) if gm and "LIEFERPROBLEM_ZUSCHLAG" in gm else 1.3

# ------------------------------------------------------------ Krug füllen
## Füllstand des Krugs in der Hand, direkt über dem Fadenkreuz.
## Warum: Am Fass war nur am Bier im Krug zu erkennen, wie weit man ist — und
## ein halb voller Krug lässt sich nicht abgeben, ohne dass das Spiel sagt warum.
## fuellung: 0 … 1 · sichtbar: false blendet die Anzeige aus.
const KRUG_VOLL_FARBE := Color(0.55, 0.95, 0.45)

func set_krug(fuellung: float, sichtbar: bool) -> void:
	_krug_fuellung = fuellung
	_krug_sichtbar = sichtbar
	_krug.visible = sichtbar
	if not sichtbar:
		return
	var voll := fuellung >= 0.999
	_krug_balken.value = clampf(fuellung, 0.0, 1.0) * 100.0
	_krug_text.text = tr("HUD_KRUG_VOLL") if voll else tr("HUD_KRUG_FUELLT") % int(fuellung * 100.0)
	_krug_text.add_theme_color_override("font_color", KRUG_VOLL_FARBE if voll else WEISS)
	# Voll wird grün: gold auf gold war im Test nicht zu unterscheiden
	if _krug_fuellt_stil == null:
		_krug_fuellt_stil = _krug_balken.get_theme_stylebox("fill")
		_krug_voll_stil = _krug_fuellt_stil.duplicate() as StyleBoxFlat
		_krug_voll_stil.bg_color = KRUG_VOLL_FARBE
	_krug_balken.add_theme_stylebox_override("fill", _krug_voll_stil if voll else _krug_fuellt_stil)

# ------------------------------------------------------------ Leiste
func set_money(v: int) -> void:
	var vorher := _money
	_money = v
	# Dispo: bis -1000 € erlaubt, Rückzahlung kostet 5 % Zinsen
	_geld.add_theme_color_override("font_color", ROT if v < 0 else WEISS)
	_buero.setze_geld(v)
	if vorher == v:
		_geld.text = Texte.euro(v)
		return
	# Betrag läuft hoch bzw. runter statt zu springen, dazu ein kurzer Stoß
	if _geld_lauf:
		_geld_lauf.kill()
	_geld_lauf = create_tween()
	_geld_lauf.tween_method(_geld_zeigen, float(vorher), float(v), GELD_DAUER) 		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_geld_stoss(v > vorher)

## Kurzer Stoß auf einer Zahl, wenn sie sich ändert (Lager).
func _zahl_stoss(feld: Control) -> void:
	feld.scale = Vector2.ONE
	var tw := create_tween()
	tw.tween_property(feld, "scale", Vector2(1.16, 1.16), 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(feld, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _geld_zeigen(wert: float) -> void:
	_geld.text = Texte.euro(roundi(wert))

## Kurzer Stoß auf Betrag und Münzsymbol: Einnahme hell, Ausgabe rot.
func _geld_stoss(rauf: bool) -> void:
	if _geld_puls:
		_geld_puls.kill()
	var chip: Control = %SymbolGeld
	_geld.scale = Vector2(1.0, 1.0)
	_geld_puls = create_tween().set_parallel(true)
	_geld_puls.tween_property(_geld, "scale", Vector2(1.08, 1.08), 0.09).set_trans(Tween.TRANS_SINE)
	_geld_puls.chain().tween_property(_geld, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	chip.self_modulate = Color.WHITE if rauf else ROT
	_geld_puls.parallel().tween_property(chip, "self_modulate", GOLD, 0.45)

## Balken gleitet auf den neuen Wert, die Prozentzahl daneben zählt mit.
func _balken_gleiten(balken: ProgressBar, wert: Label, ziel: float) -> void:
	var laufend: Tween = _balken_laeuft.get(balken)
	if laufend:
		laufend.kill()
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
			balken.value = v
			wert.text = "%d %%" % roundi(v),
		balken.value, clampf(ziel, 0.0, 100.0), BALKEN_DAUER) 		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_balken_laeuft[balken] = tw

## Füllfarbe eines Balkens (Sauberkeit wird unter 40 % rot)
func _balken_farbe(balken: ProgressBar, farbe: Color) -> void:
	var box := balken.get_theme_stylebox("fill")
	if not balken.has_theme_stylebox_override("fill"):
		box = box.duplicate()
		balken.add_theme_stylebox_override("fill", box)
	if box is StyleBoxFlat:
		(box as StyleBoxFlat).bg_color = farbe

## Punkte werden nicht mehr angezeigt — Geld und Beliebtheit sagen mehr.
func set_score(_v: int) -> void:
	pass

## clock: Spieluhr (8.0 = 08:00). Negativ = Zelt geschlossen.
func set_time(clock: float, night: bool = false) -> void:
	_clock = clock
	_night = night
	# Eine Zeile unter dem Betrag: „Tag 3/16 · 18:30", bei geschlossenem Zelt
	# steht dort der Hinweis darauf.
	var tag := tr("HUD_DAY_SAISON") % [Wirtschaft.saison_tag(_day), Wirtschaft.SAISON_TAGE]
	if clock < 0.0:
		_zeit.text = "%s · %s" % [tag, tr("HUD_CLOSED")]
		_zeit.add_theme_color_override("font_color", Color(0.78, 0.75, 0.71))
		return
	_zeit.text = "%s · %02d:%02d" % [tag, int(clock), int((clock - float(int(clock))) * 60.0)]
	_zeit.add_theme_color_override("font_color", Color(0.86, 0.8, 0.68) if night else Color(0.78, 0.75, 0.71))

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
	_balken_gleiten(_beliebtheit, _beliebtheit_wert, v)

func set_hygiene(v: float) -> void:
	_hygiene = v
	_balken_gleiten(_sauberkeit, _sauberkeit_wert, v)
	var schmutzig := v <= 40.0
	_sauberkeit_wert.add_theme_color_override("font_color", ROT if schmutzig else WEISS)
	_balken_farbe(_sauberkeit, ROT if schmutzig else GOLD)

func set_stock(bier: int, essen: int) -> void:
	var anders := bier != _bier or essen != _essen
	if anders and _lager_bier.text != "" and is_node_ready():
		_zahl_stoss(_lager_bier if bier != _bier else _lager_essen)
	_bier = bier
	_essen = essen
	_lager_bier.text = str(bier)
	_lager_essen.text = str(essen)
	var leer := bier <= 0 and essen <= 0
	for l: Label in [_lager_bier, _lager_essen]:
		l.add_theme_color_override("font_color", ROT if leer else WEISS)

## Füllfarbe eines Balkens, ohne das Theme für alle anderen zu ändern.

# ------------------------------------------------------------ Zustand vom Server
## Zelt, Personal, Lizenzen, Bierpreis … (GameManager._buero_state).
func set_buero(z: Dictionary) -> void:
	_zustand = z
	_buero.setze_zustand(z)
	_computer.setze_zustand(z)
	_ziel_anzeigen()
	# Lieferprobleme: steht als Warnung in der Leiste, solange sie gelten —
	# angekündigt wird das Ereignis nicht, also muss man es hier sehen.
	var liefer: Control = %LieferZeile
	if bool(z.get("lieferproblem", false)) != liefer.visible:
		liefer.visible = bool(z.get("lieferproblem", false))
		if liefer.visible:
			%Liefer.text = tr("HUD_LIEFERPROBLEM") % int(round((float(_gm_zuschlag()) - 1.0) * 100.0))
			liefer.modulate.a = 0.0
			create_tween().tween_property(liefer, "modulate:a", 1.0, 0.35)
	# Heutiges Tagesereignis in der Leiste
	var ereignis := str(z.get("ereignis", ""))
	var pille: Control = %EreignisZeile
	if ereignis == "":
		pille.visible = false
	else:
		%Ereignis.text = tr("EREIGNIS_%s_TITEL" % ereignis.to_upper())
		if not pille.visible:
			# Neues Ereignis: Pille schiebt sich dazu
			pille.visible = true
			pille.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(pille, "modulate:a", 1.0, 0.35)

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
	# Nach Feierabend: der Festkurier (scenes/ui/zeitung.tscn), kurz nach der Bilanz
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
