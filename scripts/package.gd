class_name Package
extends Node3D
## Geliefertes Warenpaket. Spieler nimmt es mit E auf und trägt es zum Lager.
## kind: 1 = Bier, 2 = Essen, 3 = Müllsack (zum Müllplatz vor dem Zelt, nicht ins Lager).

const Texte := preload("res://scripts/ui/texte.gd")
## Beschriftung je Sorte: WORLD_PACKAGE_1 (Bier), WORLD_PACKAGE_2 (Zutaten) in texte.csv

var pkg_id := -1
var kind := 1
var amount := 10

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("package")
	_refresh()

func set_info(k: int, amt: int) -> void:
	kind = k
	amount = amt
	if is_inside_tree():
		_refresh()

func _refresh() -> void:
	var label := get_node_or_null("Label") as Label3D
	var sack := kind == 3
	# Bier kommt als Fass, Zutaten im Karton
	var fass := kind == 1
	var k := get_node_or_null("Karton") as Node3D
	if k:
		k.visible = not sack and not fass
	var f := get_node_or_null("Fass") as Node3D
	if f:
		f.visible = fass
	var s := get_node_or_null("Sack") as Node3D
	if s:
		s.visible = sack
	if label:
		label.text = Texte.mit_tasten("WORLD_MUELLSACK") if sack else Texte.mit_tasten("WORLD_PACKAGE_%d" % clampi(kind, 1, 2)) % amount
		# Kein Schild über jedem Paket — nur das Tastensymbol, wenn anvisiert
		label.visible = false
	if sack:
		return

## Vom Spieler: dieses Paket ist anvisiert (Umriss an) — Tastensymbol zeigen
func ziel_markieren(an: bool) -> void:
	var t := get_node_or_null("TasteHinweis")
	if t:
		t.zeigen(an)
