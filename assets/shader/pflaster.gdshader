shader_type spatial;
// Kopfsteinpflaster in Weltkoordinaten — Wege auf dem Festplatz und Straßen
// (scenes/kulisse/strassen.tscn). Form der Fläche egal, Steine laufen durch.

uniform vec3 farbe : source_color = vec3(0.6, 0.56, 0.5);
uniform float stein = 0.34;

varying vec3 w;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rauschen(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 s = w.xz;
	vec2 g = vec2(stein * 1.15, stein);
	float zeile = floor(s.y / g.y);
	float x = s.x / g.x + mod(zeile, 2.0) * 0.5 + hash(vec2(zeile, 3.0)) * 0.3;
	vec2 f = vec2(fract(x), fract(s.y / g.y));
	float fuge = 0.14;
	float fx = fuge * g.y / g.x;
	float kante = smoothstep(0.0, fx, f.x) * smoothstep(1.0, 1.0 - fx, f.x)
		* smoothstep(0.0, fuge, f.y) * smoothstep(1.0, 1.0 - fuge, f.y);
	float zufall = hash(vec2(floor(x), zeile));
	vec2 fw = fwidth(s);
	float d = 1.0 - smoothstep(0.2, 0.6, max(fw.x, fw.y) / stein);
	vec3 c = farbe * mix(0.86, (0.62 + 0.38 * kante) * (0.8 + 0.4 * zufall), d);
	c *= 0.84 + 0.26 * rauschen(s * 0.12) - 0.06 * rauschen(s * 1.3);
	ALBEDO = c;
	ROUGHNESS = mix(0.95, 0.78, kante * d);
}
