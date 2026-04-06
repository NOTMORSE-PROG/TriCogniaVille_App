shader_type canvas_item;

uniform float particle_count : hint_range(5.0, 25.0) = 12.0;
uniform float particle_size : hint_range(0.005, 0.04) = 0.015;
uniform float speed : hint_range(0.01, 0.15) = 0.03;
uniform vec4 particle_color : source_color = vec4(0.392, 0.769, 0.910, 0.08);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec4 color = vec4(0.0, 0.0, 0.0, 0.0);

	for (float i = 0.0; i < 25.0; i++) {
		if (i >= particle_count) break;

		vec2 seed = vec2(i * 0.137, i * 0.491);
		float px = hash(seed);
		float py = fract(hash(seed + 1.0) + TIME * speed * (0.3 + hash(seed + 2.0) * 0.7));
		float sz = particle_size * (0.5 + hash(seed + 3.0));

		float dist = length(uv - vec2(px, py));
		float alpha = smoothstep(sz, sz * 0.2, dist) * particle_color.a;

		// Gentle breathing / pulsing
		alpha *= 0.7 + 0.3 * sin(TIME * 0.8 + i * 1.5);

		color = mix(color, vec4(particle_color.rgb, 1.0), alpha);
	}

	COLOR = color;
}
