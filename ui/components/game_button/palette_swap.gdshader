// © [2026] A7 Studio. All rights reserved. Trademark.
//
// Recolors the grey button bases: the red channel stores a level (0 outline, 1 shadow, 2 body, 3 highlight, ...), the palette texture has one column
// per level and one row per GameButton.Palette. Alpha comes from the base, the vertex color (modulate) is kept.
shader_type canvas_item;

uniform sampler2D palette : filter_nearest, repeat_disable;
uniform int palette_row = 0;
uniform float brightness = 1.0;
uniform float saturation = 1.0;

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	int level = int(round(base.r * 255.0));
	vec3 color = texelFetch(palette, ivec2(level, palette_row), 0).rgb;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(grey), color, saturation) * brightness, base.a) * modulate;
}
