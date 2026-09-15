shader_type sky;
// Himmel mit ziehenden Wolken, Abendrot und Sternen.
// Gesteuert vom GameManager (_apply_daylight): nacht 0 = Tag … 1 = Nacht,
// regen 0 … 1 = grauer, dicht bewölkter Himmel.

uniform vec3 tag_oben : source_color = vec3(0.24, 0.47, 0.86);
uniform vec3 tag_horizont : source_color = vec3(0.78, 0.85, 0.93);
uniform vec3 abend_horizont : source_color = vec3(0.98, 0.52, 0.30);
uniform vec3 nacht_oben : source_color = vec3(0.015, 0.02, 0.07);
uniform vec3 nacht_horizont : source_color = vec3(0.10, 0.07, 0.15);
uniform float nacht : hint_range(0.0, 1.0) = 0.0;
uniform float regen : hint_range(0.0, 1.0) = 0.0;
uniform float bewoelkung : hint_range(0.0, 1.0) = 0.42;
uniform float wind = 0.006;

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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * rauschen(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

// Gezackte Bergkette rundum (nahtlos über den Kreis), Ergebnis etwa 0 … 1
float kamm(float az, float freq, float versatz) {
	vec2 k = vec2(cos(az), sin(az)) * freq + versatz;
	float v = 0.0;
	float a = 0.55;
	for (int i = 0; i < 6; i++) {
		v += a * (1.0 - abs(rauschen(k) * 2.0 - 1.0));
		k *= 2.13;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	float h = clamp(d.y, -0.2, 1.0);
	// Abendrot nur in der Mitte der Dämmerung
	float abend = smoothstep(0.05, 0.45, nacht) * (1.0 - smoothstep(0.55, 0.95, nacht));
	vec3 horizont = mix(tag_horizont, nacht_horizont, nacht);
	horizont = mix(horizont, abend_horizont, abend * 0.65);
	vec3 oben = mix(tag_oben, nacht_oben, nacht);
	vec3 farbe = mix(horizont, oben, pow(max(h, 0.0), 0.55));
	if (d.y < 0.0) {
		farbe = mix(horizont, horizont * 0.35, clamp(-d.y * 4.0, 0.0, 1.0));
	}

	// Sterne (nicht bei Regen)
	float stern = step(0.9985, hash(floor(d.xz / max(d.y, 0.05) * 90.0)));
	farbe += vec3(stern) * nacht * (1.0 - regen) * smoothstep(0.1, 0.35, d.y);

	// Wolken auf einer flachen Kuppel
	if (d.y > 0.0) {
		vec2 uv = d.xz / (d.y + 0.18) * 1.4 + vec2(TIME * wind, TIME * wind * 0.35);
		float w = fbm(uv);
		float deckung = mix(bewoelkung, 0.9, regen);
		float wolke = smoothstep(1.0 - deckung, 1.0 - deckung + 0.32, w) * smoothstep(0.0, 0.2, d.y);
		vec3 wolken_farbe = mix(vec3(1.0, 0.98, 0.95), vec3(0.07, 0.07, 0.11), nacht);
		wolken_farbe = mix(wolken_farbe, abend_horizont * 0.95, abend * 0.45);
		wolken_farbe = mix(wolken_farbe, vec3(0.42, 0.44, 0.48) * (1.0 - nacht * 0.85), regen);
		farbe = mix(farbe, wolken_farbe, wolke * 0.92);
	}

	// Alpenkette am Horizont (im Süden höher) und bewaldete Vorberge davor —
	// hinter der Altstadt-Kulisse (scenes/kulisse/altstadt.tscn)
	float flach = max(length(d.xz), 0.0001);
	float el = d.y / flach;
	float az = atan(d.x, d.z);
	float sued = smoothstep(-0.3, 0.9, -d.z / flach);
	if (el < 0.2) {
		float kamm_a = kamm(az, 2.6, 11.0);
		float hA = 0.012 + mix(0.03, 0.105, sued) * pow(kamm_a, 1.7);
		if (el < hA) {
			float steig = kamm(az + 0.003, 2.6, 11.0) - kamm_a;
			float rinnen = rauschen(vec2(az * 160.0, el * 70.0));
			vec3 fels = vec3(0.42, 0.46, 0.55) * (0.85 + clamp(steig * 40.0, -0.3, 0.3)) * (0.88 + 0.2 * rinnen);
			float schnee = smoothstep(0.052, 0.062, el + (rinnen - 0.5) * 0.02) * smoothstep(0.0, 0.01, hA - el + 0.01);
			vec3 berg = mix(fels, vec3(0.93, 0.95, 1.0) * (0.88 + clamp(steig * 25.0, -0.18, 0.12)), schnee);
			berg = mix(berg, horizont, 0.42 + 0.4 * (1.0 - smoothstep(0.0, 0.05, el)));
			berg = mix(berg, nacht_horizont * 0.8, nacht * 0.8);
			farbe = mix(farbe, berg, smoothstep(hA, hA - 0.0015, el));
		}
		float hB = 0.004 + 0.028 * pow(kamm(az, 6.0, 3.0), 1.3);
		if (el < hB) {
			vec3 wald = vec3(0.2, 0.28, 0.27) * (0.9 + 0.15 * rauschen(vec2(az * 90.0, el * 40.0)));
			wald = mix(wald, horizont, 0.5);
			wald = mix(wald, nacht_horizont * 0.6, nacht * 0.85);
			farbe = mix(farbe, wald, smoothstep(hB, hB - 0.0015, el));
		}
	}

	// Regen macht alles grauer
	farbe = mix(farbe, vec3(dot(farbe, vec3(0.33))) * 0.65, regen * 0.7);
	COLOR = farbe;
}
