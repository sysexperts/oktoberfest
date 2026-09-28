@tool
extends Node3D
## Tablett der Kellner/Köche einstellen:
##  - „Tablett" mit Verschieben (W) / Drehen (E) an die Hände setzen
##  - Arme mit den Reglern hier im Inspektor
## Wird sofort in assets/trage_haltung.tres gespeichert (tablett, tablett_*).
## Die Regler werden nicht in der Szene gespeichert — sonst schriebe das Öffnen
## alte Werte zurück.

const HALTUNG := preload("res://assets/trage_haltung.tres")
const REGLER := ["tablett_oberarm_vor", "tablett_oberarm_innen", "tablett_unterarm"]

@export_group("Arme Tablett")
## Oberarm nach vorn (−) oder hinten (+) schwenken
@export_range(-3.2, 3.2, 0.01) var tablett_oberarm_vor := 0.0:
	get: return HALTUNG.tablett_oberarm_vor
	set(w): _regler_setzen("tablett_oberarm_vor", w)
## Oberarm senken (−) oder heben (+)
@export_range(-3.2, 3.2, 0.01) var tablett_oberarm_innen := 0.0:
	get: return HALTUNG.tablett_oberarm_innen
	set(w): _regler_setzen("tablett_oberarm_innen", w)
## Ellbogen beugen
@export_range(-3.2, 3.2, 0.01) var tablett_unterarm := 0.0:
	get: return HALTUNG.tablett_unterarm
	set(w): _regler_setzen("tablett_unterarm", w)

var _speichern_in := -1.0

func _validate_property(p: Dictionary) -> void:
	if p.name in REGLER:
		p.usage &= ~PROPERTY_USAGE_STORAGE

func _regler_setzen(name: String, wert: float) -> void:
	if not is_node_ready():
		return
	_h().set(name, wert)
	_merken()

func _ready() -> void:
	$Tablett.transform = HALTUNG.tablett
	var sks := $Figur.find_children("*", "Skeleton3D", true, false)
	if not sks.is_empty() and (sks[0] as Node).get_node_or_null("TragePose") == null:
		var tp := TragePose.new()
		tp.name = "TragePose"
		tp.art = 2
		(sks[0] as Node).add_child(tp)   # ohne owner: wird nicht gespeichert

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if $Tablett.transform != HALTUNG.tablett:
		_h().tablett = $Tablett.transform
		_merken()
	if _speichern_in > 0.0:
		_speichern_in -= delta
		if _speichern_in <= 0.0:
			ResourceSaver.save(HALTUNG, HALTUNG.resource_path)

func _merken() -> void:
	_speichern_in = 0.4

func _h() -> TrageHaltung:
	return HALTUNG
