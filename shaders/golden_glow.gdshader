// TriCognia Ville — Golden Glow Shader
// Adds a pulsing gold overlay on top of the building sprite.
// Used during the tier-8 celebration finale.
//
// glow_amount: 0.0 = no effect, 1.0 = full gold pulse
// Tween glow_amount 0→0.8 on celebration start, 0.8→0 on dismiss.

shader_type canvas_item;

uniform float glow_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float pulse = sin(TIME * 3.0) * 0.5 + 0.5;  // 0..1 oscillation at 3 Hz
	vec3 gold = vec3(0.95, 0.80, 0.25);
	// Mix base color toward gold proportionally to glow_amount * pulse
	vec3 col = mix(tex.rgb, gold, glow_amount * pulse * 0.38);
	// Boost overall brightness slightly at peak glow
	col += glow_amount * pulse * 0.06;
	COLOR.rgb = col;
	COLOR.a = tex.a;
}
