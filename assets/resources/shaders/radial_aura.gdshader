shader_type canvas_item;

uniform vec4 aura_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 center_offset = vec2(0.0, 0.0);
uniform float outer_radius = 0.55;
uniform float falloff_power = 1.55;
uniform float intensity = 1.0;
uniform float ray_count = 14.0;
uniform float ray_rotation_speed = 0.55;
uniform float ray_length_strength = 0.28;
uniform float ray_sharpness = 3.5;
uniform float ray_pulse_speed = 2.2;
uniform float ray_pulse_amount = 0.2;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5) - center_offset;
	float angle = atan(centered_uv.y, centered_uv.x);
	float radius = length(centered_uv);

	float rotating_angle = angle + TIME * ray_rotation_speed;
	float ray_wave = max(0.0, sin(rotating_angle * ray_count));
	float ray_mask = pow(ray_wave, ray_sharpness);
	float pulse_phase = 0.5 + 0.5 * sin(TIME * ray_pulse_speed);
	float pulse = 1.0 - pulse_phase * ray_pulse_amount;
	float dynamic_radius = outer_radius * pulse * (1.0 + ray_mask * ray_length_strength);

	float dist_norm = clamp(radius / max(dynamic_radius, 0.001), 0.0, 1.0);
	float glow = pow(1.0 - dist_norm, falloff_power);
	float alpha = clamp(glow * intensity * aura_color.a, 0.0, 1.0);
	COLOR = vec4(aura_color.rgb, alpha);
}
