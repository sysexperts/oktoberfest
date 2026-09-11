class_name Sfx
extends Node
## Ton. Läuft rein lokal, auf dem Headless-Server wird nichts erzeugt.
##
## Echte Dateien haben Vorrang: liegt unter assets/audio/ eine passende Datei,
## wird die genommen. Fehlt sie, springt die alte prozedurale Erzeugung ein —
## so klingt es nie stumm, aber jede gekaufte Datei ersetzt sofort den Piepston.
## Welche Dateien gebraucht werden, steht in docs/AUDIO.md.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIK_DIR := "res://assets/audio/musik/"
const AMBIENTE := "res://assets/audio/ambiente/kirmes"
const ENDUNGEN := [".ogg", ".wav", ".mp3"]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _idx := 0
var _ok := false
## Zeltmusik kommt als 3D-Quelle aus dem Zelt: drinnen normal laut, draußen
## leiser, je weiter man weggeht. Die Kirmes-Geräusche draußen (Ambiente) sind
## im Zelt gedämpft.
var _music_player: AudioStreamPlayer3D
var _crowd_player: AudioStreamPlayer
const MUSIK_ORT := Vector3(0.0, 3.0, -2.0)
## Grundriss des Zelts (für die Kirmes-Geräusche)
const ZELT_MIN := Vector2(-12.3, -14.3)
const ZELT_MAX := Vector2(12.3, 11.3)
var _musik_db := -6.0
var _musik_tween: Tween
var _music_stream: AudioStream
var _crowd_stream: AudioStream
## Alle gefundenen Musikstücke — es wird zufällig durchgewechselt.
var _playlist: Array[AudioStream] = []

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return  # sunucuda ses üretme
	# Ersatzklänge — werden gleich von echten Dateien überschrieben, wo es welche gibt.
	_streams["pop"] = _tone(760.0, 0.09, "sine", 8.0)
	_streams["ding"] = _tone(1200.0, 0.28, "sine", 4.0)
	_streams["glug"] = _tone(170.0, 0.16, "sine", 6.0)
	_streams["sizzle"] = _tone(0.0, 0.14, "noise", 0.0)
	_streams["scrub"] = _tone(0.0, 0.16, "noise", 0.0)
	_streams["splash"] = _tone(0.0, 0.3, "noise", 0.0)
	_streams["cheer"] = _chord([520.0, 660.0, 790.0], 0.5)
	_streams["honk"] = _honk()
	for name: String in _streams.keys():
		var echt := _lade(SFX_DIR + name)
		if echt != null:
			_streams[name] = echt
	# Namen ohne Ersatzklang: nur nutzbar, wenn eine Datei da ist.
	for name in ["kasse", "zapfen", "prost", "schritte", "tuer", "muenzen", "fahrgeschaeft"]:
		var echt := _lade(SFX_DIR + name)
		if echt != null:
			_streams[name] = echt

	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)

	_playlist = _lade_ordner(MUSIK_DIR)
	_music_stream = _playlist[0] if not _playlist.is_empty() else _music()
	# Stimmengewirr nur mit echter Datei (assets/audio/ambiente/kirmes) — der
	# früher erzeugte Ersatz war gefiltertes Rauschen und klang wie ein lautes
	# Grundrauschen, sobald das Zelt offen war.
	_crowd_stream = _lade(AMBIENTE)

	_music_player = AudioStreamPlayer3D.new()
	_music_player.stream = _music_stream
	_music_player.bus = "Musik"
	# Echte Musik ist schon abgemischt, der Ersatzton nicht.
	_musik_db = -2.0 if not _playlist.is_empty() else -12.0
	_music_player.volume_db = _musik_db
	# Bis ~14 m voll (das ganze Zelt), danach leiser, ab 110 m nicht mehr hörbar
	_music_player.unit_size = 14.0
	_music_player.max_distance = 110.0
	_music_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_music_player.finished.connect(_naechstes_stueck)
	add_child(_music_player)
	_music_player.position = MUSIK_ORT

	_crowd_player = AudioStreamPlayer.new()
	_crowd_player.stream = _crowd_stream
	_crowd_player.bus = "Ambiente"
	_crowd_player.volume_db = -10.0
	add_child(_crowd_player)
	_ok = true

