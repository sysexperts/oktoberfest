extends Node3D
## Spielbare Schießbude auf der Kirmes. Aufbau: scenes/kirmes/schiessstand_spiel.tscn
## (tools/bake_schiessstand.gd), beliebig oft in die Kirmes stellen.
##
## Ablauf: E → der Server bucht den Preis ab (GameManager.net_schiessen_bezahlen) →
## die Kamera springt an die Theke, Mauszeiger frei → 10 Schuss auf wandernde
## Blechenten und Scheiben → Treffer an den Server → Preis (Rose, Lebkuchenherz,
## Teddy) als Geld. Das Spiel selbst läuft nur beim Spieler, der schießt.

## Preis je Runde (Euro) — der Server liest ihn aus GameManager.SCHIESS_PREIS
@export var schuss := 10
@export var zeit := 30.0
## Wie schnell die Figuren wandern (m/s), untere und obere Reihe
@export var tempo_reihen := Vector2(0.9, -1.3)

var _spieler: Node = null
var _treffer := 0
var _uebrig := 0
var _rest := 0.0
var _ziele: Array[Node3D] = []
var _unten := {}      # Ziel -> Sekunden bis es wieder hochklappt

@onready var _kamera: Camera3D = $Bude/SpielKamera
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _schild: Label3D = $Bude/Schild/Text

const Texte := preload("res://scripts/ui/texte.gd")
const BAHN_HALB := 1.95

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("schiessstand")
	_anzeige.visible = false
	for reihe in [$Bude/Zielbahnen/Reihe0, $Bude/Zielbahnen/Reihe1]:
		for z in reihe.get_children():
			_ziele.append(z as Node3D)
	Einstellungen.geaendert.connect(_beschriften)
	_beschriften()

func _beschriften() -> void:
	_schild.text = Texte.mit_tasten("WORLD_SCHIESSSTAND")

## Für player.gd
func ist_schiessstand() -> bool:
	return true

func laeuft() -> bool:
	return _spieler != null

func interact_point() -> Vector3:
	return global_transform * Vector3(0, 1.0, 1.0)

## Vom GameManager, nachdem bezahlt ist.
func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_treffer = 0
	_uebrig = schuss
	_rest = zeit
	_unten.clear()
	for z in _ziele:
		z.rotation.x = 0.0
	_kamera.current = true
	_anzeige.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_info_neu()

func _process(delta: float) -> void:
	# Figuren wandern immer, auch wenn niemand schießt
	for z in _ziele:
		var reihe := 0 if z.get_parent().name == "Reihe0" else 1
		z.position.x += tempo_reihen[reihe] * delta
		if z.position.x > BAHN_HALB:
			z.position.x -= BAHN_HALB * 2.0
		elif z.position.x < -BAHN_HALB:
			z.position.x += BAHN_HALB * 2.0
	for z in _unten.keys():
		_unten[z] = float(_unten[z]) - delta
		if float(_unten[z]) <= 0.0:
			_unten.erase(z)
			create_tween().tween_property(z, "rotation:x", 0.0, 0.25)
	if _spieler == null:
		return
	_rest -= delta
	_info_neu()
	if _rest <= 0.0 or (_uebrig <= 0 and _unten.is_empty()):
		_beenden()

## Eingaben während des Spiels (player.gd reicht sie weiter).
func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _uebrig > 0:
		_schiessen(mb.position)

func _schiessen(bildpunkt: Vector2) -> void:
	_uebrig -= 1
	var start := _kamera.project_ray_origin(bildpunkt)
	var richtung := _kamera.project_ray_normal(bildpunkt)
	var bester: Node3D = null
	var beste_t := INF
	for z in _ziele:
		if _unten.has(z):
			continue
		var mitte := z.global_transform * Vector3(0, 0.15, 0)
		var zu := mitte - start
		var t := zu.dot(richtung)
		if t <= 0.0:
			continue
		if (start + richtung * t).distance_to(mitte) < 0.17 and t < beste_t:
			beste_t = t
			bester = z
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if bester:
		_treffer += 1
		_unten[bester] = 1.4
		create_tween().tween_property(bester, "rotation:x", -PI / 2.0, 0.12)
		if sfx:
			sfx.play("pop")
	elif sfx:
		sfx.play_oder("schuss", "scrub", -12.0)
	_info_neu()

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("SCHIESS_ANZEIGE")) % [_treffer, _uebrig, maxi(0, ceili(_rest))]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, _treffer)
	_anzeige.visible = false
	_kamera.current = false
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
