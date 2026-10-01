shader_type canvas_item;
// Leuchtender, umlaufender Rahmen für Profilbilder (Steam-Warteraum).
// Auf ein quadratisches ColorRect legen; das Bild selbst liegt etwas kleiner
// darüber (Rand = glow_rand). Zwei Farben laufen als Farbverlauf im Kreis um
// den Rahmen, ein heller Strahl dreht sich mit, und das Leuchten außen pulsiert.

uniform vec4 farbe_a : source_color = vec4(0.34, 0.8, 0.87, 1.0);
uniform vec4 farbe_b : source_color = vec4(0.62, 0.45, 0.95, 1.0);
// Rundung und Dicke des Rahmens, Breite des Leuchtens — Anteile der Kantenlänge
uniform float rundung : hint_range(0.0, 0.5) = 0.17;
uniform float dicke : hint_range(0.0, 0.2) = 0.04;
uniform float glow_rand : hint_range(0.0, 0.3) = 0.13;
// Umläufe pro Sekunde (0 = steht) und Stärke des Strahls und des Leuchtens
uniform float tempo = 0.3;
uniform float strahl = 0.55;
uniform float leuchten = 0.7;
// Pulsgeschwindigkeit des Leuchtens (0 = gleichmäßig)
uniform float puls = 2.0;

float kasten(vec2 p, float halb, float r) {
	vec2 q = abs(p) - vec2(halb - r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV - 0.5;
	float halb = 0.5 - glow_rand;
	float d = kasten(p, halb, rundung);
	float aa = fwidth(d) * 1.2;
	// Ring: innen vom Rand "dicke" breit
	float ring = 1.0 - smoothstep(-aa, aa, abs(d + dicke * 0.5) - dicke * 0.5);
	float umlauf = atan(p.y, p.x) / 6.2831853 + TIME * tempo;
	float mischung = 0.5 + 0.5 * sin(umlauf * 6.2831853);
	float spitze = pow(0.5 + 0.5 * cos(fract(umlauf) * 6.2831853), 7.0);
	vec3 farbe = mix(farbe_a.rgb, farbe_b.rgb, mischung) + vec3(spitze * strahl);
	float atmen = 0.8 + 0.2 * sin(TIME * puls);
	// Leuchten nur außerhalb des Rings, fällt weich ab
	float aussen = smoothstep(glow_rand, 0.0, max(d, 0.0)) * step(0.0, d + dicke);
	aussen = aussen * aussen * leuchten * atmen;
	float a = clamp(ring + aussen * (1.0 - ring), 0.0, 1.0);
	COLOR = vec4(farbe * (1.0 + spitze * 0.3 * ring), a);
}
