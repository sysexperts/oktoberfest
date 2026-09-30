// Dünner Umriss um das anvisierte Objekt (player.gd _update_highlight).
// Als material_overlay auf die Meshes gelegt: die Rückseiten werden entlang der
// Normalen ein Stück aufgeblasen und einfarbig gezeichnet — vorne verdeckt das
// Objekt sie, sichtbar bleibt nur der Rand. Breite in Metern, unabhängig von der
// Skalierung des Modells.
//
// Stencil: umriss_schreiber.tres (der erste Durchgang, dieser hier hängt als
// next_pass daran) markiert jeden Pixel, den das Ziel selbst belegt. Die Hülle
// wird nur dort gezeichnet, wo nichts markiert ist — also außerhalb der
// Gesamtform. Ohne das zeichneten die aufgeblasenen Rückseiten von Augen,
// Mund, Bart und Hut Ringe mitten ins Gesicht.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled, blend_mix;
stencil_mode read, compare_not_equal, 1;

uniform vec4 farbe : source_color = vec4(1.0, 0.86, 0.35, 1.0);
uniform float breite = 0.018;

void vertex() {
	float skalierung = max(length(MODEL_MATRIX[0].xyz), 0.0001);
	VERTEX += NORMAL * (breite / skalierung);
}

void fragment() {
	ALBEDO = farbe.rgb;
	ALPHA = 1.0;   // gleiche Warteschlange wie der Schreiber, Reihenfolge über render_priority
}
