extends RefCounted
## Geräusche für die Prügelei: Faustschlag, K.o., Aufprall beim Rauswurf.
## Liegt eine Datei unter assets/audio/sfx/pruegel/<art>.ogg (oder .wav), wird
## die benutzt. Sonst ein im Code erzeugter dumpfer Schlag als Platzhalter —
## tiefer Ton mit schnellem Abklingen plus kurzes Knacken.
## Einbinden per preload, ohne class_name.

const RATE := 22050
const ORDNER := "res://assets/audio/sfx/pruegel/"
## art -> [Dauer s, Grundton Hz, Abklingen, Knack-Anteil]
const ARTEN := {
	"schlag": [0.16, 120.0, 30.0, 0.7],
	"ko": [0.35, 80.0, 12.0, 0.5],
	"aufprall": [0.5, 55.0, 8.0, 0.9],
}

static var _cache := {}

static func hol(art: String) -> AudioStream:
	for endung in [".ogg", ".wav", ".mp3"]:
		var datei: String = ORDNER + art + endung
		if ResourceLoader.exists(datei):
			return load(datei)
	if not _cache.has(art):
		_cache[art] = _erzeuge(art)
	return _cache[art]

static func _erzeuge(art: String) -> AudioStreamWAV:
	var d: Array = ARTEN.get(art, ARTEN["schlag"])
	var n := int(RATE * float(d[0]))
	var daten := PackedByteArray()
	daten.resize(n * 2)
	var phase := 0.0
	var tief := 0.0
	for i in n:
		var t := float(i) / RATE
		var huelle := exp(-t * float(d[2]))
		# Ton fällt beim Abklingen etwas ab — klingt wuchtiger
		phase += TAU * float(d[1]) * (1.0 - minf(0.5, t * 1.5)) / RATE
		var knack := exp(-t * 160.0) * randf_range(-1.0, 1.0) * float(d[3])
		# Tiefpass für das Rauschen im Nachklang
		tief = lerpf(tief, randf_range(-1.0, 1.0), 0.08)
		var s := sin(phase) * 0.85 * huelle + knack + tief * 0.35 * huelle
		daten.encode_s16(i * 2, clampi(int(s * 26000.0), -32768, 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = daten
	return w
