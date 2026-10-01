extends Node
## Misst, wie groß die Fenster der Oberfläche mindestens sein wollen (in Oberflächen-
## einheiten, also vor dem Strecken aufs Fenster). Was größer ist als der sichtbare
## Bereich, ragt auf kleinen Bildschirmen aus dem Fenster — siehe scripts/ui/passend.gd.
##   godot --path . res://tools/mess_fenster.tscn

const FENSTER := {
	"hilfe": ["res://scenes/ui/hilfe.tscn", "Mitte/Panel"],
	"festbuero": ["res://scenes/ui/festbuero.tscn", "Mitte/Panel"],
	"zelt_mieten": ["res://scenes/ui/zelt_mieten.tscn", "Mitte/Panel"],
	"abstimmung": ["res://scenes/ui/abstimmung.tscn", "Mitte/Panel"],
	"lobby": ["res://scenes/ui/lobby.tscn", "Mitte/Panel"],
	"pause": ["res://scenes/ui/pause.tscn", "Mitte"],
	"kalender": ["res://scenes/ui/kalender.tscn", "Blatt"],
	"zeitung": ["res://scenes/ui/zeitung.tscn", "Blatt"],
	"kino": ["res://scenes/ui/kino.tscn", "Brief"],
	"zeltcomputer": ["res://scenes/ui/zeltcomputer.tscn", "Panel"],
	"schicht_intro": ["res://scenes/ui/schicht_intro.tscn", "Panel"],
	"baumodus": ["res://scenes/ui/baumodus.tscn", "Seite"],
	"steam_warteraum": ["res://scenes/ui/steam_warteraum.tscn", "Mitte/Fenster"],
	"figurenwahl": ["res://scenes/ui/figurenwahl.tscn", "Mitte/Panel"],
	"spielstandwahl": ["res://scenes/ui/spielstandwahl.tscn", "Mitte/Panel"],
	"hauptmenue Hauptspalte": ["res://scenes/ui/hauptmenue.tscn", "Mitte/Hauptspalte"],
	"hauptmenue Koop": ["res://scenes/ui/hauptmenue.tscn", "Mitte/KoopPanel"],
	"hauptmenue Credits": ["res://scenes/ui/hauptmenue.tscn", "Mitte/CreditsPanel"],
	"hauptmenue Spielstand": ["res://scenes/ui/hauptmenue.tscn", "Mitte/SpielstandPanel"],
	"koop_lobby Start": ["res://scenes/ui/koop_lobby.tscn", "Start/Panel"],
	"koop_lobby Warteraum": ["res://scenes/ui/koop_lobby.tscn", "Warteraum/Fenster"],
}

func _ready() -> void:
	await get_tree().process_frame
	for name_ in FENSTER:
		var pfad: String = FENSTER[name_][0]
		var szene := (load(pfad) as PackedScene).instantiate()
		add_child(szene)
		for i in 5:
			await get_tree().process_frame
		var knoten := szene.get_node_or_null(FENSTER[name_][1]) as Control
		if knoten == null:
			print("%-24s Knoten fehlt" % name_)
		else:
			var m := knoten.get_combined_minimum_size()
			print("%-24s min %4d × %4d" % [name_, m.x, m.y])
		szene.queue_free()
		await get_tree().process_frame
	print("MESSUNG FERTIG")
	get_tree().quit()
