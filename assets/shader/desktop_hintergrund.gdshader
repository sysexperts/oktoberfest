shader_type canvas_item;
// Hintergrundbild des Computer-Desktops im Festbüro: blau-weiße Rauten (bayerisches Muster), in der Mitte etwas heller,
// zum Rand hin dunkler. Eigenes Muster, keine fremde Vorlage. Parameter lassen sich im Editor ändern.

uniform vec4 blau : source_color = vec4(0.09, 0.22, 0.46, 1.0);
uniform vec4 hell : source_color = vec4(0.62, 0.72, 0.90, 1.0);
uniform float raute = 96.0;
uniform float kontrast = 0.22;
uniform float rand_dunkel = 0.62;

void fragment() {
	vec2 px = FRAGCOORD.xy;
	// Rauten: um 45 Grad gedreht, Schachbrettmuster
	vec2 g = vec2(px.x + px.y, px.x - px.y) / (raute * 1.4142);
	float feld = mod(floor(g.x) + floor(g.y), 2.0);
	vec3 farbe = mix(blau.rgb, hell.rgb, feld * kontrast);
	// Vignette
	vec2 mitte = UV - vec2(0.5);
	float v = 1.0 - smoothstep(0.25, 0.95, length(mitte * vec2(1.0, 1.15)));
	farbe *= mix(rand_dunkel, 1.0, v);
	COLOR = vec4(farbe, 1.0);
}
