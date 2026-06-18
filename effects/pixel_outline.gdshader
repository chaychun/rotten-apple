shader_type spatial;
render_mode unshaded;

// Fullscreen post-process: pixelizes the screen (UV quantization) and draws
// depth/normal edge outlines. Adapted from CBerry22/3d-Pixel-Art-In-Godot-4.
// Lives on a 2x2 QuadMesh parented to the camera; vertex() forces it fullscreen.

uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_nearest;

// Screen pixels per art-pixel block. Higher = chunkier. Also sets outline width.
uniform float pixel_size = 8.0;

uniform float depth_threshold : hint_range(0, 1) = 0.05;
uniform float reverse_depth_threshold : hint_range(0, 1) = 0.25;
uniform float normal_threshold : hint_range(0, 1) = 0.6;

uniform float darken_amount : hint_range(0, 1, 0.01) = 0.3;
uniform float lighten_amount : hint_range(0, 10, 0.01) = 1.5;

uniform vec3 normal_edge_bias = vec3(1, 1, 1);
uniform vec3 light_direction = vec3(-0.96, -0.18, 0.2);

// NOTE: colour grading (posterize / dither / saturation) lives on the
// SubViewportContainer (effects/color_grade.gdshader) so it covers transparent
// geometry too. This shader only does pixelation + outlines.

float get_depth(vec2 uv, mat4 inv_projection_matrix) {
	float depth = texture(depth_texture, uv).r;
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	// One art-pixel block measured in UV space. Drives both the pixel grid and
	// the neighbour offset for edge detection, so outlines match the pixel size.
	vec2 texel_size = pixel_size / VIEWPORT_SIZE.xy;
	// Snap to the block centre so every screen pixel in a block reads the same source.
	vec2 uv = (floor(SCREEN_UV / texel_size) + 0.5) * texel_size;

	float depth = get_depth(uv, INV_PROJECTION_MATRIX);
	vec3 normal = texture(normal_texture, uv).xyz * 2.0 - 1.0;

	vec2 uvs[4];
	uvs[0] = vec2(uv.x, min(1.0 - 0.001, uv.y + texel_size.y));
	uvs[1] = vec2(uv.x, max(0.0, uv.y - texel_size.y));
	uvs[2] = vec2(min(1.0 - 0.001, uv.x + texel_size.x), uv.y);
	uvs[3] = vec2(max(0.0, uv.x - texel_size.x), uv.y);

	float depth_diff = 0.0;
	float depth_diff_reversed = 0.0;
	float nearest_depth = depth;
	vec2 nearest_uv = uv;

	float normal_sum = 0.0;
	for (int i = 0; i < 4; i++) {
		float d = get_depth(uvs[i], INV_PROJECTION_MATRIX);
		depth_diff += depth - d;
		depth_diff_reversed += d - depth;

		if (d < nearest_depth) {
			nearest_depth = d;
			nearest_uv = uvs[i];
		}

		vec3 n = texture(normal_texture, uvs[i]).xyz * 2.0 - 1.0;
		vec3 normal_diff = normal - n;

		// Edge pixels should yield to the normal closest to the bias direction.
		float normal_bias_diff = dot(normal_diff, normal_edge_bias);
		float normal_indicator = smoothstep(-0.01, 0.01, normal_bias_diff);

		normal_sum += dot(normal_diff, normal_diff) * normal_indicator;
	}
	float depth_edge = step(depth_threshold, depth_diff);

	// Reverse depth masks the normal edge so it only draws on the outside silhouette.
	float reverse_depth_edge = step(reverse_depth_threshold, depth_diff_reversed);

	float indicator = sqrt(normal_sum);
	float normal_edge = step(normal_threshold, indicator - reverse_depth_edge);

	vec3 original = texture(screen_texture, uv).rgb;
	vec3 nearest = texture(screen_texture, nearest_uv).rgb;

	mat3 view_to_world_normal_mat = mat3(
			INV_VIEW_MATRIX[0].xyz,
			INV_VIEW_MATRIX[1].xyz,
			INV_VIEW_MATRIX[2].xyz
	);
	float ld = dot((view_to_world_normal_mat * normal), normalize(light_direction));

	vec3 depth_col = nearest * darken_amount;
	vec3 normal_col = original * (ld > 0.0 ? darken_amount : lighten_amount);
	vec3 edge_mix = mix(normal_col, depth_col, depth_edge);

	ALBEDO = mix(original, edge_mix, (depth_edge > 0.0 ? depth_edge : normal_edge));
}
