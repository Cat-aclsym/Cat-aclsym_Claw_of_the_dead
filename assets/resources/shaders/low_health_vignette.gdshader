shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 1.5;
uniform float noise_speed : hint_range(0.0, 10.0) = 3.0;
uniform float edge_width : hint_range(0.0, 0.5) = 0.12;
uniform vec4 base_color : source_color = vec4(0.8, 0.1, 0.1, 0.8);

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
	// Increased resolution for smoother but still pixelated look
	vec2 pixel_uv = floor(uv * 256.0) / 256.0; 
	float n = hash(pixel_uv + floor(TIME * noise_speed));
	
	// Pulse effect - reduced amplitude and speed for more fluidity
	float pulse = 0.5 + 0.25 * sin(TIME * pulse_speed);
	
	// Combine distance, noise, and intensity
	float alpha = smoothstep(edge_width, 0.0, edge_dist);
	alpha *= (0.7 + 0.3 * n); // Less aggressive noise
	alpha *= intensity * pulse;
	
	// Ensure center is clear with a smoother transition
	float center_mask = smoothstep(0.0, edge_width * 1.5, edge_dist);
	alpha *= (1.0 - center_mask * 0.7); 
	
	COLOR = vec4(base_color.rgb, alpha * base_color.a);
}
