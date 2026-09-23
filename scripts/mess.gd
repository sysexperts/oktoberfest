class_name Mess
extends Node3D
## Yerdeki kir. Oyuncu E ile temizler. Host otoriter; id ile senkron.
## kind: 0 = Erbrochenes, 1 = Urin (E6), ab 2 = Dreck im verlassenen Zelt
## (Tutorial „Putze das Zelt") — 2 + Nummer des Modells unter „Dreck".

const DRECK := 2
## Welche Dreckmodelle Gäste hinterlassen: Laub, Scherben, Papier, Staub.
## Das Stroh (Nummer 3) ist raus — die gelben Halme sahen wie Pommes aus, und
## Pommes verkaufen wir nicht.
const DRECK_ARTEN := [0, 1, 2, 4]
## Ab hier: Abdeckplanen über Möbeln (abziehen statt fegen). Größe je Art.
const DECKE := 10
## Ab hier: Sabotage von Huber — auslaufendes Fass (Bierlache, kostet Bier bis sie weg ist)
const SABOTAGE := 20
## Etwas Luft um die Plane herum: das Möbel darunter steht nicht immer mittig
const DECKEN_RAND := 0.4
const DECKEN_GROESSE := {
	10: Vector3(9.0, 1.15, 1.9), 11: Vector3(9.0, 1.15, 1.9), 12: Vector3(5.6, 1.1, 1.4),
	13: Vector3(4.5, 1.05, 8.2), 14: Vector3(3.6, 1.9, 3.6),
}

## Liegt Dreck oder eine Plane so lange herum, taucht ein Pfeil darüber auf und
## weist den Weg. Nur für Planen und Bodendreck — Bierlachen und Erbrochenes
## während der Schicht sollen das Bild nicht zupflastern. Und immer nur über
## dem nächstgelegenen Stück, sonst steht ein ganzer Pfeilwald im Zelt.
const MAHN_ZEIT := 30.0
## So oft wird geprüft, wer gerade der nächste ist
const PRUEF_TAKT := 0.4
## Schwebehöhe des Pfeils über Dreck bzw. über einer Plane
const PFEIL_H := {"dreck": 1.0, "plane": 1.75}

var mess_id := -1
var kind := 0
var _liegt := 0.0
var _pruef := 0.0

@onready var _disc: MeshInstance3D = $Disc
@onready var _dreck: Node3D = $Dreck
@onready var _label: Label3D = $Label
@onready var _plane: MeshInstance3D = $Plane
@onready var _pfeil: Label3D = $Pfeil

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("mess")
	_apply_kind()

func _process(delta: float) -> void:
	_liegt += delta
	_pruef -= delta
	if _pruef <= 0.0:
		_pruef = PRUEF_TAKT
		_pfeil.visible = _ist_wegweiser()
	if _pfeil.visible:
		# Sachtes Auf und Ab, damit er auffällt, ohne zu blinken
		_pfeil.position.y = _pfeil_hoehe() + sin(_liegt * 2.2) * 0.1

## Nur das nächstgelegene liegengebliebene Stück weist den Weg.
func _ist_wegweiser() -> bool:
	if _liegt < MAHN_ZEIT:
		return false
	var sp := _spieler()
	if sp == null:
		return false
	var meine := global_position.distance_squared_to(sp.global_position)
	for n in get_tree().get_nodes_in_group("mess"):
		var m := n as Mess
		if m == null or m == self or m._liegt < MAHN_ZEIT:
			continue
		if not (m.ist_plane() or m.ist_dreck()):
			continue
		if m.global_position.distance_squared_to(sp.global_position) < meine:
			return false
	return true

func _spieler() -> Node3D:
	var welt := get_tree().current_scene
	if welt == null:
		return null
	var leute := welt.get_node_or_null("Players")
	if leute == null:
		return null
	return leute.get_node_or_null(str(multiplayer.get_unique_id())) as Node3D

func _pfeil_hoehe() -> float:
	return PFEIL_H["plane"] if ist_plane() else PFEIL_H["dreck"]

func set_kind(k: int) -> void:
	kind = k
	if is_inside_tree():
		_apply_kind()

func ist_sabotage() -> bool:
	return kind >= SABOTAGE

func ist_plane() -> bool:
	return kind >= DECKE and kind < SABOTAGE

func ist_dreck() -> bool:
	return kind >= DRECK and kind < SABOTAGE

## Wie weit die Plane vom Mittelpunkt aus reicht, in ihrem eigenen Raum.
func _decken_halb() -> Vector3:
	var g: Vector3 = DECKEN_GROESSE.get(kind, Vector3.ONE)
	return Vector3(g.x * 0.5, g.y, g.z * 0.5)

