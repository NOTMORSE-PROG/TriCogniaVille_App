shader_type canvas_item;

// Gentle foliage sway shader for tree canopy panels.
// Creates wind-blown movement + dappled light effect.
// GL Compatibility safe.

uniform float sway_amount : hint_range(0.0, 8.0) = 2.5;
uniform float sway_speed : hint_range(0.0, 4.0) = 1.2;
uniform float dapple_intensity : hint_range(0.0, 0.3) = 0.08;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	// Sway the upper portion of the canopy — bottom stays anchored
	float height_factor = 1.0 - UV.y; // 1 at top, 0 at bottom
	float sway = sin(TIME * sway_speed + VERTEX.x * 0.02) * sway_amount * height_factor;
	VERTEX.x += sway;
	VERTEX.y += sin(TIME * sway_speed * 0.7 + VERTEX.y * 0.03) * sway_amount * 0.3 * height_factor;
}

void fragment() {
	// Dappled light: slow-shifting bright spots on foliage
	vec2 dapple_uv = UV * 4.0 + vec2(TIME * 0.15, TIME * 0.1);
	float dapple = hash(floor(dapple_uv));
	dapple = smoothstep(0.6, 0.9, dapple) * dapple_intensity;

	COLOR.rgb += dapple;
	COLOR.a = COLOR.a;
}
