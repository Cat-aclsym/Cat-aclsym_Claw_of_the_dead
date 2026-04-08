shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float noise_speed : hint_range(0.0, 10.0) = 5.0;
uniform float edge_width : hint_range(0.0, 0.5) = 0.15;
uniform vec4 base_color : source_color = vec4(0.8, 0.1, 0.1, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Distance from edges
	float dist_x = min(uv.x, 1.0 - uv.x);
	float dist_y = min(uv.y, 1.0 - uv.y);
	float edge_dist = min(dist_x, dist_y);
	
	// Create pixelated noise for the "organic/irregular" feel
	vec2 pixel_uv = floor(uv * 128.0) / 128.0; // Pixelate the noise
	float n = hash(pixel_uv + floor(TIME * noise_speed));
	
	// Pulse effect
	float pulse = 0.7 + 0.3 * sin(TIME * pulse_speed);
	
	// Combine distance, noise, and intensity
	float alpha = smoothstep(edge_width, 0.0, edge_dist);
	alpha *= (0.6 + 0.4 * n); // Add texture/noise
	alpha *= intensity * pulse;
	
	// Ensure center is clear
	float center_mask = smoothstep(0.0, edge_width * 2.0, edge_dist);
	alpha *= (1.0 - center_mask * 0.5); // Subtly fade towards center
	
	COLOR = vec4(base_color.rgb, alpha * base_color.a);
}
