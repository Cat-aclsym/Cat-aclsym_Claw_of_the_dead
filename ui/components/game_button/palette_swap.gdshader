// © [2026] A7 Studio. All rights reserved. Trademark.
//
// Recolors the grey button bases: the red channel stores a level (0 outline, 1 shadow, 2 body, 3 highlight, ...), the palette texture has one column
// per level and one row per GameButton.Palette. Alpha comes from the base, the vertex color (modulate) is kept.
// rainbow: a diagonal hue wave and a white shine over the colored levels, each keeps its HSV value so the pixel shading stays.
shader_type canvas_item;

uniform sampler2D palette : filter_nearest, repeat_disable;
uniform int palette_row = 0;
uniform float brightness = 1.0;
uniform float saturation = 1.0;
uniform bool rainbow = false;

// TIME follows Engine.time_scale: at the x3 of the fast forward button, one hue cycle lasts 1 s and one shine 2 s on screen.
const float RAINBOW_CYCLE = 3.0;
// Base pixels per hue cycle along the diagonal.
const float RAINBOW_WAVELENGTH = 96.0;
const float RAINBOW_MIN_SATURATION = 0.6;
const float SHINE_PERIOD = 6.0;
// Diagonal distance covered by one shine, longer than the base so the shine rests between two sweeps.
const float SHINE_TRAVEL = 160.0;
const float SHINE_WIDTH = 4.0;
const float SHINE_STRENGTH = 0.6;

varying vec4 modulate;
varying vec2 pixel;

void vertex() {
	modulate = COLOR;
	pixel = VERTEX;
}

// Returns [param color] with the hue [param hue] (0 to 1), its value kept and its saturation raised to RAINBOW_MIN_SATURATION.
vec3 with_hue(vec3 color, float hue) {
	float value = max(color.r, max(color.g, color.b));
	float chroma = value - min(color.r, min(color.g, color.b));
	float color_saturation = value > 0.0 ? max(chroma / value, RAINBOW_MIN_SATURATION) : 0.0;
	vec3 pure = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return value * mix(vec3(1.0), pure, color_saturation);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	int level = int(round(base.r * 255.0));
	vec3 color = texelFetch(palette, ivec2(level, palette_row), 0).rgb;
	// The outline (0), rim (4) and ink (5) levels are the same on every palette, the rainbow keeps them so the button keeps its shape
	if (rainbow && level != 0 && level != 4 && level != 5) {
		vec2 cell = floor(pixel);
		float diagonal = cell.x + cell.y;
		color = with_hue(color, fract(TIME / RAINBOW_CYCLE - diagonal / RAINBOW_WAVELENGTH));
		float shine_start = fract(TIME / SHINE_PERIOD) * SHINE_TRAVEL - SHINE_WIDTH;
		if (diagonal >= shine_start && diagonal < shine_start + SHINE_WIDTH) {
			color = mix(color, vec3(1.0), SHINE_STRENGTH);
		}
	}
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(grey), color, saturation) * brightness, base.a) * modulate;
}