## Stelle der Plane, die diesem Ort am nächsten liegt. Ohne das wäre eine 9 m
## lange Plane nur in ihrer Mitte in Reichweite und man käme an den Enden nicht
## an sie heran (Feedback Tutorial).
func naechster_punkt(von: Vector3) -> Vector3:
	if not ist_plane():
		return global_position
	var h := _decken_halb()
	var lokal := to_local(von)
	lokal.x = clampf(lokal.x, -h.x, h.x)
	lokal.y = 0.0
	lokal.z = clampf(lokal.z, -h.z, h.z)
	return to_global(lokal)

## Steht an dieser Stelle etwas unter der Plane? Solange sie daliegt, gehört der
## Griff ihr und nicht dem Regal darunter.
func deckt(punkt: Vector3) -> bool:
	if not ist_plane():
		return false
	var h := _decken_halb()
	var lokal := to_local(punkt)
	return absf(lokal.x) <= h.x + DECKEN_RAND and absf(lokal.z) <= h.z + DECKEN_RAND 		and lokal.y > -1.0 and lokal.y < h.y + 1.0

func _apply_kind() -> void:
	if _disc == null:
		return
	# Nur Planen und Bodendreck bekommen den Wegweiser
	set_process(ist_plane() or ist_dreck())
	if not (ist_plane() or ist_dreck()):
		_pfeil.visible = false
	_pfeil.position.y = _pfeil_hoehe()
	if ist_sabotage():
		var bier := (_disc.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		bier.albedo_color = Color(0.85, 0.58, 0.12, 0.92)
		_disc.material_override = bier
		_disc.scale = Vector3(1.9, 1.0, 1.9)
		_label.set("schluessel", "WORLD_LECK")
		if _label.has_method("aktualisieren"):
			_label.aktualisieren()
		return
	if ist_plane():
		_disc.visible = false
		_label.visible = false
		_plane.visible = true
		_plane.scale = DECKEN_GROESSE.get(kind, Vector3.ONE)
		return
	if ist_dreck():
		_disc.visible = false
		_dreck.visible = true
		var modelle := _dreck.get_children()
		for i in modelle.size():
			(modelle[i] as Node3D).visible = i == (kind - DRECK) % modelle.size()
		_dreck.rotation.y = float(mess_id) * 2.4
		_dreck.scale = Vector3.ONE * 1.5   # Höhe (0,045 über dem Boden) steht in mess.tscn
		# Kein Schild über jedem Haufen — der Hinweis am Fadenkreuz reicht
		_label.visible = false
		return
	var m := _disc.material_override as StandardMaterial3D
	if m == null:
		return
	var dup := m.duplicate() as StandardMaterial3D
	if kind == 1:
		dup.albedo_color = Color(0.85, 0.82, 0.35, 0.9)   # Urin: gelblich
		_disc.scale = Vector3(1.3, 1.0, 1.3)
	_disc.material_override = dup

## Temizlik ilerlemesi (0=temiz değil .. 1=temiz) -> görsel küçülür/solar.
func apply_progress(p: float) -> void:
	if ist_plane():
		# Plane wird nach vorn heruntergezogen: sie rutscht vom Möbel, die
		# Vorderkante sackt ab, hinten hebt sie sich leicht — wie ein Tuch, an
		# dem jemand zieht. Wegnehmen: entfernen().
		var g: Vector3 = DECKEN_GROESSE.get(kind, Vector3.ONE)
		var q := clampf(p, 0.0, 1.0)
		_plane.position = Vector3(0.0, 0.0, g.z * 0.45 * q)
		_plane.rotation.x = 0.18 * q
		_plane.scale = Vector3(g.x * (1.0 + 0.03 * q), g.y * (1.0 - 0.35 * q), g.z * (1.0 - 0.15 * q))
		return
	if ist_dreck():
		var d := lerpf(1.5, 0.4, clampf(p, 0.0, 1.0))
		_dreck.scale = Vector3(d, d, d)
		return
	if _disc == null:
		return
	var s := lerpf(1.0, 0.25, clampf(p, 0.0, 1.0))
	_disc.scale = Vector3(s, 1.0, s)
	var m := _disc.material_override as StandardMaterial3D
	if m:
		m.albedo_color.a = lerpf(0.95, 0.3, clampf(p, 0.0, 1.0))

## Weggeräumt (GameManager._remove_mess): die Plane fällt vorn als Stoffhaufen
## zu Boden und verschwindet dann; alles andere sofort weg.
func entfernen() -> void:
	remove_from_group("interactable")
	remove_from_group("mess")
	set_process(false)
	_pfeil.visible = false
	if not ist_plane():
		queue_free()
		return
	var g: Vector3 = DECKEN_GROESSE.get(kind, Vector3.ONE)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_plane, "scale", Vector3(g.x * 0.8, 0.12, g.z * 0.35), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_plane, "position", Vector3(0.0, 0.0, g.z * 0.75), 0.35)
	tw.tween_property(_plane, "rotation:x", 0.0, 0.35)
	tw.chain().tween_interval(0.6)
	tw.chain().tween_property(_plane, "scale", Vector3(g.x * 0.3, 0.02, g.z * 0.15), 0.4)
	tw.chain().tween_callback(queue_free)
