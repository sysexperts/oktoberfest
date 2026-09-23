shader_type canvas_item;
// Ringanzeige für Werte von 0 bis 1 (Beliebtheit, Sauberkeit in der Leiste).
// Der Ring startet oben und läuft im Uhrzeigersinn; die Enden sind rund.
//
// Balken brauchen Breite und eine Beschriftung daneben, ein Ring sagt dasselbe
// auf 34 Pixeln und lässt Platz für das Symbol in der Mitte.

uniform float wert : hint_range(0.0, 1.0) = 0.75;
uniform vec4 farbe : source_color = vec4(1.0, 0.839, 0.349, 1.0);
uniform vec4 spur : source_color = vec4(1.0, 0.96, 0.9, 0.16);
// Dicke und Radius in Anteilen der Knotengröße
uniform float dicke = 0.11;
uniform float radius = 0.38;

const float PI2 = 6.28318530718;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p);
	// Weiche Kante aus der Ableitung: der Knoten ist nur ~34 px groß, eine
	// Bildschirm-Pixelbreite wäre in seinem UV viel zu klein gewesen (die Ringe
	// sahen dadurch ausgefranst aus).
	float kante = fwidth(d) * 1.1;
	float band = smoothstep(radius + dicke * 0.5 + kante, radius + dicke * 0.5 - kante, d)
		* smoothstep(radius - dicke * 0.5 - kante, radius - dicke * 0.5 + kante, d);
	// Winkel ab oben, im Uhrzeigersinn, 0 … 1
	float t = fract(atan(p.x, -p.y) / PI2 + 1.0);
	float gefuellt = step(t, wert);
	// Runde Enden: Kappen an Anfang und Ende des Bogens
	vec2 anfang = vec2(0.0, -radius);
	float winkel = wert * PI2;
	vec2 ende = vec2(sin(winkel), -cos(winkel)) * radius;
	float kr = dicke * 0.5;
	float kappe = max(
		1.0 - smoothstep(kr - kante, kr + kante, length(p - anfang)),
		1.0 - smoothstep(kr - kante, kr + kante, length(p - ende)));
	// Bei fast leerem Ring nur die Anfangskappe zeigen, sonst sitzt ein Klecks da
	kappe *= step(0.02, wert);
	float bogen = clamp(max(gefuellt * band, kappe * band), 0.0, 1.0);
	vec4 aus = mix(vec4(spur.rgb, spur.a * band), vec4(farbe.rgb, farbe.a * band), bogen);
	COLOR = vec4(aus.rgb, aus.a * COLOR.a);
}
