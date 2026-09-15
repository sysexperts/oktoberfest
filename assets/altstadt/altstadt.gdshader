shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
// Altstadt-Kulisse (tools/bake_altstadt.gd) — ein Material für alles:
//   UV.x  = Oberflächenart (siehe ART_* im Bake-Werkzeug)
//   UV2   = Flächenmaße in Metern (Fenster und Uhren: 0 … 1)
//   COLOR = Grundfarbe
// Muster (Ziegel, Fugen, Fenstersprossen, Uhr …) zeichnet der Shader und blendet
// sie in der Ferne weich aus, damit nichts flimmert.
// Nachts leuchten zufällige Fenster — GameManager setzt „nacht“.

uniform float nacht : hint_range(0.0, 1.0) = 0.0;
uniform vec3 fensterlicht : source_color = vec3(1.0, 0.68, 0.34);

varying vec3 welt;
varying float art;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rauschen(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// 1 = Muster mit Periode p gut sichtbar, 0 = zu klein auf dem Bildschirm
float deutlich(vec2 s, float p) {
	vec2 fw = fwidth(s);
	return 1.0 - smoothstep(0.2, 0.6, max(fw.x, fw.y) / p);
}

float linie(vec2 p, vec2 a, vec2 b, float breite) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return 1.0 - smoothstep(breite * 0.5, breite, length(pa - ba * h));
}

// Mauerwerk: Steine der Größe g, jede zweite Reihe versetzt. x = Fugenanteil, y = Zufall je Stein
vec2 mauer(vec2 s, vec2 g, float fuge) {
	float zeile = floor(s.y / g.y);
	float x = s.x / g.x + mod(zeile, 2.0) * 0.5;
	vec2 f = vec2(fract(x), fract(s.y / g.y));
	float fx = fuge * g.y / g.x;
	float stein = smoothstep(0.0, fx, f.x) * smoothstep(1.0, 1.0 - fx, f.x)
		* smoothstep(0.0, fuge, f.y) * smoothstep(1.0, 1.0 - fuge, f.y);
	return vec2(stein, hash(vec2(floor(x), zeile)));
}

void vertex() {
	welt = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	art = UV.x;
}

