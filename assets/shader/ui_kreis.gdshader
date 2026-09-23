shader_type canvas_item;
// Rundes Bild (Entwurf des Nutzers: Avatar im Kreis mit Goldrand).

uniform vec4 rand : source_color = vec4(1.0, 0.84, 0.25, 1.0);
uniform vec4 grund : source_color = vec4(0.09, 0.08, 0.07, 0.95);
uniform float rand_dicke = 0.045;

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float d = length(UV - vec2(0.5)) * 2.0;
	float innen = 1.0 - smoothstep(1.0 - rand_dicke * 2.0, 1.0 - rand_dicke, d);
	float aussen = 1.0 - smoothstep(0.97, 1.0, d);
	// Bild (oder Symbol) liegt auf einer dunklen Scheibe, damit der Kreis auch
	// mit einer freigestellten Grafik gefüllt aussieht
	vec3 scheibe = mix(grund.rgb, t.rgb, t.a);
	vec3 farbe = mix(rand.rgb, scheibe, innen);
	COLOR = vec4(farbe, aussen * COLOR.a);
}
