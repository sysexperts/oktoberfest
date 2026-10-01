shader_type canvas_item;
// Schneidet ein Bild (oder eine Fläche) auf ein Quadrat mit runden Ecken zu.
// Für Profilbilder im Steam-Warteraum; passt zu profil_rahmen.gdshader.

uniform float rundung : hint_range(0.0, 0.5) = 0.17;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec2 q = abs(UV - 0.5) - vec2(0.5 - rundung);
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rundung;
	float aa = fwidth(d) * 1.2;
	c.a *= 1.0 - smoothstep(-aa, aa, d);
	COLOR = c;
}
