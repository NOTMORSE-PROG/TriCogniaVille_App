shader_type canvas_item;

// Procedural dirt path shader for TriCognia Ville village.
// Adds grain/speckle texture and organic edge softening to path ColorRects.
// GL Compatibility safe (no advanced features).

uniform vec3 base_color : source_color = vec3(0.769, 0.506, 0.102);   // #C4811A
uniform vec3 dark_speck : source_color = vec3(0.541, 0.353, 0.063);   // #8A5A10
uniform vec3 light_speck : source_color = vec3(0.925, 0.675, 0.133);  // #ECAC22

uniform float grain_scale : hint_range(20.0, 300.0) = 120.0;
uniform float speck_scale : hint_range(40.0, 400.0) = 200.0;
uniform float grain_intensity : hint_range(0.0, 0.5) = 0.18;
uniform float edge_softness : hint_range(0.0, 0.15) = 0.06;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;

	// Grain texture — fine dirt particles
	float grain = value_noise(uv * grain_scale);

	// Larger speckles — pebbles and variations
	float speck = value_noise(uv * speck_scale + vec2(42.0, 17.0));

	// Base dirt color with grain variation
	vec3 col = base_color;

	// Dark grain (shadows between dirt particles)
	col = mix(col, dark_speck, smoothstep(0.35, 0.55, grain) * grain_intensity);

	// Light speckles (small stones catching light)
	col = mix(col, light_speck, smoothstep(0.72, 0.88, speck) * grain_intensity * 0.8);

	// Very fine noise overlay for texture
	float fine = hash(uv * 500.0);
	col += (fine - 0.5) * 0.04;

	// Edge softening — fade alpha near rect edges for organic look
	float edge_x = min(uv.x, 1.0 - uv.x);
	float edge_y = min(uv.y, 1.0 - uv.y);
	float edge = min(edge_x, edge_y);
	float alpha = smoothstep(0.0, edge_softness, edge);

	// Subtle worn-center brightening (paths are lighter where walked most)
	float center_dist = length(uv - vec2(0.5));
	col = mix(col, light_speck, (1.0 - smoothstep(0.0, 0.45, center_dist)) * 0.08);

	COLOR = vec4(col, alpha * COLOR.a);
}
