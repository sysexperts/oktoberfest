// Dünner Umriss um das anvisierte Objekt (player.gd _update_highlight).
// Als material_overlay auf die Meshes gelegt: die Rückseiten werden entlang der
// Normalen ein Stück aufgeblasen und einfarbig gezeichnet — vorne verdeckt das
// Objekt sie, sichtbar bleibt nur der Rand. Breite in Metern, unabhängig von der
// Skalierung des Modells.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;

uniform vec4 farbe : source_color = vec4(1.0, 0.86, 0.35, 1.0);
uniform float breite = 0.018;

void vertex() {
	float skalierung = max(length(MODEL_MATRIX[0].xyz), 0.0001);
	VERTEX += NORMAL * (breite / skalierung);
}

void fragment() {
	ALBEDO = farbe.rgb;
}
