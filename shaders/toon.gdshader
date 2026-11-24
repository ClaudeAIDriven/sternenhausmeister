shader_type spatial;
render_mode diffuse_toon, specular_disabled;
// Toon/Cel-Look mit Kantenlicht (A-01). Läuft im Compatibility-Renderer (nur einfache Eingaben).
// Nutzung: ShaderMaterial.shader = load("res://shaders/toon.gdshader"), Parameter albedo setzen.

uniform vec4 albedo : source_color = vec4(0.3, 0.55, 0.9, 1.0);
uniform vec4 shade_color : source_color = vec4(0.12, 0.15, 0.4, 1.0); // Farbe der dunklen Stufen
uniform int steps : hint_range(2, 3) = 3;
uniform vec4 rim_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.6;
uniform float emission_strength : hint_range(0.0, 4.0) = 0.0; // z. B. für leuchtende Sterne

void fragment() {
	ALBEDO = albedo.rgb;
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	// harte Kante statt weichem Verlauf
	rim = smoothstep(0.25, 0.32, rim) * rim_strength;
	EMISSION = rim_color.rgb * rim + albedo.rgb * emission_strength;
}

void light() {
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	float lit;
	if (steps == 2) {
		lit = step(0.35, ndl);
	} else {
		lit = step(0.15, ndl) * 0.4 + step(0.55, ndl) * 0.6;
	}
	vec3 col = mix(shade_color.rgb, albedo.rgb, lit);
	DIFFUSE_LIGHT += col * LIGHT_COLOR / PI * lit + shade_color.rgb * 0.0;
}
