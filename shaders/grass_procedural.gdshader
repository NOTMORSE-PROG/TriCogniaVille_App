shader_type canvas_item;

// Procedural animated grass shader for TriCognia Ville village ground plane.
// Creates a lush, Stardew Valley-inspired grass texture with wind animation.
// Designed for GL Compatibility renderer (mobile-safe: 2 noise octaves max).

uniform vec3 color_dark   : source_color = vec3(0.177, 0.478, 0.082);   // #2D7A15
uniform vec3 color_mid    : source_color = vec3(0.239, 0.596, 0.082);   // #3D9815
uniform vec3 color_light  : source_color = vec3(0.302, 0.722, 0.165);   // #4DB82A
uniform vec3 color_bright : source_color = vec3(0.439, 0.780, 0.145);   // #70C725

uniform float wind_speed : hint_range(0.0, 2.0) = 0.4;
uniform float wind_strength : hint_range(0.0, 0.05) = 0.012;
uniform float noise_scale : hint_range(5.0, 80.0) = 28.0;
uniform float detail_scale : hint_range(20.0, 200.0) = 85.0;
uniform float blade_scale : hint_range(50.0, 400.0) = 180.0;

// Simple hash-based noise (no texture dependency, GL Compatibility safe)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Value noise with smooth interpolation
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 2-octave fractal noise
float fbm(vec2 p) {
	float v = 0.0;
	v += value_noise(p) * 0.65;
	v += value_noise(p * 2.1 + vec2(17.0, 31.0)) * 0.35;
	return v;
}

void fragment() {
	vec2 uv = UV;

	// Wind distortion — shifts UV over time for gentle movement
	float wind_offset = sin(TIME * wind_speed + uv.x * 8.0 + uv.y * 3.0) * wind_strength;
	vec2 wind_uv = uv + vec2(wind_offset, wind_offset * 0.5);

	// Layer 1: Large-scale color variation (patches of light/dark grass)
	float n1 = fbm(wind_uv * noise_scale);

	// Layer 2: Medium detail (individual grass clump shapes)
	float n2 = value_noise(wind_uv * detail_scale + vec2(50.0, 80.0));

	// Layer 3: Fine blade-like pattern (directional stretching)
	vec2 blade_uv = wind_uv * blade_scale;
	blade_uv.y *= 2.5; // stretch vertically for blade-like feel
	float n3 = value_noise(blade_uv + vec2(TIME * wind_speed * 0.3, 0.0));

	// Combine layers: large patches set base tone, detail adds texture
	float base_mix = smoothstep(0.3, 0.7, n1);
	vec3 base_color = mix(color_dark, color_mid, base_mix);

	// Add lighter highlights in bright patches
	float highlight = smoothstep(0.55, 0.80, n1) * smoothstep(0.4, 0.7, n2);
	base_color = mix(base_color, color_light, highlight * 0.7);

	// Add bright blade tips
	float blade_tip = smoothstep(0.6, 0.85, n3) * smoothstep(0.45, 0.65, n1);
	base_color = mix(base_color, color_bright, blade_tip * 0.4);

	// Subtle darkening in "valleys" between grass clumps
	float valley = 1.0 - smoothstep(0.2, 0.5, n2) * 0.15;
	base_color *= valley;

	// Very subtle warm tint variation (prevents monotone green)
	float warm = value_noise(uv * 12.0 + vec2(200.0, 100.0));
	base_color += vec3(0.02, 0.01, -0.01) * warm;

	COLOR = vec4(base_color, 1.0);
}
