class_name Lager
extends Node3D
## Lagerregal. Getragenes Warenpaket hier mit E abladen → Bestand steigt.
## Die Kisten im Regal zeigen den Bestand: 1 Kiste = 10 Einheiten (max. 6 je Sorte).

const UNITS_PER_KISTE := 10
const MAX_KISTEN := 6

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("lager")

## Vom GameManager gesetzt: Beschriftung + sichtbare Kisten.
func set_stock(bier: int, essen: int) -> void:
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.text = "📦 LAGER\n🍺 %d · 🥨 %d\n(E: Paket abladen)" % [bier, essen]
	_show_kisten("Bier", bier)
	_show_kisten("Essen", essen)

func _show_kisten(prefix: String, units: int) -> void:
	var kisten := get_node_or_null("Kisten")
	if kisten == null:
		return
	var n: int = clampi(int(ceil(float(units) / float(UNITS_PER_KISTE))), 0, MAX_KISTEN)
	for i in range(1, MAX_KISTEN + 1):
		var m := kisten.get_node_or_null("%s%d" % [prefix, i]) as MeshInstance3D
		if m:
			m.visible = i <= n
