extends RefCounted
## Brabbelton fürs Dialogfenster (scripts/ui/dialog.gd): kurze weiche Silben statt Sprachausgabe, die zum
## Tippen des Textes laufen. Jede Figur hat ihre eigene Stimmlage (aus dem Namen), kleine Schwankungen je Silbe.
## Die Silben werden im Code erzeugt und gemerkt; Einbinden per preload, ohne class_name.

const RATE := 22050
const SCHWANKUNG := [0.92, 1.0, 1.1, 0.96, 1.16, 1.04]
## feste Lagen für die Hauptfiguren (Hz), alle anderen Namen bekommen eine aus dem Namen
const LAGEN := {"Horst": 105.0, "Konrad": 128.0, "Gustav": 88.0, "Croupier": 150.0, "Frau Wagner": 215.0, "Gerhard": 96.0}

static var _cache := {}

## Grundtonhöhe einer Figur, 85 bis 260 Hz
static func lage(sprecher: String) -> float:
	for name: String in LAGEN:
		if sprecher.begins_with(name):
			return float(LAGEN[name])
	return 85.0 + float(absi(hash(sprecher)) % 175)

## Die nr-te Silbe der Figur (wechselt reihum durch die Schwankungen)
static func silbe(sprecher: String, nr: int) -> AudioStreamWAV:
	var schluessel := "%s|%d" % [sprecher, nr % SCHWANKUNG.size()]
	if not _cache.has(schluessel):
		_cache[schluessel] = _erzeuge(lage(sprecher) * float(SCHWANKUNG[nr % SCHWANKUNG.size()]))
	return _cache[schluessel]

static func _erzeuge(hz: float) -> AudioStreamWAV:
	var dauer := 0.075
	var n := int(RATE * dauer)
	var daten := PackedByteArray()
	daten.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		# Tonhöhe hebt sich zum Ende der Silbe leicht, wie ein „a“ oder „o“ im Sprechen
		phase += TAU * hz * (1.0 + 0.12 * t) / float(RATE)
		var huelle := minf(1.0, t * 12.0) * pow(1.0 - t, 1.6)
		# Grundton plus zwei Obertöne (Stimmklang), dazu eine Spur Rauschen
		var s := sin(phase) * 0.6 + sin(phase * 2.0) * 0.25 + sin(phase * 3.0) * 0.12 + randf_range(-0.02, 0.02)
		daten.encode_s16(i * 2, clampi(int(s * huelle * 20000.0), -32768, 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = daten
	return w
