shader_type canvas_item;

// Fill all non-zero alpha pixels with brown (for logbook display)
uniform vec4 tint : source_color = vec4(0.29, 0.2, 0.13, 1.0);

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(tint.rgb, a * tint.a);
}
