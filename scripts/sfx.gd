class_name Sfx
extends Node
## Basit prosedürel ses efektleri (harici dosya yok). Yerelde çalınır.
## Headless sunucuda üretilmez (sadece istemci).

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _idx := 0
var _ok := false

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return  # sunucuda ses üretme
	_streams["pop"] = _tone(760.0, 0.09, "sine", 8.0)
	_streams["ding"] = _tone(1200.0, 0.28, "sine", 4.0)
	_streams["glug"] = _tone(170.0, 0.16, "sine", 6.0)
	_streams["sizzle"] = _tone(0.0, 0.14, "noise", 0.0)
	_streams["scrub"] = _tone(0.0, 0.16, "noise", 0.0)
	_streams["splash"] = _tone(0.0, 0.3, "noise", 0.0)
	_streams["cheer"] = _chord([520.0, 660.0, 790.0], 0.5)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_ok = true

func play(name: String, vol_db := -6.0) -> void:
	if not _ok or not _streams.has(name):
		return
	var p := _players[_idx]
	_idx = (_idx + 1) % _players.size()
	p.stream = _streams[name]
	p.volume_db = vol_db
	p.play()

func _tone(freq: float, dur: float, kind: String, decay: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var env := exp(-t * decay) if decay > 0.0 else (1.0 - t / dur)
		var s := 0.0
		if kind == "noise":
			s = randf() * 2.0 - 1.0
		else:
			s = sin(t * freq * TAU)
		data.encode_s16(i * 2, int(clampf(s * env, -1.0, 1.0) * 30000.0))
	return _wav(data, rate)

func _chord(freqs: Array, dur: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var env := exp(-t * 3.0)
		var s := 0.0
		for f in freqs:
			s += sin(t * float(f) * TAU)
		s /= float(freqs.size())
		data.encode_s16(i * 2, int(clampf(s * env, -1.0, 1.0) * 30000.0))
	return _wav(data, rate)

func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w
