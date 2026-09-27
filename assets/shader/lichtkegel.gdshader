shader_type spatial;
// Lichtkegel eines Bühnenstrahlers (scenes/buehne.tscn, scripts/stage.gd).
// Hell an der Lampe, läuft nach unten aus, weiche Ränder, weich an Boden und
// Figuren (Tiefenvergleich), dazu langsam treibender Staub im Strahl.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 farbe : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float staerke = 0.35;
uniform float auslauf = 1.8;
uniform float rand_weich = 2.2;
uniform float boden_weich = 0.6;
uniform sampler2D tiefe : hint_depth_texture, filter_linear;

varying vec3 lokal;

void vertex() {
	lokal = VERTEX;
}

float rauschen(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float wolke(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(rauschen(i), rauschen(i + vec2(1, 0)), f.x),
		mix(rauschen(i + vec2(0, 1)), rauschen(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	// UV.y: 0 an der Lampe, 1 am Ende des Kegels
	float laenge = pow(1.0 - UV.y, auslauf);
	// Ränder weich: flach angeschaute Flächen verschwinden
	float kante = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), rand_weich);
	// Weich enden, wo der Strahl Boden oder Figuren trifft
	float t = texture(tiefe, SCREEN_UV).r;
	vec4 welt = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, t, 1.0);
	float szene = -welt.z / welt.w;
	float ich = -VERTEX.z;
	float weich = clamp((szene - ich) / boden_weich, 0.0, 1.0);
	// Staub, der langsam durch den Strahl treibt
	float staub = 0.75 + 0.5 * wolke(vec2(UV.x * 18.0, UV.y * 6.0 - TIME * 0.35));
	float a = staerke * farbe.a * laenge * kante * weich * staub;
	ALBEDO = farbe.rgb * a;
	ALPHA = 1.0;
}
