shader_type canvas_item;

uniform vec4 aura_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 center_offset = vec2(0.0, 0.0);
uniform float outer_radius = 0.55;
uniform float falloff_power = 1.55;
uniform float intensity = 1.0;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5) - center_offset;
	float dist_norm = clamp(length(centered_uv) / max(outer_radius, 0.001), 0.0, 1.0);
	float glow = pow(1.0 - dist_norm, falloff_power);
	float alpha = clamp(glow * intensity * aura_color.a, 0.0, 1.0);
	COLOR = vec4(aura_color.rgb, alpha);
}
