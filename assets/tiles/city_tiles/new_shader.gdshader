shader_type canvas_item;

uniform float time_scale : hint_range(0.0, 5.0) = 1.0;
uniform float water_speed : hint_range(0.0, 2.0) = 0.4;
uniform float water_distort : hint_range(0.0, 0.1) = 0.02;
uniform vec4 water_tint : source_color = vec4(0.1, 0.3, 0.6, 1.0);
uniform vec4 land_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform float contrast : hint_range(0.5, 2.0) = 1.1;

void fragment() {
    float t = TIME * time_scale;

    // --- water UV distortion ---
    vec2 uv = UV;
    vec2 distorted_uv = uv + vec2(
        sin(uv.y * 20.0 + t * water_speed) * water_distort,
        cos(uv.x * 20.0 + t * water_speed) * water_distort
    );

    // sample both: original and distorted
    vec4 original = texture(TEXTURE, uv);
    vec4 distorted = texture(TEXTURE, distorted_uv);

    // detect water by blue dominance
    float is_water = step(0.0, distorted.b - max(distorted.r, distorted.g) - 0.05);

    // blend distorted sample + tint on water, leave land alone
    vec4 col = mix(original * land_tint, distorted * water_tint, is_water);

    // --- contrast ---
    col.rgb = (col.rgb - 0.5) * contrast + 0.5;

    // --- vignette ---
    vec2 centered = UV - 0.5;
    float vignette = 1.0 - dot(centered, centered) * vignette_strength * 4.0;
    col.rgb *= clamp(vignette, 0.0, 1.0);

    COLOR = col;
}
//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
