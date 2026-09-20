extends Node
## Prüft die Paketaufteilung (v205): Läuft das Spiel, wenn spiel.pck über
## inhalt.pck gelegt wird — finden die Szenen ihre Modelle noch, lösen sich die
## uid://-Verweise auf? Genau das macht scripts/boot.gd im echten Start.
##
##   Godot.exe --headless --main-pack build/probe_inhalt.pck \
##     res://tools/paket_test.tscn -- <absoluter Pfad zu spiel.pck>
##
## Danach läuft test_phase1 aus dem zusammengesetzten Stand.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("[Pakettest] Kein Pfad zu spiel.pck angegeben")
		get_tree().quit(2)
		return
	var pfad: String = args[0]
	if not ProjectSettings.load_resource_pack(pfad, true):
		push_error("[Pakettest] %s ließ sich nicht laden" % pfad)
		get_tree().quit(2)
		return
	print("[Pakettest] %s über das Grundpaket gelegt" % pfad.get_file())
	get_tree().change_scene_to_file.call_deferred("res://tools/test_phase1.tscn")
