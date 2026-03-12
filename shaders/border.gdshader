shader_type canvas_item;

uniform sampler2D province_texture;
uniform float border_width : hint_range(0.05, 5.0) = 1.0;
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);

void fragment() {
    vec2 px = vec2(border_width) / vec2(textureSize(province_texture, 0));
	///vec2 px = vec2(border_width) / vec2(4096,4096);

    vec4 col   = texture(province_texture, UV);
    vec4 right = texture(province_texture, UV + vec2(px.x, 0.0));
    vec4 left  = texture(province_texture, UV - vec2(px.x, 0.0));
    vec4 down  = texture(province_texture, UV + vec2(0.0, px.y));
    vec4 up    = texture(province_texture, UV - vec2(0.0, px.y));

    float is_owned    = step(0.01, col.a);
    float right_owned = step(0.01, right.a);
    float left_owned  = step(0.01, left.a);
    float down_owned  = step(0.01, down.a);
    float up_owned    = step(0.01, up.a);

    float is_border = clamp(
        step(0.01, length(col.rgb - right.rgb)) * right_owned +
        step(0.01, length(col.rgb - left.rgb))  * left_owned  +
        step(0.01, length(col.rgb - down.rgb))  * down_owned  +
        step(0.01, length(col.rgb - up.rgb))    * up_owned,
        0.0, 1.0) * is_owned;

    COLOR = mix(vec4(0.0), border_color, is_border);
}