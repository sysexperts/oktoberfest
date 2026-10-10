extends CanvasLayer
## Einstellungsmenü — funktioniert im Hauptmenü und im Pausemenü gleichermaßen.
## Aufbau liegt in scenes/ui/einstellungen.tscn. Nur die Tastenzeilen entstehen
## hier im Code, aus Einstellungen.STANDARD_TASTEN — so erscheint jede neue
## Aktion automatisch im Menü.

signal geschlossen

## Sprachnamen in ihrer eigenen Sprache — so findet jeder seine wieder.
const Fokus := preload("res://scripts/ui/fokus.gd")
const SPRACH_NAMEN := ["SET_LANG_AUTO", "Deutsch", "English", "Türkçe"]
const REITER_TITEL := ["SET_TAB_GRAPHICS", "SET_TAB_AUDIO", "SET_TAB_CONTROLS", "SET_TAB_LANGUAGE"]

@onready var _reiter: TabContainer = %Reiter
@onready var _modus: OptionButton = %Modus
@onready var _fenster: OptionButton = %FensterGroesse
@onready var _monitor: OptionButton = %Monitor
@onready var _fps: OptionButton = %FpsGrenze
const MODUS_NAMEN := ["SET_MODE_BORDERLESS", "SET_MODE_EXCLUSIVE", "SET_MODE_WINDOW"]
@onready var _vsync: CheckButton = %Vsync
@onready var _qualitaet: OptionButton = %Qualitaet
@onready var _aufloesung: HSlider = %Aufloesung
@onready var _aufloesung_wert: Label = %AufloesungWert

const QUALITAETEN := ["SET_QUALITY_LOW", "SET_QUALITY_MEDIUM", "SET_QUALITY_HIGH"]
@onready var _maus: HSlider = %Maus
@onready var _maus_wert: Label = %MausWert
@onready var _invert: CheckButton = %MausInvert
@onready var _pad_name: Label = %PadName
@onready var _pad_sens: HSlider = %PadSens
@onready var _pad_sens_wert: Label = %PadSensWert
@onready var _pad_invert: CheckButton = %PadInvert
@onready var _pad_totzone: HSlider = %PadTotzone
@onready var _pad_totzone_wert: Label = %PadTotzoneWert
@onready var _pad_glyphen: OptionButton = %PadGlyphen
## Gleiche Reihenfolge wie Einstellungen.GLYPH_STILE
const GLYPH_NAMEN := ["SET_PAD_GLYPH_AUTO", "SET_PAD_GLYPH_XBOX", "SET_PAD_GLYPH_PS", "SET_PAD_GLYPH_DECK"]
@onready var _tasten_liste: GridContainer = %TastenListe
@onready var _sprache: OptionButton = %SpracheWahl

## Bus -> [Regler, Wertanzeige]
var _regler := {}
## Aktion, für die gerade auf einen Tastendruck gewartet wird ("" = keine).
var _warte_auf := ""

