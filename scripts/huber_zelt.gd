extends Node3D
## Hubers Festzelt (Rivale, siehe Konzept): eine verkleinerte Kopie unseres
## Zelts (scenes/tent.tscn) in Rot. Die Farben tauscht `tausch` beim Start:
## Material unseres Zelts → Material für Huber. Im Editor ergänzbar.

@export var tausch: Dictionary[Material, Material] = {}

func _ready() -> void:
	add_to_group("huber_zelt")
	for m in find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.material_override and tausch.has(mi.material_override):
			mi.material_override = tausch[mi.material_override]
		for i in mi.get_surface_override_material_count():
			var s := mi.get_surface_override_material(i)
			if s and tausch.has(s):
				mi.set_surface_override_material(i, tausch[s])
