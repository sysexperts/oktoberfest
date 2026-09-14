class_name Ausgabe
extends Node3D
## Ausgabe an der Theke: Zapfer, Koch und Spieler stellen hier fertige Krüge und
## Essen ab, Kellner nehmen sie mit. Test 13.09.: jede Biersorte und jedes Gericht
## hat einen eigenen Stellplatz mit Aufsteller (Farbstreifen + Name), damit jeder
## weiß, wohin was gehört. Nur Darstellung — was bereitsteht, führt der
## GameManager (_ausgabe) und schickt es per set_inhalt.
## Aufbau: scenes/ausgabe.tscn — Plaetze/<Platz> mit metadata art/typ, darin
## K0…K2 (Krüge) bzw. T0…T1 (Teller).

const Texte := preload("res://scripts/ui/texte.gd")
## Farben wie beim Spieler (player.gd BEER_COLORS)
const BIER_FARBEN := {1: Color(0.95, 0.75, 0.2), 2: Color(0.85, 0.5, 0.15), 3: Color(0.85, 0.85, 0.45), 4: Color(0.75, 0.35, 0.08)}

## "kind_typ" -> Anzahl, z. B. {"1_1": 3, "2_1": 1}
var inhalt := {}
## "art_typ" -> Platz-Knoten
var _plaetze := {}

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("ausgabe")
	for platz in $Plaetze.get_children():
		_plaetze["%d_%d" % [int(platz.get_meta("art", 1)), int(platz.get_meta("typ", 1))]] = platz
	Einstellungen.geaendert.connect(_beschriften)
	set_inhalt({})

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

## Wie viele Stück passen auf den Platz dieser Sorte?
func plaetze_fuer(art: int, typ: int) -> int:
	var platz: Node = _plaetze.get("%d_%d" % [art, typ])
	if platz == null:
		return 0
	var n := 0
	for c in platz.get_children():
		if c is Krug or c is EssenTeller:
			n += 1
	return n

func set_inhalt(neu: Dictionary) -> void:
	inhalt = neu
	for schluessel: String in _plaetze:
		var platz: Node = _plaetze[schluessel]
		var art := int(platz.get_meta("art", 1))
		var typ := int(platz.get_meta("typ", 1))
		var n := int(inhalt.get(schluessel, 0))
		var i := 0
		for c in platz.get_children():
			if c is Krug:
				(c as Krug).farbe = BIER_FARBEN.get(typ, Color.WHITE)
				c.visible = i < n
				i += 1
			elif c is EssenTeller:
				(c as EssenTeller).sorte = clampi(typ, 1, 3)
				c.visible = i < n
				i += 1
		# Aufsteller leuchtet leicht auf, solange etwas auf dem Platz steht
		var aufsteller := platz.get_node_or_null("Aufsteller") as MeshInstance3D
		if aufsteller:
			aufsteller.transparency = 0.0 if n > 0 or art == 1 else 0.0
	_beschriften()

func anzahl(art: int) -> int:
	var n := 0
	for schluessel: String in inhalt:
		if schluessel.begins_with("%d_" % art):
			n += int(inhalt[schluessel])
	return n

func hat_fertiges() -> bool:
	return anzahl(1) + anzahl(2) > 0

func _beschriften() -> void:
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.text = Texte.mit_tasten("WORLD_AUSGABE") % [anzahl(1), anzahl(2)]
