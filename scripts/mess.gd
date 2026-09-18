class_name Mess
extends Node3D
## Yerdeki kir. Oyuncu E ile temizler. Host otoriter; id ile senkron.
## kind: 0 = Erbrochenes, 1 = Urin (E6), ab 2 = Dreck im verlassenen Zelt
## (Tutorial „Putze das Zelt") — 2 + Nummer des Modells unter „Dreck".

const DRECK := 2
## Ab hier: Abdeckplanen über Möbeln (abziehen statt fegen). Größe je Art.
const DECKE := 10
const DECKEN_GROESSE := {
	10: Vector3(9.0, 1.15, 1.9), 11: Vector3(9.0, 1.15, 1.9), 12: Vector3(5.6, 1.1, 1.4),
	13: Vector3(4.5, 1.05, 8.2), 14: Vector3(1.0, 1.9, 5.6),
}

var mess_id := -1
var kind := 0

@onready var _disc: MeshInstance3D = $Disc
@onready var _dreck: Node3D = $Dreck
@onready var _label: Label3D = $Label
@onready var _plane: MeshInstance3D = $Plane

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("mess")
	_apply_kind()

func set_kind(k: int) -> void:
	kind = k
	if is_inside_tree():
		_apply_kind()

func ist_plane() -> bool:
	return kind >= DECKE

func ist_dreck() -> bool:
	return kind >= DRECK

func _apply_kind() -> void:
	if _disc == null:
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
		# Plane wird weggezogen: sackt zusammen und rutscht zur Seite
		var g: Vector3 = DECKEN_GROESSE.get(kind, Vector3.ONE)
		var q := clampf(p, 0.0, 1.0)
		_plane.scale = Vector3(g.x, g.y * (1.0 - 0.7 * q), g.z)
		_plane.position.x = g.x * 0.25 * q
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
