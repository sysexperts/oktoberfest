@tool
extends Camera3D
## Trailer-Kamera: schaut immer auf das Blickziel — auch im Editor, damit die
## Kameravorschau (Knopf „Vorschau“ oben im 3D-Fenster) stimmt, während man
## am PathFollow3D „Wagen“ den Regler progress_ratio zieht.

@export var ziel: Node3D

func _process(_delta: float) -> void:
	if ziel and is_inside_tree() and ziel.is_inside_tree():
		var z := ziel.global_position
		if not global_position.is_equal_approx(z):
			look_at(z, Vector3.UP)
