@tool
extends EditorScenePostImport
## Ein paar FBX aus dem Kirmes-Pack verweisen auf Texturen, die der Pack nicht
## mitliefert (Texture.psd, Color.jpg) — die Modelle wären weiß. Alle anderen
## Modelle des Packs benutzen dieselbe Palette, also hängen wir sie hier nach.

const PALETTE := "res://assets/kirmes/textures/Texture_Pallete.png"

func _post_import(scene: Node) -> Object:
	var tex := load(PALETTE) as Texture2D
	if tex == null:
		return scene
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(i) as StandardMaterial3D
			if mat != null and mat.albedo_texture == null:
				mat.albedo_texture = tex
	return scene
