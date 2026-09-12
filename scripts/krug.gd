@tool
class_name Krug
extends Node3D
## Maßkrug aus Glas (Modell assets/models/krug.glb) mit Bier darin.
## fuellung: 0 leer … 1 voll · farbe: Biersorte.
## Aufbau in scenes/krug.tscn — Glasmaterial, Bierhöhe und Glasboden dort anpassen.
## Der Ursprung liegt am Boden des Krugs.

@export_range(0.0, 1.0) var fuellung := 1.0:
	set(v):
		fuellung = clampf(v, 0.0, 1.0)
		_anwenden()
@export var farbe := Color(0.95, 0.75, 0.2):
	set(v):
		farbe = v
		_anwenden()
## So hoch steht das Bier im vollen Krug (über dem Glasboden)
@export var innen_hoehe := 0.16
## Dicke des Glasbodens
@export var boden := 0.014
## Wird auf alle Flächen des Krug-Modells gelegt
@export var glas_material: Material

## Biermaterial je Farbe — geteilt, sonst hätte jeder der vielen Krüge eine Kopie
static var _bier_materialien := {}

func _ready() -> void:
	if glas_material:
		for mi: MeshInstance3D in $Glas.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = glas_material
	_anwenden()

func _anwenden() -> void:
	if not is_node_ready():
		return
	var bier := $Bier as MeshInstance3D
	var schaum := $Schaum as MeshInstance3D
	var h := innen_hoehe * fuellung
	bier.visible = fuellung > 0.01
	schaum.visible = fuellung > 0.01
	bier.scale = Vector3(1.0, maxf(h, 0.001), 1.0)
	bier.position.y = boden + h * 0.5
	schaum.position.y = boden + h + 0.006
	var schluessel := farbe.to_html()
	if not _bier_materialien.has(schluessel):
		var m := StandardMaterial3D.new()
		m.albedo_color = farbe
		m.roughness = 0.3
		m.emission_enabled = true
		m.emission = farbe.darkened(0.6)
		_bier_materialien[schluessel] = m
	bier.material_override = _bier_materialien[schluessel]
