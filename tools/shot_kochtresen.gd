extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Bilder vom Kochtresen mit Würstchen in allen Zuständen und dem Mülleimer:
##   SHOT_DIR=build godot --path . res://tools/shot_kochtresen.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var st: Node = gm.get_node("Stations")
		var wurst: FoodStation = st.get_node("FoodSosis")
		var brezn: FoodStation = st.get_node("FoodPretzel")
		var hendl: FoodStation = st.get_node("FoodHendl")
		for f: FoodStation in [wurst, brezn, hendl]:
			f.set_process(false)
			f.visible = true
		_stand(wurst, [[FoodStation.BRAET, 2.0], [FoodStation.BRAET, 6.5], [FoodStation.FERTIG, 3.0], [FoodStation.VERBRANNT, 0.0]])
		_stand(brezn, [[FoodStation.FERTIG, 12.0], [FoodStation.BRAET, 4.0], [FoodStation.VERBRANNT, 0.0]])
		_stand(hendl, [[FoodStation.BRAET, 5.0], [FoodStation.VERBRANNT, 0.0], [FoodStation.FERTIG, 4.0]])
		print("STATION ", wurst.global_position, " vis=", wurst.is_visible_in_tree(), " slots=", wurst._slots.size(), " slot0vis=", wurst._slots[0].visible, " z=", wurst._zustand)
		var sp := gm._players_nodes.get(1) as Node3D
		sp.global_position = Vector3(7.0, 0.1, -10.0)
		sp.set("carry_state", 4)
		sp.set("carry_type", 2)
		sp.set("carry_fill", 1.0)
		var k := Camera3D.new()
		gm.add_child(k)
		k.current = true
		var dir := OS.get_environment("SHOT_DIR")
		k.look_at_from_position(Vector3(4.9, 2.2, -10.0), Vector3(4.9, 1.3, -13.2))
		await _warten(2.0)
		Schuss.speichern(get_viewport(), dir + "/koch_uebersicht.png")
		k.look_at_from_position(Vector3(4.65, 1.9, -11.8), Vector3(4.65, 1.0, -13.2))
		await _warten(0.6)
		Schuss.speichern(get_viewport(), dir + "/koch_wurst.png")
		k.look_at_from_position(Vector3(7.5, 1.9, -11.8), Vector3(7.5, 1.0, -13.2))
		await _warten(0.6)
		Schuss.speichern(get_viewport(), dir + "/koch_zweite.png")
		get_tree().quit()
	func _stand(f: FoodStation, liste: Array) -> void:
		for i in liste.size():
			f._setze(i, int(liste[i][0]))
			f._zeit[i] = float(liste[i][1]) if int(liste[i][0]) != FoodStation.VERBRANNT else FoodStation.BRENN_ZEIT
			f._anzeigen(i)
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
