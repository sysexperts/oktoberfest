@tool
extends Area3D
## Fläche, die Kirmes-Besucher (scripts/visitor.gd, scripts/crowd.gd) meiden:
## kein Wegpunkt darin, und wer darauf zuläuft, weicht aus wie vor einer Wand.
## Spieler, Gäste und Kellner merken nichts davon — die Fläche liegt allein auf
## der Physik-Ebene EBENE, und nur die Besucher fragen diese Ebene ab.
##
## Benutzen: im Baumodus (F8) unter „Besucher-Sperren“ aufstellen, oder als
## Kind in eine Szene hängen (steckt z. B. schon in scenes/tent.tscn). Die
## Größe kommt vom BoxShape der CollisionShape3D — im Editor ziehbar; die rote
## Anzeige passt sich an. Sichtbar ist sie nur im Editor und im Baumodus.

## Physik-Ebene 20 — sonst von nichts benutzt
const EBENE := 1 << 19

## Im Baumodus an (scripts/ui/baumodus.gd)
static var anzeigen := false

@onready var _anzeige := get_node_or_null("Anzeige") as MeshInstance3D

func _ready() -> void:
	collision_layer = EBENE
	collision_mask = 0
	monitoring = false
	input_ray_pickable = false
	add_to_group("besucher_sperre")
	_anzeige_anpassen()

func _anzeige_anpassen() -> void:
	if _anzeige == null:
		return
	_anzeige.visible = Engine.is_editor_hint() or anzeigen
	var form := get_node_or_null("Form") as CollisionShape3D
	if form and form.shape is BoxShape3D and _anzeige.mesh is BoxMesh:
		(_anzeige.mesh as BoxMesh).size = (form.shape as BoxShape3D).size
		_anzeige.transform = form.transform

## Alle Sperren ein- oder ausblenden (Baumodus an/aus)
static func alle_anzeigen(baum: SceneTree, an: bool) -> void:
	anzeigen = an
	baum.call_group("besucher_sperre", "_anzeige_anpassen")

## Liegt diese Form (Besucher-Körper) in einer Sperre?
static func gesperrt(raum: PhysicsDirectSpaceState3D, abfrage: PhysicsShapeQueryParameters3D) -> bool:
	var maske := abfrage.collision_mask
	var bereiche := abfrage.collide_with_areas
	var koerper := abfrage.collide_with_bodies
	abfrage.collision_mask = EBENE
	abfrage.collide_with_areas = true
	abfrage.collide_with_bodies = false
	var treffer := not raum.intersect_shape(abfrage, 1).is_empty()
	abfrage.collision_mask = maske
	abfrage.collide_with_areas = bereiche
	abfrage.collide_with_bodies = koerper
	return treffer