func _ready() -> void:
	_regler = {
		"Master": [%VolMaster, %VolMasterWert],
		"Musik": [%VolMusik, %VolMusikWert],
		"SFX": [%VolSfx, %VolSfxWert],
		"Ambiente": [%VolAmbiente, %VolAmbienteWert],
	}
	_werte_laden()
	# Über den Knotenpfad statt über den Autoload-Namen — siehe menu.gd: in einer
	# älteren .exe gibt es das Autoload nicht, und dann würde diese Seite gar
	# nicht mehr laden.
	var klang := get_node_or_null("/root/Klang")
	if klang != null:
		# Schließen klingt anders als ein normaler Knopf — vorher markieren, damit
		# an_knoepfe() ihn überspringt und er nicht zwei Klänge bekommt.
		%Schliessen.set_meta("klang", true)
		%Schliessen.mouse_entered.connect(klang.hover)
		%Schliessen.pressed.connect(klang.zurueck)
		klang.an_knoepfe(self)
	# Kategorien links schalten den (reiterlosen) TabContainer um
	for i in _reiter.get_tab_count():
		var kat := %Kategorien.get_node_or_null("Kat%d" % i) as Button
		if kat != null:
			kat.pressed.connect(func() -> void: _reiter.current_tab = i)
	_reiter.tab_changed.connect(func(_i: int) -> void: _nachbarn())
	_modus.item_selected.connect(_on_modus)
	_fenster.item_selected.connect(_on_fenster)
	_monitor.item_selected.connect(_on_monitor)
	_fps.item_selected.connect(_on_fps)
	_vsync.toggled.connect(_on_vsync)
	_qualitaet.item_selected.connect(_on_qualitaet)
	_aufloesung.value_changed.connect(_on_aufloesung)
	# Größe der Oberfläche — eigene Datei user://ui.cfg (siehe menu_eingang.gd)
	var ui := preload("res://scripts/menu_eingang.gd")
	var groesse: float = ui.ui_groesse_laden()
	%UiGroesse.set_value_no_signal(groesse)
	%UiGroesseWert.text = "%d %%" % roundi(groesse * 100.0)
	%UiGroesse.value_changed.connect(func(wert: float) -> void:
		var cfg := ConfigFile.new()
		cfg.load(ui.UI_DATEI)
		cfg.set_value("ui", "groesse", wert)
		cfg.save(ui.UI_DATEI)
		get_tree().root.content_scale_size = ui.ui_basis(wert)
		%UiGroesseWert.text = "%d %%" % roundi(wert * 100.0))
	_maus.value_changed.connect(_on_maus)
	_invert.toggled.connect(_on_invert)
	_pad_sens.value_changed.connect(_on_pad_sens)
	_pad_invert.toggled.connect(func(an: bool) -> void: Einstellungen.pad_y_umkehren = an)
	_pad_totzone.value_changed.connect(_on_pad_totzone)
	_pad_glyphen.item_selected.connect(_on_glyphen)
	# An- und Abstecken waehrend das Menue offen ist
	Input.joy_connection_changed.connect(func(_i: int, _da: bool) -> void: _pad_anzeigen())
	for bus: String in _regler:
		(_regler[bus][0] as HSlider).value_changed.connect(_on_lautstaerke.bind(bus))
	_sprache.item_selected.connect(_on_sprache)
	%TastenReset.pressed.connect(_on_tasten_reset)
	%Schliessen.pressed.connect(schliessen)
	# Für den Supportfall: dort liegen Godots Logdateien (bis zu fünf Stück)
	%LogOrdner.pressed.connect(func() -> void:
		OS.shell_open(ProjectSettings.globalize_path("user://logs")))
	Einstellungen.geaendert.connect(_texte)
	_texte()
	_kategorie(0)
	_nachbarn()

func _werte_laden() -> void:
	_vsync.set_pressed_no_signal(Einstellungen.vsync)
	_aufloesung.set_value_no_signal(Einstellungen.aufloesung)
	_maus.set_value_no_signal(Einstellungen.maus)
	_invert.set_pressed_no_signal(Einstellungen.maus_y_umkehren)
	_pad_sens.set_value_no_signal(Einstellungen.pad_empfindlichkeit)
	_pad_invert.set_pressed_no_signal(Einstellungen.pad_y_umkehren)
	_pad_totzone.set_value_no_signal(Einstellungen.pad_totzone)
	_pad_glyphen.clear()
	for i in GLYPH_NAMEN.size():
		_pad_glyphen.add_item(tr(GLYPH_NAMEN[i]), i)
	_pad_glyphen.select(maxi(0, Einstellungen.GLYPH_STILE.find(Einstellungen.glyph_stil)))
	_pad_anzeigen()
	for bus: String in _regler:
		(_regler[bus][0] as HSlider).set_value_no_signal(float(Einstellungen.lautstaerke.get(bus, 1.0)))
	_sprache.clear()
	for i in SPRACH_NAMEN.size():
		_sprache.add_item(SPRACH_NAMEN[i], i)
	_sprache.select(maxi(0, Einstellungen.SPRACHEN.find(Einstellungen.sprache)))

