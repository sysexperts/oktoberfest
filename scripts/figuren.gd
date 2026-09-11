extends RefCounted
## Alle NPC-Figuren und wer welche bekommt.
## Neue Figur: Szene unter scenes/figuren/ anlegen (siehe scripts/figur.gd) und
## hier in ALLE eintragen — Besucher, Gäste, Personal und Künstler wählen daraus.
## Ohne class_name (neue Klassennamen brauchen auf dem Server eine Neuindizierung),
## einbinden per preload.

const ALLE: Array[PackedScene] = [
	preload("res://scenes/figuren/bean.tscn"),
	preload("res://scenes/figuren/charakter2.tscn"),
	preload("res://scenes/figuren/charakter3.tscn"),
]

## Figuren, die sauber auf der Bank sitzen. charakter3 fehlt: ihr Rock ist an
## die Beine gewichtet und spreizt sich beim Sitzen zur roten Scheibe — sie
## bleibt Besucherin, Personal und Künstlerin, bis das Modell Rock-Knochen hat.
const GAESTE: Array[PackedScene] = [
	preload("res://scenes/figuren/bean.tscn"),
	preload("res://scenes/figuren/charakter2.tscn"),
]

## Sitzende Gäste: wie fuer_id, aber nur aus GAESTE.
static func fuer_gast(id: int) -> PackedScene:
	return GAESTE[posmod(id * 7 + 3, GAESTE.size())]

## Gäste, Personal, Künstler: aus der ID — so sieht jeder Mitspieler dieselbe Figur,
## ohne dass die Wahl übers Netz geschickt werden muss.
static func fuer_id(id: int) -> PackedScene:
	# Streuen, damit aufeinanderfolgende IDs nicht streng abwechseln
	return ALLE[posmod(id * 7 + 3, ALLE.size())]

## Besucher draußen laufen nur lokal — dort reicht Zufall.
static func zufaellig() -> PackedScene:
	return ALLE.pick_random()

## Ersetzt den Knoten "Model" von besitzer durch die gewählte Figur, mit gleicher
## Lage und gleichem Platz in der Szene. Gibt die Figur zurück.
static func einsetzen(besitzer: Node3D, szene: PackedScene) -> Figur:
	var alt := besitzer.get_node("Model") as Node3D
	if alt.scene_file_path == szene.resource_path and alt is Figur:
		return alt as Figur
	var neu := szene.instantiate() as Figur
	neu.transform = alt.transform
	var platz := alt.get_index()
	alt.name = "ModelAlt"
	besitzer.remove_child(alt)
	alt.queue_free()
	neu.name = "Model"
	besitzer.add_child(neu)
	besitzer.move_child(neu, platz)
	return neu
