shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 16.0) = 8.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.5;
uniform float scanline_speed : hint_range(0.0, 5.0) = 1.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.5;
uniform float contrast : hint_range(0.5, 2.0) = 0.5;
uniform vec4 color_tint : source_color = vec4(1.0, 0.95, 0.85, 1.0);

void fragment() {
    // --- pixelation ---
    vec2 uv = UV;
    vec2 grid = floor(uv / (pixel_size * TEXTURE_PIXEL_SIZE)) * (pixel_size * TEXTURE_PIXEL_SIZE);
    vec4 col = texture(TEXTURE, grid);

    // --- color tint + contrast ---
    col.rgb = (col.rgb - 0.5) * contrast + 0.5;
    col.rgb *= color_tint.rgb;

    // --- scanlines ---
    float scan = sin(uv.y / TEXTURE_PIXEL_SIZE.y * 3.14159) * scanline_strength;
    col.rgb -= scan;

    // --- vignette ---
    vec2 centered = uv - 0.5;
    float vignette = 1.0 - dot(centered, centered) * vignette_strength * 4.0;
    col.rgb *= clamp(vignette, 0.0, 1.0);

    COLOR = col;
}