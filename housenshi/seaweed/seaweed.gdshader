shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform float sway_speed     = 1.5;
uniform float sway_strength  = 0.08;
uniform float sway_frequency = 2.0;
uniform sampler2D seaweed_texture : source_color, filter_linear_mipmap, repeat_enable;

// --- Underwater depth effect ---
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float water_surface_y   = 0.0;   // match your water plane's Y position in world
uniform float depth_distance    = 4.0;   // match your water shader's depth_distance
uniform float beers_law         = 12.0;  // match your water shader's beers_law
uniform vec4  secondary_color : source_color; // match your water's deep/secondary color

const float Y_MIN = -1.115;
const float Y_MAX =  1.184;

void vertex() {
    float height_factor = clamp((VERTEX.y - Y_MIN) / (Y_MAX - Y_MIN), 0.0, 1.0);
    float time_offset   = VERTEX.x * sway_frequency;
    float sway          = sin(TIME * sway_speed + time_offset) * sway_strength;
    VERTEX.x += sway * height_factor;
    VERTEX.z += sway * 0.5 * height_factor;
}

void fragment() {
    vec4 tex = texture(seaweed_texture, UV);

    // How deep is this fragment below the water surface?
    float frag_world_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
    float depth_below  = clamp((water_surface_y - frag_world_y) / depth_distance, 0.0, 1.0);

    // Same Beer's Law curve your water uses
    float depth_blend  = exp(-depth_below * beers_law);

    // Tint seaweed toward the deep water color the deeper it is
    vec3 tinted = mix(secondary_color.rgb, tex.rgb, depth_blend);

    // Extra darkness + slight blue-green cast at depth
    float darkness = mix(0.25, 1.0, depth_blend);
    tinted *= darkness;

    ALBEDO = tinted;
    ALPHA  = tex.a;
}