## Lädt <basis>.ogg / .wav / .mp3 — je nachdem, was da ist.
func _lade(basis: String) -> AudioStream:
	for e in ENDUNGEN:
		if ResourceLoader.exists(basis + e):
			return load(basis + e) as AudioStream
	return null

func _lade_ordner(pfad: String) -> Array[AudioStream]:
	var out: Array[AudioStream] = []
	var d := DirAccess.open(pfad)
	if d == null:
		return out
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		# Im Projekt liegt daneben eine .import, im fertigen Export eine .remap —
		# beide Endungen abschneiden, sonst findet der Export die Musik nicht.
		var clean := n.trim_suffix(".import").trim_suffix(".remap")
		# menue.* ist die Menümusik (hauptmenue) — nicht im Zelt spielen
		if clean.get_extension().to_lower() in ["ogg", "wav", "mp3"] and clean.get_basename() != "menue":
			var s := load(pfad + clean) as AudioStream
			if s != null and not out.has(s):
				out.append(s)
		n = d.get_next()
	d.list_dir_end()
	out.shuffle()
	return out

## Nach jedem Stück das nächste — nur wenn es mehrere gibt.
func _naechstes_stueck() -> void:
	if _playlist.size() < 2:
		if _music_player.stream != null:
			_music_player.play()
		return
	var jetzt := _music_player.stream
	var neu := jetzt
	while neu == jetzt:
		neu = _playlist[randi() % _playlist.size()]
	_music_player.stream = neu
	_music_player.play()

func play_music() -> void:
	if not _ok:
		return
	if _musik_tween:
		_musik_tween.kill()
		_musik_tween = null
	_music_player.volume_db = _musik_db
	if not _music_player.playing:
		_music_player.play()
	if _crowd_stream != null and not _crowd_player.playing:
		_crowd_player.play()

func stop_music() -> void:
	if not _ok:
		return
	_music_player.stop()
	_crowd_player.stop()

## Feierabend: Musik in dauer Sekunden leiser werden lassen, dann aus.
func musik_ausblenden(dauer: float) -> void:
	if not _ok or not _music_player.playing or _musik_tween != null:
		return
	_musik_tween = create_tween()
	_musik_tween.tween_property(_music_player, "volume_db", -45.0, dauer)
	_musik_tween.tween_callback(func() -> void:
		_music_player.stop()
		_music_player.volume_db = _musik_db
		_musik_tween = null)

## Kirmes-Geräusche: draußen voll, im Zelt gedämpft.
func _process(delta: float) -> void:
	if not _ok or _crowd_stream == null:
		return
	var kamera := get_viewport().get_camera_3d()
	if kamera == null:
		return
	var p := kamera.global_position
	var im_zelt := p.x > ZELT_MIN.x and p.x < ZELT_MAX.x and p.z > ZELT_MIN.y and p.z < ZELT_MAX.y
	var ziel := -22.0 if im_zelt else -6.0
	_crowd_player.volume_db = lerpf(_crowd_player.volume_db, ziel, clampf(delta * 2.0, 0.0, 1.0))

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

## Klang abspielen — gibt es dafür (noch) keine Datei, den Ersatzklang.
func play_oder(name: String, ersatz: String, vol_db := -6.0) -> void:
	play(name if _streams.has(name) else ersatz, vol_db)

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

## Lieferwagen-Hupe: zwei kurze Töne — "düt düt".
func _honk() -> AudioStreamWAV:
	var rate := 22050
	var beep := 0.16      # Länge eines Tons
	var gap := 0.10       # Pause dazwischen
	var total := beep * 2.0 + gap
	var n := int(total * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var local := -1.0
		if t < beep:
			local = t
		elif t >= beep + gap:
			local = t - beep - gap
		var s := 0.0
		if local >= 0.0:
			# leicht rauer Klang: Grundton + Quinte, weiche Hüllkurve
			var env: float = clampf(local / 0.02, 0.0, 1.0) * clampf((beep - local) / 0.04, 0.0, 1.0)
			s = (sin(local * 420.0 * TAU) * 0.6 + sin(local * 630.0 * TAU) * 0.4) * env
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 26000.0))
	return _wav(data, rate)

func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w
