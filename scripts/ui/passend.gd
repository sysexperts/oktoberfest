extends Node
## Hält ein Fenster der Oberfläche im sichtbaren Bereich. Auf kleinen Bildschirmen
## oder bei großer Oberfläche (Einstellungen → Größe der Oberfläche) ist das Fenster
## sonst größer als das Bild: Titel oder Knöpfe ragen heraus. Dieser Knoten
## schrumpft es dann so weit, dass es mit etwas Rand hineinpasst; passt es schon,
## bleibt es in Originalgröße.
##
## Als Kind des Fensters einhängen (PanelContainer, VBox …), das mittig sitzt: in
## einem CenterContainer oder mit mittigen Ankern. Skaliert wird nicht das Fenster
## selbst, sondern der Knoten darüber, den kein Container verwaltet — Container
## setzen die Skalierung ihrer Kinder bei jeder Anordnung auf 1 zurück.
## Gemessen wird per tools/mess_fenster.tscn.

@export var rand := 20.0
## Weiter verkleinern als so geht nicht — dann lieber scrollen
@export var kleinster_faktor := 0.45

var _fenster: Control
var _ziel: Control

func _ready() -> void:
	_fenster = get_parent() as Control
	if _fenster == null:
		return
	_ziel = _fenster
	while _ziel.get_parent() is Container:
		_ziel = _ziel.get_parent() as Control
	_fenster.minimum_size_changed.connect(_anpassen)
	_ziel.resized.connect(_anpassen)
	_fenster.visibility_changed.connect(_anpassen)
	get_viewport().size_changed.connect(_anpassen)
	_anpassen.call_deferred()

func _anpassen() -> void:
	# Mehrere Fenster teilen sich manchmal denselben Rahmen (Hauptmenü): nur das
	# sichtbare bestimmt die Größe
	if _fenster == null or not _fenster.is_inside_tree() or not _fenster.is_visible_in_tree():
		return
	var sicht := _fenster.get_viewport().get_visible_rect().size
	var noetig := _fenster.get_combined_minimum_size()
	var faktor := 1.0
	if noetig.x > 0.0 and noetig.y > 0.0:
		faktor = minf(1.0, minf((sicht.x - 2.0 * rand) / noetig.x, (sicht.y - 2.0 * rand) / noetig.y))
	faktor = maxf(faktor, kleinster_faktor)
	_ziel.pivot_offset = _ziel.size / 2.0
	if not is_equal_approx(_ziel.scale.x, faktor):
		_ziel.scale = Vector2(faktor, faktor)
