class_name Sfx
extends Node
## Basit prosedürel ses efektleri (harici dosya yok). Yerelde çalınır.
## Headless sunucuda üretilmez (sadece istemci).

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _idx := 0
var _ok := false
var _music_player: AudioStreamPlayer
var _crowd_player: AudioStreamPlayer
var _music_stream: AudioStreamWAV
var _crowd_stream: AudioStreamWAV

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
	_music_stream = _music()
	_crowd_stream = _crowd()
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = _music_stream
	_music_player.volume_db = -16.0
	add_child(_music_player)
	_crowd_player = AudioStreamPlayer.new()
	_crowd_player.stream = _crowd_stream
	_crowd_player.volume_db = -22.0
	add_child(_crowd_player)
	_ok = true

func play_music() -> void:
	if not _ok:
		return
	if not _music_player.playing:
		_music_player.play()
	if not _crowd_player.playing:
		_crowd_player.play()

func stop_music() -> void:
	if not _ok:
		return
	_music_player.stop()
	_crowd_player.stop()

func _music() -> AudioStreamWAV:
	var rate := 22050
	var beat := 0.5
	var n := int(beat * 4.0 * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var bass := [65.41, 98.0, 65.41, 98.0]
	var chord := [261.6, 329.6, 392.0]
	for i in n:
		var t := float(i) / rate
		var b := int(t / beat) % 4
		var bt := fmod(t, beat)
		var s := 0.0
		if b == 0 or b == 2:
			s = sin(t * float(bass[b]) * TAU) * exp(-bt * 7.0) * 0.9
		else:
			var c := 0.0
			for f in chord:
				c += sin(t * float(f) * TAU)
			s = (c / 3.0) * exp(-bt * 9.0) * 0.7
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 22000.0))
	var w := _wav(data, rate)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w

func _crowd() -> AudioStreamWAV:
	var rate := 22050
	var n := int(2.0 * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var prev := 0.0
	for i in n:
		var raw := randf() * 2.0 - 1.0
		prev = lerpf(prev, raw, 0.05)  # basit alçak geçiren -> uğultu
		data.encode_s16(i * 2, int(clampf(prev * 3.0, -1.0, 1.0) * 20000.0))
	var w := _wav(data, rate)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w

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