## Alles, was Platzhalter hat oder aus dem Code kommt, neu beschriften.
func _texte() -> void:
	for i in mini(REITER_TITEL.size(), _reiter.get_tab_count()):
		_reiter.set_tab_title(i, tr(REITER_TITEL[i]))
		# Die Kategorien links tragen dieselben Titel — die Reiterleiste des
		# TabContainers ist ausgeblendet, umgeschaltet wird über sie.
		var kat := %Kategorien.get_node_or_null("Kat%d" % i) as Button
		if kat != null:
			kat.text = tr(REITER_TITEL[i])
	_maus_wert.text = "%.2f×" % Einstellungen.maus
	# Qualitätsstufen neu beschriften (OptionButton übersetzt seine Einträge nicht selbst)
	_qualitaet.clear()
	for i in QUALITAETEN.size():
		_qualitaet.add_item(tr(QUALITAETEN[i]), i)
	_qualitaet.select(Einstellungen.grafik)
	_aufloesung_wert.text = "%d %%" % roundi(Einstellungen.aufloesung * 100.0)
	_anzeige_listen()
	# Lautstärke-Beschriftungen und Tastenliste (standen früher mit in _renderer_hinweis)
	for bus: String in _regler:
		(_regler[bus][1] as Label).text = "%d %%" % roundi(float(Einstellungen.lautstaerke[bus]) * 100.0)
	_tasten_aufbauen()

## Anzeigemodus, Fenstergröße, Bildschirm und Bildrate beschriften und wählen.
func _anzeige_listen() -> void:
	_modus.clear()
	for i in MODUS_NAMEN.size():
		_modus.add_item(tr(MODUS_NAMEN[i]), i)
	_modus.select(maxi(0, Einstellungen.MODI.find(Einstellungen.modus)))
	_fenster.clear()
	var groessen := Einstellungen.fenster_groessen()
	for i in groessen.size():
		_fenster.add_item("%d × %d" % [groessen[i].x, groessen[i].y], i)
		if groessen[i] == Einstellungen.fenster_groesse:
			_fenster.select(i)
	# Die Fenstergröße gilt nur im Fenster — im Vollbild zählt der Bildschirm
	_fenster.disabled = Einstellungen.modus != "fenster"
	_monitor.clear()
	for i in DisplayServer.get_screen_count():
		var g := DisplayServer.screen_get_size(i)
		_monitor.add_item(tr("SET_MONITOR_N") % [i + 1, g.x, g.y], i)
	_monitor.select(DisplayServer.window_get_current_screen())
	_monitor.disabled = DisplayServer.get_screen_count() < 2
	_fps.clear()
	for i in Einstellungen.FPS_GRENZEN.size():
		var f: int = Einstellungen.FPS_GRENZEN[i]
		_fps.add_item(tr("SET_FPS_UNLIMITED") if f == 0 else str(f), i)
	_fps.select(maxi(0, Einstellungen.FPS_GRENZEN.find(Einstellungen.fps_grenze)))

## Hinweis, wenn die gewählte Darstellung erst nach einem Neustart gilt.
func _tasten_aufbauen() -> void:
	# Die Knöpfe entstehen neu — der Fokus ginge dabei verloren, und ohne Fokus
	# kommt man mit dem Controller nicht mehr weiter. Also merken und zurückgeben.
	var fokus := _warte_auf
	var alt := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if fokus == "" and alt != null and alt.get_parent() == _tasten_liste:
		fokus = str(alt.get_meta("aktion", ""))
	for c in _tasten_liste.get_children():
		c.queue_free()
	# Raster mit 4 Spalten: Name, Taste, Name, Taste — so passen alle Aktionen
	# ohne Scrollen ins Fenster, auch "Benutzen", die wichtigste.
	for aktion: String in Einstellungen.STANDARD_TASTEN:
		var name_label := Label.new()
		name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		name_label.text = tr("ACTION_" + aktion.to_upper())
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var knopf := Button.new()
		knopf.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		knopf.custom_minimum_size = Vector2(110, 32)
		knopf.text = tr("SET_PRESS_KEY") if aktion == _warte_auf else Einstellungen.tasten_name(aktion)
		knopf.pressed.connect(_on_taste_waehlen.bind(aktion))
		knopf.set_meta("aktion", aktion)
		_tasten_liste.add_child(name_label)
		_tasten_liste.add_child(knopf)
		if aktion == fokus:
			knopf.grab_focus()

