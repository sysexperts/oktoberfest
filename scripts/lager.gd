class_name Lager
extends Node3D
## Lagerregal. Getragenes Warenpaket hier mit E abladen → Bestand steigt.
##
## WICHTIG: Es gibt nur EIN gemeinsames Lager (eine Zahl je Sorte). Mehrere Regale
## sind zusätzlicher Platz, kein zweites Lager — deshalb zeigt jedes Regal einen
## eigenen Abschnitt des Gesamtbestands: Regal 1 füllt sich zuerst, Regal 2 nimmt
## den Überlauf. Verkauft wird immer vom Gesamtbestand.

const UNITS_PER_KISTE := 10
const MAX_KISTEN := 6
const KAPAZITAET := UNITS_PER_KISTE * MAX_KISTEN   # 60 Einheiten je Regal
const Texte := preload("res://scripts/ui/texte.gd")

## Zuletzt gemeldeter Stand [Bier gesamt, Essen gesamt, Regalnummer] — für
## neue Beschriftung nach Sprach- oder Tastenwechsel.
var _stand := [0, 0, 0]

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("lager")
	Einstellungen.geaendert.connect(_beschriften)
	_beschriften()

## bier/essen = Gesamtbestand, index = Nummer dieses Regals (0-basiert).
func set_stock(bier: int, essen: int, index: int = 0) -> void:
	_stand = [bier, essen, index]
	_beschriften()
	_show_kisten("Bier", _slice(bier, index))
	_show_kisten("Essen", _slice(essen, index))

func _beschriften() -> void:
	var label := get_node_or_null("Label") as Label3D
	if label == null:
		return
	var bier: int = _stand[0]
	var essen: int = _stand[1]
	var index: int = _stand[2]
	label.text = Texte.mit_tasten("WORLD_STORAGE") % [
		index + 1, _slice(bier, index), _slice(essen, index), bier, essen]

## Anteil dieses Regals am Gesamtbestand.
func _slice(total: int, index: int) -> int:
	return clampi(total - index * KAPAZITAET, 0, KAPAZITAET)

func _show_kisten(prefix: String, units: int) -> void:
	var kisten := get_node_or_null("Kisten")
	if kisten == null:
		return
	var n: int = clampi(int(ceil(float(units) / float(UNITS_PER_KISTE))), 0, MAX_KISTEN)
	for i in range(1, MAX_KISTEN + 1):
		var m := kisten.get_node_or_null("%s%d" % [prefix, i]) as MeshInstance3D
		if m:
			m.visible = i <= n
