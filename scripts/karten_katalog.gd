extends RefCounted
## Alles, was man im Baumodus (F8) auf die Karte stellen kann, nach Gruppen.
## Neue Bude: Szene hier eintragen — sie erscheint dann im Baumodus.
## Ordner-Einträge (mit „/“ am Ende) werden beim Start durchsucht (.tscn/.fbx).

const GRUPPEN := [
	["Spiele", [
		"res://scenes/kirmes/schiessstand.tscn",
		"res://scenes/kirmes/dosenwurf.tscn",
		"res://scenes/kirmes/hau_den_lukas.tscn",
		"res://scenes/kirmes/ringwurf.tscn",
		"res://scenes/kirmes/entenangeln.tscn",
		"res://scenes/kirmes/gluecksrad.tscn",
		"res://scenes/kirmes/stemmen.tscn",
		"res://scenes/kirmes/nagelbalken.tscn",
		"res://scenes/kirmes/kegeln.tscn",
	]],
	["Essen & Markt", ["res://scenes/kirmes/essen/"]],
	["Fahrgeschäfte", [
		"res://scenes/props/riesenrad.tscn",
		"res://scenes/props/karussell.tscn",
		"res://scenes/props/schiffschaukel.tscn",
		"res://scenes/props/topspin.tscn",
		"res://scenes/props/wave.tscn",
		"res://scenes/props/turm.tscn",
		"res://scenes/props/raketen.tscn",
		"res://assets/kirmes/Models/Attractions/OtherRides/",
		"res://assets/kirmes/Models/Attractions/ShipRide/",
		"res://assets/kirmes/Models/Attractions/TopSpin/",
		"res://assets/kirmes/Models/Attractions/Wave/",
		"res://assets/kirmes/Models/Attractions/RollerCoaster/",
		"res://assets/kirmes/Models/Attractions/WaterRide/",
		"res://assets/kirmes/Models/Attractions/CableRailway/",
	]],
	["Deko-Buden", [
		"res://scenes/props/enten.tscn",
		"res://scenes/props/drehscheibe.tscn",
		"res://scenes/props/suessigkeiten.tscn",
		"res://scenes/props/schiessstand.tscn",
		"res://scenes/props/marktstand.tscn",
	]],
	["Bäume & Pflanzen", [
		"res://scenes/kulisse/baum_kastanie.tscn",
		"res://scenes/kulisse/baum_linde.tscn",
		"res://scenes/kulisse/baum_ahorn.tscn",
		"res://assets/kirmes/Models/Foliage/",
	]],
	["Straßendeko", [
		"res://scenes/props/laterne.tscn",
		"res://scenes/props/lichterkette.tscn",
		"res://scenes/zelt/biergarten_tisch.tscn",
		"res://assets/kirmes/Models/Props/",
	]],
	["Gebäude", ["res://assets/kirmes/Models/Shops/", "res://assets/kirmes/Models/Ground/"]],
]

## [[Gruppe, [Pfad, …]], …] mit aufgelösten Ordnern
static func alle() -> Array:
	var aus: Array = []
	for g: Array in GRUPPEN:
		var pfade: Array = []
		for p: String in g[1]:
			if p.ends_with("/"):
				for datei in ResourceLoader.list_directory(p):
					if datei.ends_with(".tscn") or datei.ends_with(".fbx"):
						pfade.append(p + datei)
			elif ResourceLoader.exists(p):
				pfade.append(p)
		aus.append([g[0], pfade])
	return aus

static func name_von(pfad: String) -> String:
	return pfad.get_file().get_basename().replace("_", " ").capitalize()

## Nur Szenen/Modelle aus dem Spiel dürfen gesetzt werden
static func erlaubt(pfad: String) -> bool:
	return pfad.begins_with("res://") and (pfad.ends_with(".tscn") or pfad.ends_with(".fbx")) \
		and not pfad.contains("..") and ResourceLoader.exists(pfad)
