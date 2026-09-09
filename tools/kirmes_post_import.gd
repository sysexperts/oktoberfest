@tool
extends EditorScenePostImport
## Ein paar FBX aus dem Kirmes-Pack verweisen auf Texturen, die der Pack nicht
## mitliefert (Texture.psd, Color.jpg) — die Modelle wären weiß. Alle anderen
## Modelle des Packs benutzen dieselbe Palette, also hängen wir sie hier nach.
##
## Die Emissions-Maske des Packs hatten wir hier schon mal angehängt, damit
## Budenschilder und Glühbirnen von selbst leuchten. Im Spiel strahlte danach
## aber alles gleißend weiß, also ist sie wieder raus — die Kirmesbeleuchtung
## kommt stattdessen aus den Lichtern, die wir selbst setzen (Laternen,
## Lichterketten, Standlichter).

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
			if mat == null:
				continue
			if mat.albedo_texture == null:
				mat.albedo_texture = tex
			# Der Pack setzt emission_enabled auf allen Materialien, liefert aber
			# keine Textur dazu — ohne Textur leuchtet dann die volle Farbe.
			mat.emission_enabled = false
	return scene
