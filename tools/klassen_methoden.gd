extends SceneTree
## Listet Methoden, Signale und Konstanten einer Klasse — hier für Plan 5.3:
## welche Lobby- und Beitrittsfunktionen gibt es in unserer GodotSteam-Version?
## Aufruf: godot --headless --path . --script res://tools/klassen_methoden.gd

## Klasse -> Suchbegriffe (leer = alles)
const PRUEFEN := {
	"SteamMultiplayerPeer": [],
	"Steam": ["lobby", "Lobby", "invite", "Invite", "join", "Join", "friend", "Friend"],
}

func _init() -> void:
	for klasse: String in PRUEFEN:
		if not ClassDB.class_exists(klasse):
			print("===== %s FEHLT" % klasse)
			continue
		var filter: Array = PRUEFEN[klasse]
		print("===== %s (erbt von %s)" % [klasse, ClassDB.get_parent_class(klasse)])
		var methoden := []
		for m in ClassDB.class_get_method_list(klasse, true):
			var name: String = m.name
			if name.begins_with("_") or not _passt(name, filter):
				continue
			var args := []
			for a in m.args:
				args.append(a.name)
			methoden.append("%s(%s)" % [name, ", ".join(args)])
		methoden.sort()
		print("  Methoden: ")
		for m in methoden:
			print("    ", m)
		print("  Signale:")
		for s in ClassDB.class_get_signal_list(klasse, true):
			if _passt(s.name, filter):
				var args := []
				for a in s.args:
					args.append(a.name)
				print("    %s(%s)" % [s.name, ", ".join(args)])
		var konst := []
		for k in ClassDB.class_get_integer_constant_list(klasse, true):
			if _passt(k, filter) or (klasse == "Steam" and k.begins_with("LOBBY_TYPE")):
				konst.append(k)
		if not konst.is_empty():
			print("  Konstanten: ", ", ".join(konst))
	quit()

func _passt(name: String, filter: Array) -> bool:
	if filter.is_empty():
		return true
	for f: String in filter:
		if name.contains(f):
			return true
	return false