func _on_taste_waehlen(aktion: String) -> void:
	_warte_auf = aktion
	_tasten_aufbauen()

## Während auf eine Taste gewartet wird, fängt dieses Menü jeden Tastendruck ab.
## ESC bricht ab, statt sich als Taste eintragen zu lassen. Ein Knopf am
## Controller bricht ebenfalls ab — sonst hinge man dort ohne Tastatur fest.
func _input(event: InputEvent) -> void:
	if _warte_auf == "":
		return
	if event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		_warte_auf = ""
		_tasten_aufbauen()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		var aktion := _warte_auf
		_warte_auf = ""
		var k := event as InputEventKey
		if k.physical_keycode != KEY_ESCAPE:
			Einstellungen.setze_taste(aktion, k.physical_keycode)
		_tasten_aufbauen()

func _unhandled_input(event: InputEvent) -> void:
	if _warte_auf != "":
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		schliessen()
	elif event is InputEventJoypadButton and event.pressed:
		# Schultertasten blättern durch die Kategorien
		var knopf := (event as InputEventJoypadButton).button_index
		if knopf == JOY_BUTTON_LEFT_SHOULDER or knopf == JOY_BUTTON_RIGHT_SHOULDER:
			get_viewport().set_input_as_handled()
			var schritt := -1 if knopf == JOY_BUTTON_LEFT_SHOULDER else 1
			_kategorie(posmod(_reiter.current_tab + schritt, _reiter.get_tab_count()))

## Am Controller: von jeder Kategorie geht es nach rechts zum ersten
## Bedienelement der offenen Seite, egal auf welcher Höhe es liegt.
func _nachbarn() -> void:
	var erstes := Fokus._suche(_reiter.get_current_tab_control())
	for i in _reiter.get_tab_count():
		var kat := %Kategorien.get_node_or_null("Kat%d" % i) as Button
		if kat != null:
			kat.focus_neighbor_right = kat.get_path_to(erstes) if erstes != null else NodePath()

## Kategorie wählen und ihren Knopf links anwählen.
func _kategorie(i: int) -> void:
	_reiter.current_tab = i
	var kat := %Kategorien.get_node_or_null("Kat%d" % i) as Button
	if kat != null:
		kat.set_pressed_no_signal(true)
		kat.grab_focus()

# ------------------------------------------------ Regler am Controller halten
## Ein Druck aufs Steuerkreuz schiebt einen Regler nur um einen Schritt — bei
## 1-%-Schritten wären das fünfzig Drücke. Gehalten läuft er in zwei Sekunden
## über die ganze Breite.
const HALTE_VERZUG := 0.35
var _halte_zeit := 0.0
var _halte_rest := 0.0

func _process(delta: float) -> void:
	var regler := get_viewport().gui_get_focus_owner() as Slider
	var richtung := _pad_richtung()
	if regler == null or richtung == 0.0:
		_halte_zeit = 0.0
		_halte_rest = 0.0
		return
	_halte_zeit += delta
	if _halte_zeit > HALTE_VERZUG:
		_regler_schieben(regler, richtung, delta)

func _pad_richtung() -> float:
	for geraet in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(geraet, JOY_BUTTON_DPAD_LEFT):
			return -1.0
		if Input.is_joy_button_pressed(geraet, JOY_BUTTON_DPAD_RIGHT):
			return 1.0
		var x := Input.get_joy_axis(geraet, JOY_AXIS_LEFT_X)
		if absf(x) > 0.5:
			return signf(x)
	return 0.0

