extends RefCounted
## Spielszene für ein Werkzeug starten und warten, bis sie wirklich steht.
##
##   const Spielstart := preload("res://tools/spielstart.gd")
##   var gm := await Spielstart.starten(self)
##   if gm == null:
##       return          # Fehlermeldung hat Spielstart schon geschrieben
##
## Warum nicht Net.start_solo: das geht über den Ladebildschirm, und der lädt die
## Szene in einem Hintergrund-Thread. Bis er umschaltet, ist `current_scene` noch
## der Ladebildschirm. Die Werkzeuge haben darauf bisher mit einer Zählschleife
## über 60 000 Bilder gewartet — headless sind das je nach Last zwischen 20 und
## 200 Sekunden. Lief die Maschine unter Last (zweite Godot-Instanz), reichte das
## nicht: das Werkzeug arbeitete dann mit dem Ladebildschirm weiter und stürzte
## beim ersten `gm.get_node(...)` ab (gemessen an test_minispiel, 25.09.2026) —
## oder filmte stundenlang einen schwarzen Bildschirm (render_trailer).
##
## Hier wird deshalb direkt umgeschaltet, nach echter Zeit gewartet und im
## Fehlerfall ehrlich abgebrochen, statt mit der falschen Szene weiterzumachen.

## So lange wird auf die Spielszene gewartet. Grosszügig, weil eine kalte
## Shader-Übersetzung beim ersten Start lange dauern kann.
const ZEITGRENZE_S := 120.0
## Nach dem Szenenwechsel noch ein paar Bilder laufen lassen, damit _ready aller
## Knoten durch ist — sonst sind Kinder wie das HUD noch nicht da.
const NACHLAUF_BILDER := 30

## Gibt die Spielszene zurück, oder null (dann steht der Grund im Log).
static func starten(knoten: Node, neues_spiel := true, platz := 1) -> Node:
	var baum := knoten.get_tree()
	if baum == null:
		push_error("Spielstart: Knoten hängt nicht im Szenenbaum.")
		return null
	Net.solo = true
	Net.neues_spiel = neues_spiel
	Net.slot = platz
	knoten.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	baum.change_scene_to_file(Net.GAME_SCENE)
	var ende := Time.get_ticks_msec() + int(ZEITGRENZE_S * 1000.0)
	while Time.get_ticks_msec() < ende:
		var szene := baum.current_scene
		if szene != null and szene.has_method("net_book_tent"):
			for i in NACHLAUF_BILDER:
				await baum.process_frame
			return szene
		await baum.process_frame
	push_error("Spielstart: Spielszene kam in %d s nicht hoch." % int(ZEITGRENZE_S))
	print("ABBRUCH: keine Spielszene")
	return null
