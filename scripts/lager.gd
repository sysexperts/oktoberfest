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

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("lager")

## bier/essen = Gesamtbestand, index = Nummer dieses Regals (0-basiert).
func set_stock(bier: int, essen: int, index: int = 0) -> void:
	var hier_bier := _slice(bier, index)
	var hier_essen := _slice(essen, index)
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.text = "📦 LAGER %d\nHier: 🍺 %d · 🥨 %d\nGesamt: 🍺 %d · 🥨 %d\n(E: Paket abladen)" % [
			index + 1, hier_bier, hier_essen, bier, essen]
	_show_kisten("Bier", hier_bier)
	_show_kisten("Essen", hier_essen)

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
