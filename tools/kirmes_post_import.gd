@tool
extends EditorScenePostImport
## Zwei Dinge beim Import jedes Kirmes-Modells:
##
## 1. Ein paar FBX verweisen auf Texturen, die der Pack nicht mitliefert — die
##    Modelle wären weiß. Alle Modelle benutzen dieselbe Palette, also hängen
##    wir sie nach.
## 2. Der Pack bringt eine Emissions-Maske mit: genau die Palettenzelle der
##    Glühbirnen leuchtet darin. Damit glühen Budenschilder und Lampen von
##    selbst, sobald es dunkel wird — das macht die Kirmes-Optik aus.

const PALETTE := "res://assets/kirmes/textures/Texture_Pallete.png"
const EMISSION := "res://assets/kirmes/textures/Texture_Pallete_Emission.png"
const EMISSION_ENERGY := 2.5

func _post_import(scene: Node) -> Object:
	var tex := load(PALETTE) as Texture2D
	var emi := load(EMISSION) as Texture2D
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(i) as StandardMaterial3D
			if mat == null:
				continue
			if tex != null and mat.albedo_texture == null:
				mat.albedo_texture = tex
			# Die Pack-Materialien haben emission_enabled schon an, aber keine
			# Textur — deshalb hier nicht auf das Flag prüfen, sondern auf die
			# Textur selbst.
			if emi != null and mat.emission_texture == null:
				mat.emission_enabled = true
				mat.emission_texture = emi
				mat.emission = Color(1, 1, 1)
				mat.emission_energy_multiplier = EMISSION_ENERGY
				mat.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
	return scene
