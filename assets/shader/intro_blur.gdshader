shader_type canvas_item;
// Unschärfe über dem Bildschirm (Intro-Übergang): staerke 1 = stark verwischt, 0 = scharf
uniform sampler2D bild : hint_screen_texture, filter_linear_mipmap;
uniform float staerke : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 summe = vec4(0.0);
	float lod = staerke * 5.0;
	vec2 px = SCREEN_PIXEL_SIZE * staerke * 6.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			summe += textureLod(bild, SCREEN_UV + vec2(float(x), float(y)) * px, lod);
		}
	}
	COLOR = summe / 25.0;
}
