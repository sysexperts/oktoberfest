extends Node
## Prueft, dass die UI-Klaenge geladen sind, wirklich abgespielt werden und die
## Menuemusik im Hauptmenue laeuft. Hoeren kann man beim Test nichts — also
## wird geprueft, ob die Spieler tatsaechlich auf "spielt" gehen.
func _ready() -> void:
	var fehlen := []
	for name in ["ui_hover", "ui_klick", "ui_wechsel", "ui_zurueck", "ui_schalter"]:
		if not ResourceLoader.exists("res://assets/audio/sfx/%s.wav" % name):
			fehlen.append(name)
	print("fehlende Klangdateien: %s" % ("keine" if fehlen.is_empty() else str(fehlen)))
	Klang.klick()
	await get_tree().process_frame
	var laeuft := 0
	for p in Klang.get_children():
		if p is AudioStreamPlayer and p.playing:
			laeuft += 1
	print("Klang.klick() -> %d Spieler aktiv, Bus=%s" % [laeuft, (Klang.get_child(0) as AudioStreamPlayer).bus])

	var menue: Control = load("res://scenes/ui/hauptmenue.tscn").instantiate()
	add_child(menue)
	await _warte(1.0)
	var musik: AudioStreamPlayer = menue.get_node("MenueMusik")
	var titel := musik.stream.resource_path if musik.stream != null else "<keine>"
	print("Menuemusik: %s  spielt=%s" % [titel, musik.playing])
	var kat := menue.get_node("Mitte/Hauptspalte/Weiterspielen") as Button
	print("Knopf hat Klang verbunden: %s" % kat.has_meta("klang"))
	get_tree().quit()

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
