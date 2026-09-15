shader_type canvas_item;
// Bildfilter über der 3D-Welt (unter dem HUD): dunklere Bildränder und leichte Körnung.
// Liegt in scenes/effekte/bildfilter.tscn, grafikstufe.gd schaltet ihn ab Stufe Mittel ein.

uniform sampler2D bild : hint_screen_texture, filter_linear;
uniform float vignette : hint_range(0.0, 1.0) = 0.38;
uniform float koernung : hint_range(0.0, 0.1) = 0.02;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(bild, SCREEN_UV).rgb;
	vec2 q = SCREEN_UV - 0.5;
	c *= 1.0 - smoothstep(0.25, 0.85, length(q * vec2(1.0, 0.8))) * vignette;
	c += (hash(SCREEN_UV * 1000.0 + fract(TIME * 7.0) * 61.0) - 0.5) * koernung;
	COLOR = vec4(c, 1.0);
}
