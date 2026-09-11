extends CanvasLayer
## Einstellungsmenü — funktioniert im Hauptmenü und im Pausemenü gleichermaßen.
## Aufbau liegt in scenes/ui/einstellungen.tscn. Nur die Tastenzeilen entstehen
## hier im Code, aus Einstellungen.STANDARD_TASTEN — so erscheint jede neue
## Aktion automatisch im Menü.

signal geschlossen

## Sprachnamen in ihrer eigenen Sprache — so findet jeder seine wieder.
const SPRACH_NAMEN := ["SET_LANG_AUTO", "Deutsch", "English", "Türkçe"]
const REITER_TITEL := ["SET_TAB_GRAPHICS", "SET_TAB_AUDIO", "SET_TAB_CONTROLS", "SET_TAB_LANGUAGE"]

@onready var _reiter: TabContainer = %Reiter
@onready var _vollbild: CheckButton = %Vollbild
@onready var _vsync: CheckButton = %Vsync
@onready var _qualitaet: OptionButton = %Qualitaet
@onready var _aufloesung: HSlider = %Aufloesung
@onready var _aufloesung_wert: Label = %AufloesungWert

const QUALITAETEN := ["SET_QUALITY_LOW", "SET_QUALITY_MEDIUM", "SET_QUALITY_HIGH"]
@onready var _maus: HSlider = %Maus
@onready var _maus_wert: Label = %MausWert
@onready var _invert: CheckButton = %MausInvert
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
	_vollbild.toggled.connect(_on_vollbild)
	_vsync.toggled.connect(_on_vsync)
	_qualitaet.item_selected.connect(_on_qualitaet)
	_aufloesung.value_changed.connect(_on_aufloesung)
	_maus.value_changed.connect(_on_maus)
	_invert.toggled.connect(_on_invert)
	for bus: String in _regler:
		(_regler[bus][0] as HSlider).value_changed.connect(_on_lautstaerke.bind(bus))
	_sprache.item_selected.connect(_on_sprache)
	%TastenReset.pressed.connect(_on_tasten_reset)
	%Schliessen.pressed.connect(schliessen)
	Einstellungen.geaendert.connect(_texte)
	_texte()
	%Schliessen.grab_focus()

func _werte_laden() -> void:
	_vollbild.set_pressed_no_signal(Einstellungen.vollbild)
	_vsync.set_pressed_no_signal(Einstellungen.vsync)
	_aufloesung.set_value_no_signal(Einstellungen.aufloesung)
	_maus.set_value_no_signal(Einstellungen.maus)
	_invert.set_pressed_no_signal(Einstellungen.maus_y_umkehren)
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
	_maus_wert.text = "%.2f×" % Einstellungen.maus
	# Qualitätsstufen neu beschriften (OptionButton übersetzt seine Einträge nicht selbst)
	_qualitaet.clear()
	for i in QUALITAETEN.size():
		_qualitaet.add_item(tr(QUALITAETEN[i]), i)
	_qualitaet.select(Einstellungen.grafik)
	_aufloesung_wert.text = "%d %%" % roundi(Einstellungen.aufloesung * 100.0)
	for bus: String in _regler:
		(_regler[bus][1] as Label).text = "%d %%" % roundi(float(Einstellungen.lautstaerke[bus]) * 100.0)
	_tasten_aufbauen()

func _tasten_aufbauen() -> void:
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
		_tasten_liste.add_child(name_label)
		_tasten_liste.add_child(knopf)

func _on_taste_waehlen(aktion: String) -> void:
	_warte_auf = aktion
	_tasten_aufbauen()

## Während auf eine Taste gewartet wird, fängt dieses Menü jeden Tastendruck ab.
## ESC bricht ab, statt sich als Taste eintragen zu lassen.
func _input(event: InputEvent) -> void:
	if _warte_auf == "":
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
	if _warte_auf == "" and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		schliessen()

func schliessen() -> void:
	Einstellungen.speichern()
	geschlossen.emit()
	queue_free()

func _on_vollbild(an: bool) -> void:
	Einstellungen.vollbild = an
	Einstellungen.anwenden()

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
