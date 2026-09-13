extends Node3D
## Klo-Container im Zelt: eine Person gleichzeitig. Die Lampe über der Tür zeigt
## rot = besetzt, grün = frei. Wer drin ist, führt der GameManager (_klo_gast)
## und meldet es an alle Mitspieler (_net_klo → set_besetzt).

const ROT := Color(1.0, 0.12, 0.08)
const GRUEN := Color(0.2, 1.0, 0.3)

var besetzt := false

func _ready() -> void:
	set_besetzt(false)

func set_besetzt(b: bool) -> void:
	besetzt = b
	var farbe := ROT if b else GRUEN
	var lampe := get_node_or_null("Lampe") as MeshInstance3D
	if lampe and lampe.material_override is StandardMaterial3D:
		var m := lampe.material_override as StandardMaterial3D
		m.albedo_color = farbe
		m.emission = farbe
	var licht := get_node_or_null("LampenLicht") as OmniLight3D
	if licht:
		licht.light_color = farbe
