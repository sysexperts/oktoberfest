extends Node
## Lädt eine Szene wie der Ladebildschirm (im Hintergrund) und zeigt den Fortschritt. Aufruf:
##   godot --path . res://tools/lade_test.tscn -- res://scenes/main.tscn
var t := 0.0
var n := 0.0
var pfad := ""
func _ready() -> void:
	pfad = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://scenes/main.tscn"
	ResourceLoader.load_threaded_request(pfad, "", false)
func _process(d: float) -> void:
	t += d
	n += d
	if n >= 2.0:
		n = 0.0
		var p := []
		var s := ResourceLoader.load_threaded_get_status(pfad, p)
		print("LADE %s t=%.0f status=%d p=%s" % [pfad, t, s, p])
		if s != 1 or t > 60:
			get_tree().quit()
