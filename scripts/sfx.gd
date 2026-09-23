class_name Sfx
extends Node
## Ton. Läuft rein lokal, auf dem Headless-Server wird nichts erzeugt.
##
## Echte Dateien haben Vorrang: liegt unter assets/audio/ eine passende Datei,
## wird die genommen. Fehlt sie, springt die alte prozedurale Erzeugung ein —
## so klingt es nie stumm, aber jede gekaufte Datei ersetzt sofort den Piepston.
## Welche Dateien gebraucht werden, steht in docs/AUDIO.md.

const SFX_DIR := "res://assets/audio/sfx/"
## Die Stücke liegen in assets/music (mit Suno Pro erzeugt, kommerziell nutzbar).
## Der Dateiname entscheidet, wann ein Stück läuft:
##   Gamesound.*            Hauptmusik des Spiels, läuft im Hauptmenü (menu.gd)
##   Voice_Last_Concert_*   Schlussnummer, wenn ein Künstler gebucht ist
##   Voice_*                mit Gesang — nur mit gebuchtem Künstler auf der Bühne
##   alles andere           Instrumentals, die normale Zeltmusik
const MUSIK_DIR := "res://assets/music/"
const HAUPTSTUECK := "Gamesound"
const KENNUNG_GESANG := "Voice_"
const KENNUNG_FINALE := "Voice_Last_Concert"
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
## Zeltmusik ohne Künstler — reine Instrumentals
var _instrumental: Array[AudioStream] = []
## Zeltmusik mit gebuchtem Künstler — der Sänger auf der Bühne singt dazu
var _gesang: Array[AudioStream] = []
## Schlussnummer des Auftritts; wird so gelegt, dass sie vor 22:00 durch ist
var _finale: AudioStream
## Stufe des gebuchten Künstlers (0 = keiner)
var _kuenstler := 0
var _finale_laeuft := false
var _finale_gespielt := false
## Nach der Schlussnummer bis zum Feierabend still bleiben
var _stille_bis_feierabend := false
## Verbleibende echte Sekunden bis Feierabend, vom GameManager gemeldet
var _restzeit := INF

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
	for name in ["kasse", "zapfen", "prost", "schritte", "tuer", "muenzen", "fahrgeschaeft", "krug_voll"]:
		var echt := _lade(SFX_DIR + name)
		if echt != null:
			_streams[name] = echt

	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)

	_musik_einlesen()
	_music_stream = _instrumental[0] if not _instrumental.is_empty() else _music()
	# Stimmengewirr nur mit echter Datei (assets/audio/ambiente/kirmes) — der
	# früher erzeugte Ersatz war gefiltertes Rauschen und klang wie ein lautes
	# Grundrauschen, sobald das Zelt offen war.
	_crowd_stream = _lade(AMBIENTE)

	_music_player = AudioStreamPlayer3D.new()
	_music_player.stream = _music_stream
	_music_player.bus = "Musik"
	# Echte Musik ist schon abgemischt, der Ersatzton nicht.
	_musik_db = -2.0 if not _instrumental.is_empty() else -12.0
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

## Stücke aus MUSIK_DIR auf die drei Listen verteilen — nach dem Dateinamen,
## siehe Kommentar bei MUSIK_DIR.
func _musik_einlesen() -> void:
	var d := DirAccess.open(MUSIK_DIR)
	if d == null:
		push_warning("[Sfx] %s nicht lesbar — keine Musik" % MUSIK_DIR)
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		# Im Projekt liegt daneben eine .import, im fertigen Export eine .remap —
		# beide Endungen abschneiden, sonst findet der Export die Musik nicht.
		var clean := n.trim_suffix(".import").trim_suffix(".remap")
		if clean.get_extension().to_lower() in ["ogg", "wav", "mp3"]:
			var s := load(MUSIK_DIR + clean) as AudioStream
			var basis := clean.get_basename()
			if s == null or basis == HAUPTSTUECK:
				pass                                   # Hauptmusik läuft nur im Menü
			elif basis.begins_with(KENNUNG_FINALE):
				_finale = s
			elif basis.begins_with(KENNUNG_GESANG):
				if not _gesang.has(s):
					_gesang.append(s)
			elif not _instrumental.has(s):
				_instrumental.append(s)
		n = d.get_next()
	d.list_dir_end()
	_instrumental.shuffle()
	_gesang.shuffle()

## Welche Liste gerade dran ist: mit Künstler auf der Bühne der Gesang, sonst
## die Instrumentals. Ist eine Liste leer, bleibt es bei der anderen.
func _aktuelle_liste() -> Array[AudioStream]:
	if _kuenstler > 0 and not _gesang.is_empty():
		return _gesang
	if _instrumental.is_empty():
		return _gesang
	return _instrumental

## Nach jedem Stück das nächste.
func _naechstes_stueck() -> void:
	if _finale_laeuft:
		# Nach der Schlussnummer nichts mehr — gleich ist ohnehin Feierabend.
		# Ohne diese Sperre würde play_music() sie beim nächsten Abgleich vom
		# Server sofort wieder von vorn anwerfen.
		_finale_laeuft = false
		_stille_bis_feierabend = true
		return
	if _finale_faellig():
		_finale_starten()
		return
	var liste := _aktuelle_liste()
	if liste.is_empty():
		if _music_player.stream != null:
			_music_player.play()
		return
	var jetzt := _music_player.stream
	var neu: AudioStream = liste[randi() % liste.size()]
	if liste.size() > 1:
		while neu == jetzt:
			neu = liste[randi() % liste.size()]
	_music_player.stream = neu
	_music_player.play()

## Muss die Schlussnummer jetzt anfangen, damit sie vor Feierabend durch ist?
func _finale_faellig() -> bool:
	return _kuenstler > 0 and _finale != null and not _finale_gespielt \
		and _restzeit <= _finale.get_length()

func _finale_starten() -> void:
	_finale_gespielt = true
	_finale_laeuft = true
	_music_player.stream = _finale
	_music_player.volume_db = _musik_db
	_music_player.play()

## Gebuchter Künstler (0 = keiner). Wechselt die Liste; das laufende Stück darf
## zu Ende spielen, damit der Wechsel nicht mitten im Takt abschneidet.
func kuenstler(stufe: int) -> void:
	if _kuenstler == stufe:
		return
	_kuenstler = stufe
	if stufe == 0:
		_finale_gespielt = false
		_finale_laeuft = false
		_stille_bis_feierabend = false

## Verbleibende echte Sekunden bis 22:00, vom GameManager. Danach entscheidet
## sich, wann die Schlussnummer anfangen muss.
func restzeit(sekunden: float) -> void:
	_restzeit = sekunden
	if not _ok or not _music_player.playing or _finale_laeuft:
		return
	if _finale_faellig():
		# Das laufende Stück würde über 22:00 hinauslaufen — kurz ausblenden und
		# die Schlussnummer anfangen, damit sie vor Feierabend durch ist.
		var tw := create_tween()
		tw.tween_property(_music_player, "volume_db", -40.0, 1.0)
		tw.tween_callback(_finale_starten)

func play_music() -> void:
	if not _ok:
		return
	if _musik_tween:
		_musik_tween.kill()
		_musik_tween = null
	_music_player.volume_db = _musik_db
	if not _music_player.playing and not _stille_bis_feierabend:
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
