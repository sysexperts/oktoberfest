@tool
extends Node3D
## Sitzhaltung von Lisa auf der Bank einstellen. Regler im Inspektor bei
## „Sitzen"; gespeichert sofort in assets/sitz_lisa.tres. Die Figur sitzt mit
## der echten Sitzanimation — die Regler kommen obendrauf.
## Werte werden nicht in dieser Szene gespeichert (sonst überschriebe das Öffnen sie).

const HALTUNG := preload("res://assets/sitz_lisa.tres")
const REGLER := ["oberschenkel_vor", "beine_zusammen", "unterschenkel", "oberkoerper", "hoehe"]

@export_group("Sitzen")
@export_range(-2.0, 2.0, 0.01) var oberschenkel_vor := 0.0:
	get: return HALTUNG.oberschenkel_vor
	set(w): _setzen("oberschenkel_vor", w)
@export_range(-1.0, 1.0, 0.01) var beine_zusammen := 0.0:
	get: return HALTUNG.beine_zusammen
	set(w): _setzen("beine_zusammen", w)
@export_range(-2.0, 2.0, 0.01) var unterschenkel := 0.0:
	get: return HALTUNG.unterschenkel
	set(w): _setzen("unterschenkel", w)
@export_range(-1.0, 1.0, 0.01) var oberkoerper := 0.0:
	get: return HALTUNG.oberkoerper
	set(w): _setzen("oberkoerper", w)
@export_range(-0.4, 0.4, 0.005) var hoehe := 0.0:
	get: return HALTUNG.hoehe
	set(w):
		_setzen("hoehe", w)
		var lisa := get_node_or_null("Sitzplatz/Lisa") as Node3D
		if lisa and is_node_ready():
			lisa.position.y = GRUND_HOEHE + w

var _speichern_in := -1.0

func _validate_property(p: Dictionary) -> void:
	if p.name in REGLER:
		p.usage &= ~PROPERTY_USAGE_STORAGE

func _setzen(name: String, wert: float) -> void:
	if not is_node_ready():
		return
	var h: SitzHaltung = HALTUNG
	h.set(name, wert)
	_speichern_in = 0.4

## figur.gd läuft im Editor nicht (kein @tool) — darum hier von Hand: Sitzanimation
## aus character2 ausleihen, abspielen und die Korrektur ans Skelett hängen.
const LEIH := preload("res://assets/character/character2/character2.glb")
const SITZ_ANIM := "geliehen/Sit_and_Drink"
const GRUND_HOEHE := 0.03   # sitz_hoehe aus charakter3.tscn

func _ready() -> void:
	var lisa := $Sitzplatz/Lisa as Node3D
	var aps := lisa.find_children("*", "AnimationPlayer", true, false)
	var sks := lisa.find_children("*", "Skeleton3D", true, false)
	if aps.is_empty() or sks.is_empty():
		return
	var ap := aps[0] as AnimationPlayer
	if not ap.has_animation_library("geliehen"):
		var quelle := LEIH.instantiate()
		var qa := quelle.find_children("*", "AnimationPlayer", true, false)
		if not qa.is_empty():
			ap.add_animation_library("geliehen", (qa[0] as AnimationPlayer).get_animation_library(""))
		quelle.free()
	if ap.has_animation(SITZ_ANIM):
		ap.get_animation(SITZ_ANIM).loop_mode = Animation.LOOP_LINEAR
		ap.play(SITZ_ANIM)
	lisa.position.y = GRUND_HOEHE + (HALTUNG as SitzHaltung).hoehe
	var sk := sks[0] as Node
	if sk.get_node_or_null("SitzKorrektur") == null:
		var m := SitzKorrektur.new()
		m.name = "SitzKorrektur"
		m.haltung = HALTUNG
		sk.add_child(m)   # ohne owner: wird nicht gespeichert

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	# Höhe: Lisa einfach mit dem Verschiebe-Werkzeug (W) hoch/runter ziehen
	var lisa := get_node_or_null("Sitzplatz/Lisa") as Node3D
	var h: SitzHaltung = HALTUNG
	if lisa and not is_equal_approx(lisa.position.y - GRUND_HOEHE, h.hoehe):
		h.hoehe = lisa.position.y - GRUND_HOEHE
		_speichern_in = 0.4
	if _speichern_in > 0.0:
		_speichern_in -= delta
		if _speichern_in <= 0.0:
			ResourceSaver.save(HALTUNG, HALTUNG.resource_path)
