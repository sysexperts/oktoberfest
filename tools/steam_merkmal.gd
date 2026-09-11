extends SceneTree
## Prüft ein exportiertes Paket (Plan 5.1): Ist das Merkmal "steam" gesetzt, und
## überspringt boot.gd dann den Auto-Updater?
## Das Paket muss mit tools/ exportiert sein, sonst fehlt dieses Skript darin.
## Aufruf: godot --headless --main-pack <paket> --script res://tools/steam_merkmal.gd

func _init() -> void:
	var steam := OS.has_feature("steam")
	print("MERKMAL steam: ", steam)
	# boot.gd laden und schauen, ob es ohne Netzwerk direkt ins Menü will
	var boot := (load("res://scenes/boot.tscn") as PackedScene).instantiate()
	root.add_child(boot)
	await process_frame
	await process_frame
	var laedt := false
	for c in boot.get_children():
		if c is HTTPRequest:
			laedt = true
	print("UPDATER aktiv: ", laedt)
	quit()
