// TriCognia Ville — Building Unlock Shader (Enhanced)
// Grayscale-to-color transition + breathing shimmer + base ambient occlusion.
//
// color_amount: 0.0 = fully grayscale (locked), 1.0 = full color (unlocked)
// Tween color_amount 0→1 over 1.5s for the "restoration" reveal animation.
//
// CRITICAL: Assign a NEW ShaderMaterial instance per building.
// Never share one ShaderMaterial across multiple buildings.

shader_type canvas_item;

uniform float color_amount : hint_range(0.0, 1.0) = 1.0;
// glow_amount: 0.0 = no celebration glow (default), 0.0–1.0 set by TownCelebration.
uniform float glow_amount : hint_range(0.0, 1.0) = 0.0;
// flash_amount: momentary white flash during unlock cutscene peak.
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Perceptual luminance (ITU-R BT.601)
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 gray = vec3(luma);

	// Mix: 0=fully gray, 1=full color
	vec3 col = mix(gray, tex.rgb, color_amount);

	// Subtle breathing shimmer when unlocked (very gentle brightness pulse)
	float breathe = sin(TIME * 1.8) * 0.5 + 0.5;  // 0..1 oscillation
	float shimmer = breathe * 0.03 * color_amount;  // only active when colorized
	col += shimmer;

	// Warm ambient occlusion at building base (darken bottom 18%)
	float ao = smoothstep(0.82, 1.0, UV.y) * 0.18;
	col *= (1.0 - ao);

	// Slight vignette darkening at sprite edges for depth
	float edge_dist = length(UV - vec2(0.5)) * 1.2;
	float edge_darken = smoothstep(0.5, 0.9, edge_dist) * 0.08 * color_amount;
	col *= (1.0 - edge_darken);

	// Celebration golden glow — pulsing gold overlay (default off: glow_amount=0.0)
	float gold_pulse = sin(TIME * 3.0) * 0.5 + 0.5;
	vec3 gold = vec3(0.95, 0.80, 0.25);
	col = mix(col, gold, glow_amount * gold_pulse * 0.38);
	col += glow_amount * gold_pulse * 0.06;

	// White flash overlay (momentary during unlock cutscene)
	col = mix(col, vec3(1.0), flash_amount * 0.7);

	COLOR.rgb = col;
	COLOR.a = tex.a;
}
