@tool
extends Node3D
## Tragehaltung im Editor einstellen:
##  - „FassMitspieler" mit dem Verschiebe-/Skalier-Werkzeug an die Hände setzen
##    (so sehen es die Mitspieler)
##  - „IchSicht/FassIchSicht" verschieben; Kamera „IchSicht" auswählen und oben im
##    3D-Fenster „Vorschau" anklicken, um durch die Augen des Spielers zu sehen
##  - Arme mit den Reglern hier im Inspektor
## Alles wird sofort in assets/trage_haltung.tres gespeichert — das Spiel liest
## es beim nächsten Start.

const HALTUNG := preload("res://assets/trage_haltung.tres")

@export_range(-3.2, 3.2, 0.01) var oberarm_vor := 0.0:
	get: return HALTUNG.oberarm_vor
	set(w): _h().oberarm_vor = w; _merken()
@export_range(-3.2, 3.2, 0.01) var oberarm_innen := 0.0:
	get: return HALTUNG.oberarm_innen
	set(w): _h().oberarm_innen = w; _merken()
@export_range(-3.2, 3.2, 0.01) var unterarm := 0.0:
	get: return HALTUNG.unterarm
	set(w): _h().unterarm = w; _merken()

var _speichern_in := -1.0

func _ready() -> void:
	# Aktuelle Werte an die Knoten, Arme in Tragehaltung
	$FassMitspieler.transform = HALTUNG.fass
	$IchSicht/FassIchSicht.transform = HALTUNG.pov
	var sks := $Figur.find_children("*", "Skeleton3D", true, false)
	if not sks.is_empty() and (sks[0] as Node).get_node_or_null("TragePose") == null:
		var tp := TragePose.new()
		tp.name = "TragePose"
		(sks[0] as Node).add_child(tp)   # ohne owner: wird nicht in die Szene gespeichert

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if $FassMitspieler.transform != HALTUNG.fass:
		_h().fass = $FassMitspieler.transform
		_merken()
	if $IchSicht/FassIchSicht.transform != HALTUNG.pov:
		_h().pov = $IchSicht/FassIchSicht.transform
		_merken()
	if _speichern_in > 0.0:
		_speichern_in -= delta
		if _speichern_in <= 0.0:
			ResourceSaver.save(HALTUNG, HALTUNG.resource_path)

## Nicht bei jedem Mauszucken schreiben — kurz nach dem letzten Ändern
func _merken() -> void:
	_speichern_in = 0.4

## Konstante lässt sich nicht beschreiben, ihr Inhalt schon — über eine Variable
func _h() -> TrageHaltung:
	return HALTUNG
