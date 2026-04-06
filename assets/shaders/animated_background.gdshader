shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.039, 0.067, 0.122, 1.0);
uniform vec4 color_mid : source_color = vec4(0.059, 0.114, 0.220, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.039, 0.086, 0.157, 1.0);
uniform float wave_speed : hint_range(0.01, 0.3) = 0.04;
uniform float wave_amplitude : hint_range(0.0, 0.2) = 0.08;

void fragment() {
	vec2 uv = UV;

	// Subtle wave distortion on the gradient
	float wave1 = sin(uv.x * 2.5 + TIME * wave_speed) * wave_amplitude * 0.08;
	float wave2 = sin(uv.x * 4.0 + TIME * wave_speed * 1.3 + 1.5) * wave_amplitude * 0.04;
	float gradient = clamp(uv.y + wave1 + wave2, 0.0, 1.0);

	// Three-stop gradient
	vec4 color;
	if (gradient < 0.45) {
		color = mix(color_top, color_mid, gradient / 0.45);
	} else {
		color = mix(color_mid, color_bottom, (gradient - 0.45) / 0.55);
	}

	// Very subtle vignette for depth
	float vignette = 1.0 - length(uv - vec2(0.5)) * 0.4;
	color.rgb *= vignette;

	COLOR = color;
}
