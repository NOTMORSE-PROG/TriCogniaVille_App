shader_type canvas_item;

// Animated water shimmer for the well.
// Caustic-like color oscillation with ripple pattern.
// GL Compatibility safe.

uniform vec3 water_deep : source_color = vec3(0.102, 0.420, 0.541);    // #1A6B8A
uniform vec3 water_mid : source_color = vec3(0.176, 0.608, 0.769);     // #2D9BC4
uniform vec3 water_light : source_color = vec3(0.357, 0.753, 0.871);   // #5BC0DE
uniform vec3 water_highlight : source_color = vec3(0.659, 0.902, 0.941); // #A8E6F0

uniform float ripple_speed : hint_range(0.0, 3.0) = 0.8;
uniform float caustic_scale : hint_range(2.0, 20.0) = 8.0;

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

	// Concentric ripples from center
	float dist = length(uv - vec2(0.5));
	float ripple = sin(dist * 25.0 - TIME * ripple_speed) * 0.5 + 0.5;

	// Caustic-like pattern from overlapping noise
	float c1 = value_noise(uv * caustic_scale + vec2(TIME * 0.3, TIME * 0.2));
	float c2 = value_noise(uv * caustic_scale * 1.3 + vec2(-TIME * 0.2, TIME * 0.35));
	float caustic = smoothstep(0.3, 0.7, (c1 + c2) * 0.5);

	// Base water color with depth (darker at edges)
	vec3 col = mix(water_deep, water_mid, 1.0 - dist * 1.5);

	// Add caustic highlights
	col = mix(col, water_light, caustic * 0.4);

	// Ripple brightening
	col = mix(col, water_highlight, ripple * 0.2 * (1.0 - dist));

	// Bright center highlight (sunlight reflection)
	float center_glow = smoothstep(0.3, 0.0, dist);
	col = mix(col, water_highlight, center_glow * 0.3 * (sin(TIME * 1.5) * 0.3 + 0.7));

	// Circular mask (water is inside the well circle)
	float circle_mask = smoothstep(0.5, 0.45, dist);

	COLOR = vec4(col, circle_mask * 0.85);
}
