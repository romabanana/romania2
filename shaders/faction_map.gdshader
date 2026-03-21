shader_type canvas_item;

uniform float border_strength      : hint_range(0.0, 1.0) = 0.9;
uniform float inner_strength       : hint_range(0.0, 1.0) = 0.3;
uniform float water_border_strength: hint_range(0.0, 1.0) = 0.9;
uniform float border_width         : hint_range(1.0, 5.0)  = 1.0;

void fragment() {
	vec2 px = vec2(border_width) / vec2(textureSize(TEXTURE, 0));

	vec4 col        = texture(TEXTURE, UV);
	vec4 right      = texture(TEXTURE, UV + vec2(px.x,  0.0));
	vec4 left       = texture(TEXTURE, UV - vec2(px.x,  0.0));
	vec4 down       = texture(TEXTURE, UV + vec2(0.0,   px.y));
	vec4 up         = texture(TEXTURE, UV - vec2(0.0,   px.y));
	vec4 up_right   = texture(TEXTURE, UV + vec2(px.x, -px.y));
	vec4 up_left    = texture(TEXTURE, UV + vec2(-px.x, -px.y));
	vec4 down_right = texture(TEXTURE, UV + vec2(px.x,  px.y));
	vec4 down_left  = texture(TEXTURE, UV + vec2(-px.x,  px.y));

	float is_owned      = step(0.01, col.a);
	float right_owned   = step(0.01, right.a);
	float left_owned    = step(0.01, left.a);
	float down_owned    = step(0.01, down.a);
	float up_owned      = step(0.01, up.a);
	float ur_owned      = step(0.01, up_right.a);
	float ul_owned      = step(0.01, up_left.a);
	float dr_owned      = step(0.01, down_right.a);
	float dl_owned      = step(0.01, down_left.a);

	float province_edge = clamp(
		step(0.01, length(col.rgb - right.rgb))      * right_owned +
		step(0.01, length(col.rgb - left.rgb))       * left_owned  +
		step(0.01, length(col.rgb - down.rgb))       * down_owned  +
		step(0.01, length(col.rgb - up.rgb))         * up_owned    +
		step(0.01, length(col.rgb - up_right.rgb))   * ur_owned    +
		step(0.01, length(col.rgb - up_left.rgb))    * ul_owned    +
		step(0.01, length(col.rgb - down_right.rgb)) * dr_owned    +
		step(0.01, length(col.rgb - down_left.rgb))  * dl_owned,
		0.0, 1.0) * is_owned;

	float water_edge = clamp(
		(1.0 - right_owned) + (1.0 - left_owned) +
		(1.0 - down_owned)  + (1.0 - up_owned)   +
		(1.0 - ur_owned)    + (1.0 - ul_owned)   +
		(1.0 - dr_owned)    + (1.0 - dl_owned),
		0.0, 1.0) * is_owned;

	float opacity = inner_strength;
	opacity = mix(opacity, water_border_strength, water_edge);
	opacity = mix(opacity, border_strength, province_edge);

	COLOR = vec4(col.rgb, col.a);
}