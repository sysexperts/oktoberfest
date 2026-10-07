extends Node
const Brabbel := preload("res://scripts/ui/brabbel.gd")
## Zeichnet die Brabbel-Silben mehrerer Figuren als Schwingungsbild (build/brabbel.png) und prüft sie.
##   godot --headless --path . res://tools/render_brabbel.tscn

func _ready() -> void:
	var namen := ["Horst", "Konrad", "Gustav", "Frau Wagner", "Croupier"]
	var bild := Image.create(1200, 60 + namen.size() * 120, false, Image.FORMAT_RGB8)
	bild.fill(Color(0.1, 0.1, 0.14))
	var fehler := 0
	for z in namen.size():
		var mitte := 60 + z * 120 + 30
		var x0 := 20
		for nr in 6:
			var s: AudioStreamWAV = Brabbel.silbe(namen[z], nr)
			var n := s.data.size() / 2
			for i in n:
				var v := float(s.data.decode_s16(i * 2)) / 32768.0
				var x := x0 + int(float(i) / float(n) * 170.0)
				var y := mitte + int(-v * 45.0)
				if x < 1200 and y >= 0 and y < bild.get_height():
					bild.set_pixel(x, y, Color(1.0, 0.8, 0.3))
			x0 += 190
		var hz := Brabbel.lage(namen[z])
		print("  %s: Grundton %.0f Hz" % [namen[z], hz])
		if hz < 80.0 or hz > 280.0:
			fehler += 1
	if Brabbel.silbe("Horst", 1).data.size() < 1000:
		fehler += 1
	print("  Horst tiefer als Frau Wagner: ", Brabbel.lage("Horst") < Brabbel.lage("Frau Wagner"))
	bild.save_png("res://build/brabbel.png")
	print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
	get_tree().quit()
