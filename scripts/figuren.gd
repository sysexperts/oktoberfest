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
	preload("res://scenes/figuren/alex.tscn"),
	# Varianten: andere Kleidung, Hut, Bart, Brille
	preload("res://scenes/figuren/wilhelm_hut_bart.tscn"),
	preload("res://scenes/figuren/wilhelm_schwarz.tscn"),
	preload("res://scenes/figuren/wilhelm_brille_bart.tscn"),
	preload("res://scenes/figuren/alex_rot_brille.tscn"),
	preload("res://scenes/figuren/alex_gruen_sonnenbrille.tscn"),
	preload("res://scenes/figuren/alex_grau_hut.tscn"),
]
## Figuren, die auf der Bank sitzen. Lisa (charakter3) sitzt mit einer
## Sitzkorrektur gegen den Rock (assets/sitz_lisa.tres, scenes/werkzeuge/sitz_haltung.tscn).
const GAESTE: Array[PackedScene] = [
	preload("res://scenes/figuren/bean.tscn"),
	preload("res://scenes/figuren/charakter2.tscn"),
	preload("res://scenes/figuren/charakter3.tscn"),
	preload("res://scenes/figuren/alex.tscn"),
	# Varianten: andere Kleidung, Hut, Bart, Brille
	preload("res://scenes/figuren/wilhelm_hut_bart.tscn"),
	preload("res://scenes/figuren/wilhelm_schwarz.tscn"),
	preload("res://scenes/figuren/wilhelm_brille_bart.tscn"),
	preload("res://scenes/figuren/alex_rot_brille.tscn"),
	preload("res://scenes/figuren/alex_gruen_sonnenbrille.tscn"),
	preload("res://scenes/figuren/alex_grau_hut.tscn"),
]
## Stehende Gäste: stehen hinter der Bank am Tisch statt zu sitzen, bestellen,
## trinken und tanzen sonst wie alle.
const STEHGAESTE: Array[PackedScene] = [
	preload("res://scenes/figuren/charakter3.tscn"),
]
## Steht dieser Gast? Etwa jeder dritte. Aus der ID, damit Server (Platz hinter
## der Bank) und alle Mitspieler (Figur, kein Hinsetzen) dasselbe entscheiden.
static func ist_stehgast(id: int) -> bool:
	return posmod(id * 5 + 1, 3) == 0
## Gäste: Stehgäste aus STEHGAESTE, alle anderen sitzen und kommen aus GAESTE.
static func fuer_gast(id: int) -> PackedScene:
	if ist_stehgast(id):
		return STEHGAESTE[posmod(int(id / 3), STEHGAESTE.size())]
	# Sitzende Gäste lückenlos durchzählen (Stehgäste sind die IDs mit id % 3 == 1),
	# damit jede Figur in GAESTE drankommt, egal wie viele es sind
	return GAESTE[posmod(id - int((id + 1) / 3), GAESTE.size())]
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
