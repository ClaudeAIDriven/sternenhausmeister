shader_type spatial;
render_mode diffuse_toon, specular_disabled;
// Stern-Reinigungsübergang (A-11): clean 0..1 lässt goldene saubere Stellen wachsen, bis der Stern komplett leuchtet.
// Nur einfache Eingaben, läuft im Compatibility-Renderer. Ein Basismodell für alle Zustände (0/25/50/75/100 %).

uniform float clean : hint_range(0.0, 1.0) = 0.0;
uniform vec4 dirt_color : source_color = vec4(0.467, 0.482, 0.514, 1.0);   // Palette.DIRT_GRAY
uniform vec4 gold_color : source_color = vec4(1.0, 0.831, 0.467, 1.0);     // Palette.STAR_GOLD
uniform vec4 rim_color : source_color = vec4(1.0, 0.8, 0.45, 1.0);   // goldener Randschimmer (kein Weiß, sonst überstrahlt es)
uniform float noise_scale : hint_range(0.5, 6.0) = 2.2;
uniform float edge_width : hint_range(0.01, 0.2) = 0.06;
uniform float glow_max : hint_range(0.0, 4.0) = 0.0;   // Zusatz-Leuchten, 0 = aus (Standard); Bloom regelt die Umgebung
uniform bool use_overlays = false;
uniform sampler2D dirt_soot : source_color, filter_linear;
uniform sampler2D dirt_stain : source_color, filter_linear;
uniform sampler2D dirt_patina : source_color, filter_linear;

varying vec3 lpos;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x),
				   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
				   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	lpos = VERTEX;
}

void fragment() {
	vec3 p = normalize(lpos) * noise_scale;
	float n = vnoise(p) * 0.65 + vnoise(p * 2.3) * 0.35;           // 0..1, Reihenfolge, in der Stellen sauber werden
	float t = clean * (1.0 + edge_width * 2.0) - edge_width;       // 0 -> komplett schmutzig, 1 -> komplett sauber
	float m = smoothstep(n - edge_width, n + edge_width, t);        // 1 = sauber
	float edge = (1.0 - abs(m * 2.0 - 1.0));                        // Leuchtband am Übergang
	// Schmutzige Seite: mattes Grau mit weichen dunkleren Wolken, optional Overlays (Ruß/Flecken/Patina)
	vec3 dirty = dirt_color.rgb * (0.82 + 0.3 * vnoise(p * 3.1));
	if (use_overlays) {
		vec2 uv = UV * vec2(2.0, 1.0);
		vec4 a = texture(dirt_soot, uv);
		vec4 b = texture(dirt_stain, uv * 1.3 + 0.17);
		vec4 c = texture(dirt_patina, uv * 1.1 + 0.41);
		dirty = mix(dirty, a.rgb, a.a);
		dirty = mix(dirty, b.rgb, b.a);
		dirty = mix(dirty, c.rgb, c.a);
	}
	// Saubere Seite: warmes Gold mit leichter Aufhellung zur Mitte
	vec3 golden = gold_color.rgb * (0.78 + 0.2 * vnoise(p * 1.7));
	ALBEDO = mix(dirty, golden * 0.45, m);   // sauber: Farbe kommt über die Emission, damit bläuliches Umgebungslicht das Gold nicht entsättigt
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	rim = smoothstep(0.35, 0.5, rim) * (0.1 + 0.35 * clean);
	vec3 glow = gold_color.rgb * m * (0.3 * clean + 0.4 * clean * clean) * (1.0 + glow_max) * (0.92 + 0.08 * vnoise(p * 1.7)) + rim_color.rgb * rim + rim_color.rgb * edge * 0.7 * step(0.001, clean) * (1.0 - step(0.999, clean));
	EMISSION = glow;
}
