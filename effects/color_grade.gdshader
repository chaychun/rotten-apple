shader_type canvas_item;

// Color grade applied to the whole rendered frame via the SubViewportContainer,
// so it affects transparent geometry (foliage) too — unlike the in-world outline
// quad, which only sees the opaque pass. Posterize + ordered dither + saturation.

// Colour bands per channel. Lower = flatter, fewer colours, more low-poly/retro.
uniform float color_levels : hint_range(1, 32, 1) = 32.0;

// Overall vibrancy. 1 = unchanged, <1 = muted/washed, 0 = greyscale.
uniform float saturation : hint_range(0, 2, 0.01) = 1;

// PS1-style ordered (Bayer) dithering applied before posterize. 0 = off.
uniform float dither_amount : hint_range(0, 1, 0.01) = 1.0;

const float bayer4[16] = float[](
	 0.0,  8.0,  2.0, 10.0,
	12.0,  4.0, 14.0,  6.0,
	 3.0, 11.0,  1.0,  9.0,
	15.0,  7.0, 13.0,  5.0
);

void fragment() {
	vec3 col = texture(TEXTURE, UV).rgb;

	// Lower vibrancy: pull colours toward their luma.
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(luma), col, saturation);

	// Dither at the source (low-res) pixel grid, not the upscaled screen.
	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	ivec2 px = ivec2(UV * tex_size);
	float threshold = (bayer4[(px.x & 3) + (px.y & 3) * 4] + 0.5) / 16.0 - 0.5;

	float steps = max(color_levels - 1.0, 1.0);
	col += threshold / steps * dither_amount;

	// Posterize to flat colour bands.
	col = round(col * steps) / steps;

	COLOR = vec4(col, 1.0);
}
