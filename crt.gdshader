shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float curvature         : hint_range(3.0, 10.0)  = 0.08;
uniform float scanline_strength : hint_range(0.0, 1.0)  = 0.12;
uniform float aberration        : hint_range(0.0, 0.01) = 0.002;
uniform float vignette_strength : hint_range(0.0, 2.0)  = 1.2;
uniform float brightness        : hint_range(0.5, 2.0)  = 1.1;

//uniform float pix_x        : hint_range(10.0, 1000.0)  = 100;
//uniform float pix_y        : hint_range(10.0, 1000.0)  = 100;

void fragment() {
    // curve the UV
    vec2 uv = SCREEN_UV * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(curvature);
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;

    // inside mask — 1 inside screen, 0 outside
    float inside = step(0.0, uv.x) * step(uv.x, 1.0)
                 * step(0.0, uv.y) * step(uv.y, 1.0);

    // safe uv — clamp so texture sample never goes out of bounds
    vec2 safe_uv = clamp(uv, 0.0, 1.0);

    // chromatic aberration
    float r = texture(screen_texture, safe_uv + vec2(aberration, 0.0)).r;
    float g = texture(screen_texture, safe_uv).g;
    float b = texture(screen_texture, safe_uv - vec2(aberration, 0.0)).b;
    vec4 col = vec4(r, g, b, 1.0);

    // scanlines
    col.rgb -= sin(safe_uv.y * 800.0) * scanline_strength;

    // vignette
    vec2 centered = safe_uv - 0.5;
    col.rgb *= clamp(1.0 - dot(centered, centered) * vignette_strength, 0.0, 1.0);

    // brightness
    col.rgb *= brightness;
	//
	// pixel grid
	//float grid_x = step(0.55, fract(safe_uv.x * pix_x));
	//float grid_y = step(0.55, fract(safe_uv.y * pix_y));
	//float grid   = max(grid_x, grid_y);
	//col.rgb *= 1.0 - grid * 0.5;
    // black outside curved edges
    COLOR = mix(vec4(0.0, 0.0, 0.0, 1.0), col, inside);
}