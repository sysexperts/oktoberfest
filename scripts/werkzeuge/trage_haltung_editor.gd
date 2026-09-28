@tool
extends Node3D
## Tragehaltung im Editor einstellen (ein-/ausblenden über das Auge im Szenenbaum):
##  - „FassMitspieler" / „KartonMitspieler" mit dem Verschiebe-/Skalier-Werkzeug
##    an die Hände setzen (so sehen es die Mitspieler)
##  - „IchSicht/FassIchSicht" / „IchSicht/KartonIchSicht" verschieben; Kamera
##    „IchSicht" auswählen und oben im 3D-Fenster „Vorschau" anklicken, um durch
##    die Augen des Spielers zu sehen
##  - Arme mit den Reglern hier im Inspektor (gelten für Fass und Karton)
## Alles wird sofort in assets/trage_haltung.tres gespeichert — das Spiel liest
## es beim nächsten Start. Die Regler selbst werden NICHT in dieser Szene
## gespeichert: sonst schrieb das Öffnen der Szene alte Werte in die .tres zurück.

const HALTUNG := preload("res://assets/trage_haltung.tres")
const REGLER := ["oberarm_vor", "oberarm_innen", "unterarm"]

@export_group("Arme")
## Oberarm nach vorn (−) oder hinten (+) schwenken
@export_range(-3.2, 3.2, 0.01) var oberarm_vor := 0.0:
	get: return HALTUNG.oberarm_vor
	set(w): _regler_setzen("oberarm_vor", w)
## Oberarm senken (−) oder heben (+) — aus der T-Pose heraus
@export_range(-3.2, 3.2, 0.01) var oberarm_innen := 0.0:
	get: return HALTUNG.oberarm_innen
	set(w): _regler_setzen("oberarm_innen", w)
## Ellbogen beugen
@export_range(-3.2, 3.2, 0.01) var unterarm := 0.0:
	get: return HALTUNG.unterarm
	set(w): _regler_setzen("unterarm", w)

var _speichern_in := -1.0

## Regler im Inspektor zeigen, aber nicht in die Szene schreiben
func _validate_property(p: Dictionary) -> void:
	if p.name in REGLER:
		p.usage &= ~PROPERTY_USAGE_STORAGE

## Nur echte Änderungen im Inspektor übernehmen — nie Werte, die beim Laden
## der Szene gesetzt werden
func _regler_setzen(name: String, wert: float) -> void:
	if not is_node_ready():
		return
	_h().set(name, wert)
	_merken()

func _ready() -> void:
	# Aktuelle Werte an die Knoten, Arme in Tragehaltung
	$FassMitspieler.transform = HALTUNG.fass
	$IchSicht/FassIchSicht.transform = HALTUNG.pov
	$KartonMitspieler.transform = HALTUNG.karton
	$IchSicht/KartonIchSicht.transform = HALTUNG.karton_pov
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
	if $KartonMitspieler.transform != HALTUNG.karton:
		_h().karton = $KartonMitspieler.transform
		_merken()
	if $IchSicht/KartonIchSicht.transform != HALTUNG.karton_pov:
		_h().karton_pov = $IchSicht/KartonIchSicht.transform
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
