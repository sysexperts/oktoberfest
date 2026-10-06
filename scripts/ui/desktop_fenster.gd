extends PanelContainer
## Ein Fenster auf dem Computer-Desktop (scenes/ui/desktop_fenster.tscn): Titelleiste zum Verschieben, Minimieren und Schließen,
## darunter der Inhalt (eine App). Der Desktop (scripts/ui/desktop.gd) verwaltet Reihenfolge und Taskleiste.

signal fokussiert(fenster: Control)
signal schliessen_angefordert(fenster: Control)
signal minimiert(fenster: Control)

## Welche App darin läuft ("mail", "quests" …)
var app := ""
## Inhalt so groß, wie er entworfen ist; zu große Fenster werden als Ganzes verkleinert
var inhalt_groesse := Vector2(900, 600)
var _zieht := false
var _verfuegbar := Vector2(1600, 800)
var _gr := Vector2(900, 600)

func _ready() -> void:
	%Titelleiste.gui_input.connect(_titel_eingabe)
	%Minimieren.pressed.connect(func() -> void: minimiert.emit(self))
	%Schliessen.pressed.connect(func() -> void: schliessen_angefordert.emit(self))
	pivot_offset = Vector2.ZERO

func einrichten(titel_schluessel: String, symbol: Texture2D, groesse: Vector2) -> void:
	%Titel.text = tr(titel_schluessel)
	%Symbol.texture = symbol
	inhalt_groesse = groesse
	%Inhalt.custom_minimum_size = groesse

func titel_setzen(schluessel: String) -> void:
	%Titel.text = tr(schluessel)

func inhalt() -> Control:
	return %Inhalt

## Größe an den freien Platz anpassen: passt der Inhalt nicht, schrumpft das ganze Fenster
func anpassen(verfuegbar: Vector2) -> void:
	_verfuegbar = verfuegbar
	size = Vector2.ZERO
	var noetig := get_combined_minimum_size()
	var s := minf(1.0, minf((verfuegbar.x - 24.0) / maxf(noetig.x, 1.0), (verfuegbar.y - 16.0) / maxf(noetig.y, 1.0)))
	scale = Vector2(s, s)
	_gr = noetig * s
	_klammern()

func _titel_eingabe(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_zieht = event.pressed
		fokussiert.emit(self)
	elif event is InputEventMouseMotion and _zieht and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		position += event.relative
		_klammern()

## Fenster bleibt so im Bild, dass die Titelleiste greifbar ist
func _klammern() -> void:
	var gr := _gr
	position.x = clampf(position.x, 140.0 - gr.x, _verfuegbar.x - 140.0)
	position.y = clampf(position.y, 0.0, _verfuegbar.y - 48.0)

func mittig(versatz := Vector2.ZERO) -> void:
	position = ((_verfuegbar - _gr) / 2.0 + versatz).max(Vector2.ZERO)
	_klammern()