## Sammelt Bruchteile, bis ein ganzer Schritt des Reglers voll ist.
func _regler_schieben(regler: Slider, richtung: float, delta: float) -> void:
	_halte_rest += (regler.max_value - regler.min_value) * delta * 0.5
	var schritt := maxf(regler.step, 0.0001)
	var ganze := floorf(_halte_rest / schritt)
	if ganze > 0.0:
		_halte_rest -= ganze * schritt
		regler.value += richtung * ganze * schritt

func schliessen() -> void:
	Einstellungen.speichern()
	geschlossen.emit()
	queue_free()

func _on_modus(index: int) -> void:
	Einstellungen.modus = Einstellungen.MODI[index]
	Einstellungen.anwenden()
	_anzeige_listen()

func _on_fenster(index: int) -> void:
	var groessen := Einstellungen.fenster_groessen()
	if index < groessen.size():
		Einstellungen.fenster_groesse = groessen[index]
		Einstellungen.anwenden()

func _on_monitor(index: int) -> void:
	Einstellungen.monitor = index
	Einstellungen.anwenden()
	_anzeige_listen()

func _on_fps(index: int) -> void:
	Einstellungen.fps_grenze = Einstellungen.FPS_GRENZEN[index]
	Engine.max_fps = Einstellungen.fps_grenze

func _on_vsync(an: bool) -> void:
	Einstellungen.vsync = an
	Einstellungen.anwenden()

func _on_qualitaet(index: int) -> void:
	Einstellungen.grafik = index
	Einstellungen.anwenden()   # Grafikstufe im Spiel hört auf "geaendert"

## Beim Ziehen direkt auf das Fenster — ohne das Menü jedes Mal neu aufzubauen.
func _on_aufloesung(wert: float) -> void:
	Einstellungen.aufloesung = wert
	get_tree().root.scaling_3d_scale = wert
	_aufloesung_wert.text = "%d %%" % roundi(wert * 100.0)

## Die Maus liest der Spieler bei jeder Bewegung frisch — kein anwenden() nötig.
func _on_maus(wert: float) -> void:
	Einstellungen.maus = wert
	_maus_wert.text = "%.2f×" % wert

func _on_invert(an: bool) -> void:
	Einstellungen.maus_y_umkehren = an

## Steht ein Controller bereit? Ohne diese Zeile weiss niemand, ob das Spiel das
## Geraet ueberhaupt sieht — und sucht den Fehler an der falschen Stelle.
func _pad_anzeigen() -> void:
	var name := Einstellungen.pad_name()
	_pad_name.text = name if name != "" else tr("SET_PAD_KEINER")
	_pad_sens_wert.text = "%.2f×" % Einstellungen.pad_empfindlichkeit
	_pad_totzone_wert.text = "%.2f" % Einstellungen.pad_totzone

func _on_pad_sens(wert: float) -> void:
	Einstellungen.pad_empfindlichkeit = wert
	_pad_sens_wert.text = "%.2f×" % wert

## Die Totzone steckt in der Eingabekarte — die muss neu gesetzt werden.
func _on_pad_totzone(wert: float) -> void:
	Einstellungen.pad_totzone = wert
	_pad_totzone_wert.text = "%.2f" % wert
	Einstellungen.anwenden()

func _on_glyphen(i: int) -> void:
	Einstellungen.glyph_stil = Einstellungen.GLYPH_STILE[clampi(i, 0, Einstellungen.GLYPH_STILE.size() - 1)]
	Einstellungen.speichern()
	Einstellungen.geaendert.emit()

## Direkt auf den Bus — beim Ziehen feuert das dutzendfach, da soll nicht
## jedes Mal das ganze Menü neu aufgebaut werden.
func _on_lautstaerke(wert: float, bus: String) -> void:
	Einstellungen.setze_lautstaerke(bus, wert)
	(_regler[bus][1] as Label).text = "%d %%" % roundi(wert * 100.0)

func _on_sprache(index: int) -> void:
	Einstellungen.sprache = Einstellungen.SPRACHEN[index]
	Einstellungen.anwenden()
	Einstellungen.speichern()

func _on_tasten_reset() -> void:
	Einstellungen.tasten_zuruecksetzen()
