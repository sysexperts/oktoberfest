shader_type spatial;
render_mode unshaded, blend_mul, cull_back, depth_draw_never, shadows_disabled, fog_disabled;
// Zweiter Durchgang über Kirmes-, Zelt- und Tischmaterialien (grafikstufe.gd, ab Stufe Mittel):
// multipliziert feine Farbflecken, Schmutz am Boden und dunklere Kanten aufs Bild,
// damit die glatten Farbflächen nicht nach Plastik aussehen.

varying vec3 w;
varying vec3 n;

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
	n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = w.xz + vec2(w.y * 0.7, -w.y * 0.4);
	float fleck = mix(0.88, 1.0, rauschen(p * 0.9)) * mix(0.93, 1.0, rauschen(p * 6.0));
	float boden = mix(0.72, 1.0, smoothstep(0.0, 1.4, w.y));
	float fres = pow(1.0 - clamp(abs(dot(normalize(n), normalize(CAMERA_POSITION_WORLD - w))), 0.0, 1.0), 2.5);
	ALBEDO = vec3(fleck * boden * mix(1.0, 0.78, fres));
}
