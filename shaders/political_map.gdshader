shader_type canvas_item;

uniform sampler2D province_texture;   // your province PNG
uniform sampler2D owner_texture;      // 256x1 — province_id → faction color
uniform float tint_opacity     : hint_range(0.0, 1.0) = 0.3;
uniform float border_thickness : hint_range(0.0, 8.0) = 1.0;
uniform bool  show_overlay     = false;

// converts province PNG color back to a 0-255 ID
int color_to_id(vec3 col) {
	// encode: r=id/65025, g=(id%255)/255 for IDs > 255
	// simple single channel for up to 255 provinces
	return int(round(col.r * 255.0));
}

void fragment() {
	vec4 terrain_col = texture(TEXTURE, UV);

	if (!show_overlay) {
		COLOR = terrain_col;
		///return;
	}

	// world position → province PNG uv
	// these match your map world bounds — update if needed
	vec2 map_uv = VERTEX / vec2(65536.0, 32768.0);
	map_uv = clamp(map_uv, 0.0, 1.0);

	vec2 px = vec2(1.0 / 256.0, 1.0 / 256.0);  // one pixel in province PNG

	// sample this fragment and neighbors
	vec4 p_center = texture(province_texture, map_uv);
	vec4 p_right  = texture(province_texture, map_uv + vec2(px.x * border_thickness, 0.0));
	vec4 p_left   = texture(province_texture, map_uv - vec2(px.x * border_thickness, 0.0));
	vec4 p_down   = texture(province_texture, map_uv + vec2(0.0, px.y * border_thickness));
	vec4 p_up     = texture(province_texture, map_uv - vec2(0.0, px.y * border_thickness));

	int id_center = color_to_id(p_center.rgb);
	int id_right  = color_to_id(p_right.rgb);
	int id_left   = color_to_id(p_left.rgb);
	int id_down   = color_to_id(p_down.rgb);
	int id_up     = color_to_id(p_up.rgb);

	// get owner colors from owner texture
	vec2 owner_uv_center = vec2((float(id_center) + 0.5) / 256.0, 0.5);
	vec2 owner_uv_right  = vec2((float(id_right)  + 0.5) / 256.0, 0.5);
	vec2 owner_uv_left   = vec2((float(id_left)   + 0.5) / 256.0, 0.5);
	vec2 owner_uv_down   = vec2((float(id_down)   + 0.5) / 256.0, 0.5);
	vec2 owner_uv_up     = vec2((float(id_up)     + 0.5) / 256.0, 0.5);

	vec4 owner_center = texture(owner_texture, owner_uv_center);
	vec4 owner_right  = texture(owner_texture, owner_uv_right);
	vec4 owner_left   = texture(owner_texture, owner_uv_left);
	vec4 owner_down   = texture(owner_texture, owner_uv_down);
	vec4 owner_up     = texture(owner_texture, owner_uv_up);

	// province border — neighbors have different province id
	bool province_border = (id_center != id_right) || (id_center != id_left)
						|| (id_center != id_down)  || (id_center != id_up);

	// state border — neighbors have different owner color
	bool state_border = province_border && (
		   length(owner_center.rgb - owner_right.rgb) > 0.01
		|| length(owner_center.rgb - owner_left.rgb)  > 0.01
		|| length(owner_center.rgb - owner_down.rgb)  > 0.01
		|| length(owner_center.rgb - owner_up.rgb)    > 0.01
	);

	// border colors
	vec3 province_border_col = vec3(0.0, 0.0, 0.0);  // thin dark line
	vec3 state_border_col    = vec3(1.0, 1.0, 1.0);  // thick bright line

	// base: terrain + owner tint
	bool is_owned = owner_center.a > 0.01;
	vec3 col = terrain_col.rgb;
	if (is_owned) {
		col = mix(col, owner_center.rgb, tint_opacity);
	}

	// draw borders on top
	if (state_border) {
		col = state_border_col;
	} else if (province_border) {
		col = mix(col, province_border_col, 0.6);
	}

	COLOR = vec4(col, terrain_col.a);
}
