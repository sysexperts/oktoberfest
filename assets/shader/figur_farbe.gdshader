shader_type spatial;
// Farbvarianten einer Figur aus derselben Textur: Haare (über eine gebackene
// Maske, tools/bake_lisa_maske.gd) und Kleid (kräftiges Rot der Textur) werden
// umgefärbt, Helligkeitsverlauf und Muster bleiben erhalten.
// Gesetzt von scripts/figur.gd (farbe_haar / farbe_kleid).

uniform sampler2D textur : source_color, filter_linear_mipmap;
uniform sampler2D haar_maske : hint_default_black, filter_linear;
uniform vec4 haar_farbe : source_color = vec4(0.0);
uniform vec4 kleid_farbe : source_color = vec4(0.0);
uniform float eigenleuchten = 0.35;
uniform bool nur_kern = false;

float hell(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void fragment() {
	vec3 c = texture(textur, UV).rgb;
	// Kleid: kräftiges Rot → Zielfarbe, Helligkeit relativ zum Grundrot
	vec2 maske = texture(haar_maske, UV).rg;
	// Nur kräftiges Kleid-Rot (≈ 0.6/0.02/0.05) — Haut und Brezel-Kette sind
	// zu schwach rot und bleiben. Kopf (Grün) nie als Kleid färben.
	// Erkennung im sRGB-Raum (die Textur kommt linear an): Kleid ≈ 0.6/0.02/0.05
	vec3 srgb = pow(c, vec3(1.0 / 2.2));
	float rot = smoothstep(0.3, 0.42, srgb.r - max(srgb.g, srgb.b)) * (1.0 - step(0.5, maske.g));
	if (kleid_farbe.a > 0.0 && rot > 0.0) {
		vec3 neu = kleid_farbe.rgb * clamp(c.r / 0.33, 0.3, 1.6);
		c = mix(c, neu, rot);
	}
	// Haare: nur in der Maske, Schattierung aus der Originalhelligkeit
	float haar = nur_kern ? step(0.98, maske.r) : maske.r;
	if (haar_farbe.a > 0.0 && haar > 0.0 && rot < 0.5) {
		vec3 neu = haar_farbe.rgb * clamp(hell(c) / 0.52, 0.4, 1.5);
		c = mix(c, neu, haar);
	}
	ALBEDO = c;
	ROUGHNESS = 0.75;
	SPECULAR = 0.3;
	EMISSION = c * eigenleuchten;
}
