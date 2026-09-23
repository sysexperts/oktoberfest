shader_type canvas_item;
// Milchglas hinter einer UI-Fläche (Entwurf des Nutzers: „Glassmorphism"):
// verwischt das Spielbild dahinter und schneidet die Ecken rund ab.
//
// In Godot 4 gibt es SCREEN_TEXTURE nicht mehr — das Bild dahinter kommt über
// einen Uniform mit hint_screen_texture (sonst bleibt die Fläche weiß).
// groesse und radius setzt das Skript, weil ein Canvas-Shader die Knotengröße
// nicht selbst kennt.

uniform sampler2D dahinter : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec2 groesse = vec2(300.0, 80.0);
uniform float radius = 20.0;
uniform float staerke = 2.5;     // Streuung in Pixeln je Schritt
uniform vec4 toenung : source_color = vec4(0.0, 0.0, 0.0, 0.45);

// Abstand zum Rand eines abgerundeten Rechtecks (negativ = innen)
float rund(vec2 p, vec2 halb, float r) {
	vec2 d = abs(p) - (halb - vec2(r));
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - r;
}

void fragment() {
	vec2 pixel = SCREEN_PIXEL_SIZE * staerke;
	// 3x3-Mittel: reicht für den weichen Eindruck und kostet fast nichts
	vec3 summe = vec3(0.0);
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			summe += texture(dahinter, SCREEN_UV + vec2(float(x), float(y)) * pixel).rgb;
		}
	}
	vec3 verwischt = summe / 9.0;
	vec3 farbe = mix(verwischt, toenung.rgb, toenung.a);
	// Rand weich abschneiden, damit die Ecken rund sind
	float d = rund((UV - vec2(0.5)) * groesse, groesse * 0.5, radius);
	COLOR = vec4(farbe, 1.0 - smoothstep(-1.0, 0.5, d));
}
