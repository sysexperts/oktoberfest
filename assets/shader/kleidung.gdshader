shader_type spatial;
// Kleidung aus dem Charakter-Creator (scripts/charakter_look.gd, tools/blender/kleidung.py):
// Die Textur traegt in R eine Maske (0 = Hauptfarbe, 1 = Zweitfarbe/Besatz, dazwischen Mischung, z. B.
// Karomuster) und in G den eingebackenen Schatten. Die beiden Farben stellt der Creator ein.
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 haupt : source_color = vec4(1.0);
uniform vec4 muster : source_color = vec4(1.0);
// Wie stark das Zelt auch im Dunkeln leuchtet (wie Figur.eigenleuchten beim Koerper)
uniform float leuchten = 0.5;
// Knoepfe, Guertel usw.: eine Farbe statt der Textur
uniform bool einfarbig = false;
uniform float rauheit = 0.9;
// Tiefenvorrang in Metern: das Stueck wird beim Zeichnen so behandelt, als laege es um diese Strecke naeher an der
// Kamera (nur die Tiefe, nicht die Bildposition). Aeussere Schichten (Jacke > Hose > Hemd > Haut) gewinnen damit
// immer, auch wenn die Animation sie ein paar cm ineinanderschiebt. Werte: scripts/charakter_look.gd (TIEFE)
uniform float tiefe = 0.0;
// Mehr Vorrang fuer einzelne Stuecke (ihre Vertexfarbe ist dann durch diesen Wert geteilt): Puffaermel der Bluse
uniform float skala = 1.0;
// Mehr Vorrang fuer einzelne Stuecke (die Vertexfarbe ist dann durch diesen Wert geteilt): Puffaermel der Bluse

void vertex() {
	// POSITION wird immer gesetzt (sonst bleibt sie bei tiefe = 0 undefiniert); die Tiefe verschiebt nur entlang des Sehstrahls
	vec3 vv = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vv -= normalize(vv) * tiefe * skala * COLOR.r;   // COLOR.r: Anteil je Punkt (0 am Hals und Handgelenk), ohne Vertexfarben 1
	POSITION = PROJECTION_MATRIX * vec4(vv, 1.0);
}

void fragment() {
	vec4 t = texture(tex, UV);
	vec3 c = einfarbig ? haupt.rgb : mix(haupt.rgb, muster.rgb, t.r) * t.g;
	ALBEDO = c;
	EMISSION = c * leuchten;
	ROUGHNESS = rauheit;
	SPECULAR = 0.2;
}
