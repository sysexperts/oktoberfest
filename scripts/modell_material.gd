extends RefCounted
## Meshy-Modelle (assets/models) bringen eine gebackene Metallic-Karte mit
## (metallic = 1). Im Zelt spiegeln sie dann nur die Umgebung und wirken dunkel.
## ohne_metall() setzt je Material einmal eine Kopie ohne Metall ein — alle
## Instanzen desselben Modells teilen sie. Ohne class_name, einbinden per preload.

static var _kopien := {}

static func ohne_metall(wurzel: Node) -> void:
	for mi: MeshInstance3D in wurzel.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var original := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if original == null:
				continue
			if not _kopien.has(original):
				var kopie := original.duplicate() as BaseMaterial3D
				kopie.metallic = 0.0
				kopie.metallic_texture = null
				kopie.metallic_specular = 0.4
				_kopien[original] = kopie
			mi.set_surface_override_material(s, _kopien[original])
