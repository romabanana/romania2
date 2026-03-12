shader_type canvas_item;

uniform float border_width : hint_range(1.0, 5.0) = 1.0;
uniform vec4 province_border_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);
uniform vec4 state_border_color    : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec2 px = vec2(border_width) / vec2(textureSize(TEXTURE, 0));

    vec4 col   = texture(TEXTURE, UV);
    vec4 right = texture(TEXTURE, UV + vec2(px.x, 0.0));
    vec4 left  = texture(TEXTURE, UV - vec2(px.x, 0.0));
    vec4 down  = texture(TEXTURE, UV + vec2(0.0, px.y));
    vec4 up    = texture(TEXTURE, UV - vec2(0.0, px.y));

    float diff_province = step(0.05, length(col.rgb - right.rgb))
                        + step(0.05, length(col.rgb - left.rgb))
                        + step(0.05, length(col.rgb - down.rgb))
                        + step(0.05, length(col.rgb - up.rgb));

    float diff_owner = step(0.15, length(col.rgb - right.rgb))
                     + step(0.15, length(col.rgb - left.rgb))
                     + step(0.15, length(col.rgb - down.rgb))
                     + step(0.15, length(col.rgb - up.rgb));

    diff_province = clamp(diff_province, 0.0, 1.0);
    diff_owner    = clamp(diff_owner,    0.0, 1.0);

    // unowned pixels stay transparent
    float is_owned = step(0.01, col.a);

    vec4 result = col;
    result = mix(result, province_border_color, diff_province * is_owned);
    result = mix(result, state_border_color,    diff_owner);
    result.a = mix(col.a, 1.0, clamp(diff_province + diff_owner, 0.0, 1.0));

    COLOR = result;
}