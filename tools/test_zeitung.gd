extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Festkurier prüfen: Schlagzeilen für verschiedene Tage, Bild der Zeitung.
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		TranslationServer.set_locale("de")
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var Z := preload("res://scripts/ui/zeitung.gd")
		for b in [{"served": 0}, {"served": 40, "complaints": 7}, {"served": 60, "urin": 6}, {"served": 30, "left": 12},
				{"served": 50, "net": -200}, {"served": 130, "net": 900}, {"served": 60, "pop": 85, "net": 300}, {"served": 45, "net": 200}]:
			print("  ", Z.schlagzeile(b, "Testzelt"))
		gm._zelt_name = "Sepps Festzelt"
		gm._broadcast_meta()
		await _warten(0.3)
		gm.net_report.rpc({"day": 3, "served": 112, "earn": 2450, "net": 900, "pop": 71, "missed": 2, "toilet": false,
			"kellner": true, "gekocht": 38, "rausgeworfen": 3})
		await _warten(4.5)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/zeitung.png")
		print("  Zeitung offen: ", gm.get_node("Zeitung").aktiv)
		get_tree().quit()
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
