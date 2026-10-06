shader_type spatial;
// Frisuren aus dem Charakter-Creator: graue Haartextur (mit eingebackenem Schatten) mal Haarfarbe. Wie assets/shader/kleidung.gdshader
// mit Tiefenvorrang: Haar liegt immer vor Kleidung und Haut, auch wenn ein Zopf oder lange Haare in Schulter oder Kleid
// hineinragen (Look.TIEFE_HAAR).
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 farbe : source_color = vec4(1.0);
uniform float leuchten = 0.5;
uniform float rauheit = 0.9;
uniform float tiefe = 0.0;

void vertex() {
	// POSITION wird immer gesetzt (sonst bleibt sie bei tiefe = 0 undefiniert); die Tiefe verschiebt nur entlang des Sehstrahls
	vec3 vv = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vv -= normalize(vv) * tiefe;
	POSITION = PROJECTION_MATRIX * vec4(vv, 1.0);
}

void fragment() {
	vec3 c = texture(tex, UV).rgb * farbe.rgb;
	ALBEDO = c;
	EMISSION = c * leuchten;
	ROUGHNESS = rauheit;
	SPECULAR = 0.2;
}
