shader_type canvas_item;
// Farbverlauf über einen Text (Entwurf des Nutzers: Geldbetrag in Gold von hell
// nach dunkel). Godot-Labels können keinen Verlauf füllen — hier wird die
// fertige Schrift von oben nach unten eingefärbt, die Buchstabenform bleibt.

uniform vec4 oben : source_color = vec4(0.99, 0.92, 0.58, 1.0);
uniform vec4 unten : source_color = vec4(0.93, 0.68, 0.11, 1.0);

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	COLOR = vec4(mix(oben.rgb, unten.rgb, clamp(UV.y, 0.0, 1.0)), t.a * COLOR.a);
}
