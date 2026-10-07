extends Node3D
## Konrads Überwachungskamera (scenes/sab_kamera.tscn, in scenes/huber_zelt.tscn über den Sabotage-Stellen).
## Sie schwenkt hin und her. Wer im Blickfeld Gustavs Werkzeug einsetzt, wird erwischt (scripts/sab_ziel.gd).
## Die Kameras hängen erst ab `ab_kapitel`. Tarnung verkürzt die Reichweite wie bei Konrad selbst.
## Blickrichtung ist die lokale +Z-Achse (wie bei Konrad), geschwenkt wird um die Hochachse.

@export var ab_kapitel := 4
@export var schwenk := 1.0       # halber Schwenkwinkel in Bogenmaß
@export var tempo := 0.7
@export var halbwinkel := 35.0   # Blickfeld in Grad zu jeder Seite

@onready var _kopf: Node3D = $Kopf
@onready var _led: MeshInstance3D = $Kopf/Led

var _t := randf() * TAU
var _kapitel_t := 0.0
var _aktiv := false

func _ready() -> void:
	add_to_group("konrad_kamera")
	visible = false

func _process(delta: float) -> void:
	_kapitel_t -= delta
	if _kapitel_t <= 0.0:
		_kapitel_t = 1.0
		var welt := get_tree().current_scene
		var hud: Object = welt.get("_hud")
		var z: Dictionary = hud.get("_zustand") if hud != null else {}
		_aktiv = int((z.get("story", {}) as Dictionary).get("kapitel", 1)) >= ab_kapitel
		visible = _aktiv
	if _aktiv:
		_t += delta * tempo
		_kopf.rotation.y = sin(_t) * schwenk

## Aktiv (hängt schon) und gerade im Blickfeld? stufe: 0 ohne Tarnung, 1 Mantel, 2 Komplettset.
func sieht(stelle: Vector3, stufe: int) -> bool:
	if not _aktiv:
		return false
	var reichweite: float = [11.0, 7.0, 3.5][clampi(stufe, 0, 2)]
	var zu := stelle - _kopf.global_position
	zu.y = 0.0
	if zu.length() > reichweite:
		return false
	var vorn := _kopf.global_transform.basis.z
	vorn.y = 0.0
	return rad_to_deg(vorn.normalized().angle_to(zu.normalized())) <= halbwinkel