void fragment() {
	vec3 c = COLOR.rgb;
	float rau = 0.92;
	float metall = 0.0;
	vec3 leuchten = vec3(0.0);
	vec2 s = UV2;
	int k = int(art + 0.5);
	float grob = rauschen(welt.xz * 0.3 + vec2(welt.y * 0.25));

	if (k == 0) {
		// Putz: fleckig, unten etwas schmutziger
		c *= 0.92 + 0.12 * rauschen(s * 1.6) - 0.05 * grob;
	} else if (k == 1) {
		// Biberschwanz-Ziegel
		float d = deutlich(s, 0.32);
		float zeile = s.y / 0.3;
		float x = s.x / 0.28 + mod(floor(zeile), 2.0) * 0.5;
		float fz = fract(zeile);
		float fx = fract(x);
		float form = (0.72 + 0.28 * smoothstep(0.0, 0.8, fz))
			* (0.8 + 0.2 * smoothstep(0.0, 0.1, fx) * smoothstep(1.0, 0.9, fx));
		float zufall = 0.86 + 0.28 * hash(vec2(floor(x), floor(zeile)));
		c *= mix(0.86, form * zufall, d) * (0.88 + 0.2 * grob);
		rau = 0.78;
	} else if (k == 2) {
		// Holz
		c *= 0.78 + 0.3 * rauschen(vec2(s.x * 1.2, s.y * 12.0));
	} else if (k == 3) {
		// Fenster mit Rahmen und Sprossenkreuz; nachts leuchten manche
		float d = deutlich(s, 0.12);
		float sprosse = max(1.0 - step(0.035, abs(s.x - 0.5)), 1.0 - step(0.03, abs(s.y - 0.64)));
		float rand = 1.0 - step(0.05, s.x) * step(s.x, 0.95) * step(0.04, s.y) * step(s.y, 0.96);
		float holz = max(sprosse, rand) * d;
		float spiegel = smoothstep(0.1, 1.0, s.y) * (0.5 + 0.5 * hash(floor(welt.xz * 0.7)));
		vec3 glas = vec3(0.06, 0.08, 0.11) + vec3(0.16, 0.2, 0.26) * spiegel;
		float an = step(0.45, hash(floor(welt.xz * 0.55) + vec2(floor(welt.y / 2.9) * 7.31)));
		float warm = 0.7 + 0.3 * hash(floor(welt.xz * 0.55) + 3.7);
		leuchten = fensterlicht * an * warm * nacht * 2.4 * (1.0 - holz);
		c = mix(glas, vec3(0.92, 0.9, 0.84), holz);
		rau = mix(0.12, 0.8, holz);
	} else if (k == 4) {
		// Naturstein-Quader
		vec2 m = mauer(s, vec2(0.9, 0.42), 0.08);
		float d = deutlich(s, 0.42);
		c *= mix(0.9, (0.7 + 0.3 * m.x) * (0.84 + 0.32 * m.y), d) * (0.9 + 0.18 * grob);
	} else if (k == 5) {
		// Kupfer mit Patina, senkrechte Falze
		float d = deutlich(s, 0.6);
		float falz = smoothstep(0.0, 0.08, fract(s.x / 0.6)) * smoothstep(1.0, 0.92, fract(s.x / 0.6));
		c *= (0.78 + 0.35 * rauschen(s * vec2(1.5, 0.6))) * mix(0.93, 0.8 + 0.2 * falz, d);
		rau = 0.5;
		metall = 0.2;
	} else if (k == 6) {
		// Gold (Turmkugeln, Kreuze)
		metall = 0.9;
		rau = 0.28;
		leuchten = c * 0.08;
	} else if (k == 7) {
		// Wiese und Felder
		float n1 = rauschen(welt.xz * 0.025);
		float n2 = rauschen(welt.xz * 0.22);
		c *= 0.78 + 0.3 * n1 + 0.14 * n2;
		c = mix(c, c * vec3(1.15, 1.06, 0.72), smoothstep(0.55, 0.85, n1) * 0.5);
	} else if (k == 8) {
		// Maibaum weiß-blau gewunden
		float band = step(0.5, fract((s.y + s.x * 0.9) / 1.4));
		c = mix(vec3(0.95, 0.95, 0.93), vec3(0.1, 0.34, 0.72), band);
		rau = 0.5;
	} else if (k == 9) {
		// Kopfsteinpflaster
		vec2 m = mauer(welt.xz, vec2(0.34, 0.3), 0.14);
		float d = deutlich(welt.xz, 0.3);
		c *= mix(0.88, (0.68 + 0.32 * m.x) * (0.85 + 0.3 * m.y), d) * (0.88 + 0.2 * grob);
	} else if (k == 10) {
		// Turmuhr (Farbe außerhalb = Turmputz)
		vec2 q = s * 2.0 - 1.0;
		float r = length(q);
		float ang = atan(q.x, q.y);
		float striche = step(0.6, r) * step(r, 0.74) * step(0.96, cos(ang * 12.0));
		float zeiger = max(linie(q, vec2(0.0), 0.62 * vec2(sin(1.95), cos(1.95)), 0.06),
			linie(q, vec2(0.0), 0.42 * vec2(sin(-0.45), cos(-0.45)), 0.09));
		float ring = smoothstep(0.76, 0.8, r) * (1.0 - smoothstep(0.92, 0.96, r));
		float innen = 1.0 - smoothstep(0.94, 0.98, r);
		vec3 blatt = vec3(0.95, 0.93, 0.85);
		vec3 uhr = mix(blatt, vec3(0.08), max(striche, zeiger));
		uhr = mix(uhr, vec3(0.95, 0.72, 0.3), ring);
		c = mix(c, uhr, innen);
		metall = ring * innen * 0.7;
		leuchten = blatt * innen * (1.0 - ring) * (1.0 - zeiger) * nacht * 0.5;
	} else if (k == 11) {
		// Backstein (Frauenkirche)
		vec2 m = mauer(s, vec2(0.55, 0.22), 0.12);
		float d = deutlich(s, 0.22);
		vec3 stein = c * (0.82 + 0.34 * m.y);
		vec3 fuge = vec3(0.78, 0.72, 0.64);
		c = mix(c * 0.96, mix(fuge, stein, m.x), d) * (0.9 + 0.16 * grob);
	} else if (k == 12) {
		// Blumen (Geranien) im Kasten
		float b = hash(floor(welt.xz * 8.0 + vec2(welt.y * 8.0)));
		c = mix(vec3(0.15, 0.32, 0.1), c, step(0.4, b));
		rau = 0.85;
	} else if (k == 13) {
		// Fensterladen mit Lamellen
		float d = deutlich(s, 0.09);
		float l = fract(s.y / 0.09);
		c *= mix(0.85, 0.62 + 0.38 * smoothstep(0.0, 0.6, l), d);
	} else if (k == 14) {
		// Markise gestreift
		c = mix(vec3(0.95, 0.93, 0.88), c, step(0.5, fract(s.x / 0.45)));
		rau = 0.75;
	} else if (k == 15) {
		// Dunkle Öffnung / Schallluken
		c = vec3(0.05, 0.045, 0.04) + vec3(0.05) * step(0.5, fract(s.y / 0.28));
	} else if (k == 16) {
		// Laub und Nadeln
		c *= 0.62 + 0.55 * rauschen(welt.xz * 1.1 + vec2(welt.y * 1.4));
		rau = 0.95;
	} else if (k == 17) {
		// Balkongeländer mit Latten
		float d = deutlich(s, 0.16);
		c *= mix(0.7, mix(0.3, 1.0, step(0.38, fract(s.x / 0.16))), d);
	}

	ALBEDO = c;
	ROUGHNESS = rau;
	METALLIC = metall;
	EMISSION = leuchten;
}
