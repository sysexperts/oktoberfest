extends Node3D
## Interaktive Animationsvorschau: die vier Grundfiguren nebeneinander, dieselbe
## Rolle gleichzeitig. Starten mit F6 im Editor oder
## godot --path . res://tools/anim_vorschau.tscn
##
## 1 stehen · 2 gehen · 3 rennen · 4 sitzen · 5 tanzen · 6 torkeln · 7 extra
## A/D drehen · Leertaste Pause · Pfeil hoch/runter Tempo

const ROLLEN := ["stehen", "gehen", "rennen", "sitzen", "tanzen", "torkeln", "extra"]

@onready var _figuren: Array[Figur] = [$Standard, $Wilhelm, $Lisa, $Alex]
@onready var _anzeige: Label = $Oberflaeche/Anzeige

var _rolle := "stehen"
var _tempo := 1.0
var _pause := false

## Welche Figurszene zu welcher Spalte gehört (Varianten erben die Werte)
const SZENEN := ["bean", "charakter2", "charakter3", "alex"]
const FELDER := {
	"Ruecken": "aufrichten_ruecken", "Nacken": "aufrichten_nacken",
	"Kopf": "aufrichten_kopf", "Huefte": "aufrichten_huefte", "Beine": "aufrichten_beine",
	"Arme": "arme_abspreizen", "ArmeSitzen": "arme_sitzen",
	"Gehen": "aufrichten_gehen",
}

func _ready() -> void:
	for i in _figuren.size():
		for fn: String in FELDER:
			var zeile := get_node("Oberflaeche/Regler/Spalte%d/%sZeile" % [i, fn])
			var regler: HSlider = zeile.get_node("Regler")
			regler.value = _figuren[i].get(FELDER[fn])
			_wert_zeigen(zeile, regler.value)
			regler.value_changed.connect(_regler_geaendert.bind(i, fn, zeile))
	$Oberflaeche/Speichern.pressed.connect(_speichern)
	await get_tree().process_frame
	_abspielen()

func _wert_zeigen(zeile: Node, v: float) -> void:
	(zeile.get_node("Wert") as Label).text = "%.2f" % v

func _regler_geaendert(v: float, i: int, fn: String, zeile: Node) -> void:
	_figuren[i].set(FELDER[fn], v)
	_wert_zeigen(zeile, v)
	# Stehen/Gehen neu anwenden, damit der Modifier die Werte übernimmt
	_abspielen()

## Werte in die Figurszenen schreiben (Wurzelknoten, direkt nach der Skriptzeile)
func _speichern() -> void:
	for i in _figuren.size():
		var pfad := "res://scenes/figuren/%s.tscn" % SZENEN[i]
		var zeilen := FileAccess.get_file_as_string(pfad).split("
")
		var neu: PackedStringArray = []
		for z in zeilen:
			if z.begins_with("aufrichten_"):
				continue
			neu.append(z)
			if z.begins_with("script = ExtResource"):
				for fn: String in FELDER:
					neu.append("%s = %s" % [FELDER[fn], _zahl(_figuren[i].get(FELDER[fn]))])
		var f := FileAccess.open(pfad, FileAccess.WRITE)
		f.store_string("
".join(neu))
		f.close()
	_anzeige.text = "Gespeichert in scenes/figuren/ — im Editor ggf. neu laden"

func _zahl(v: float) -> String:
	return str(snappedf(v, 0.01))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_7:
			_rolle = ROLLEN[k - KEY_1]
			_abspielen()
		elif k == KEY_SPACE:
			_pause = not _pause
			_tempo_setzen()
		elif k == KEY_UP:
			_tempo = minf(_tempo + 0.25, 3.0)
			_tempo_setzen()
		elif k == KEY_DOWN:
			_tempo = maxf(_tempo - 0.25, 0.25)
			_tempo_setzen()

func _process(delta: float) -> void:
	var dreh := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A):
		dreh = -1.0
	elif Input.is_key_pressed(KEY_D):
		dreh = 1.0
	if dreh != 0.0:
		for f in _figuren:
			f.rotation.y += dreh * delta * 2.0

func _abspielen() -> void:
	for f in _figuren:
		f.pose_loesen()
		match _rolle:
			"stehen": f.stehen()
			"gehen": f.gehen()
			"rennen": f.rennen()
			"sitzen":
				if f.kann_sitzen():
					f.sitzen()
				else:
					f.sitz_pose()
			"tanzen": f.tanzen()
			"torkeln": f.torkeln()
			"extra":
				if not f.extra():
					f.stehen()
		# Alle im Gleichschritt, damit man die Figuren vergleichen kann
		if f.anim and f.anim.current_animation != "":
			f.anim.seek(0.0, true)
	_tempo_setzen()

func _tempo_setzen() -> void:
	for f in _figuren:
		if f.anim:
			f.anim.speed_scale = 0.0 if _pause else _tempo
	_anzeige.text = "%s   ·   Tempo %.2f%s\n1 stehen  2 gehen  3 rennen  4 sitzen  5 tanzen  6 torkeln  7 extra\nA/D drehen  ·  Leertaste Pause  ·  Pfeil hoch/runter Tempo" % [
		_rolle.to_upper(), _tempo, "  ·  PAUSE" if _pause else ""]
