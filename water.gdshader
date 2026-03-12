shader_type canvas_item;

uniform vec4 water_color_shallow : source_color = vec4(0.1, 0.4, 0.7, 1.0);
uniform vec4 water_color_deep    : source_color = vec4(0.05, 0.2, 0.5, 1.0);
uniform float wave_speed  : hint_range(0.0, 2.0) = 0.3;
uniform float wave_scale  : hint_range(0.0, 1.0) = 0.1;
void fragment() {
	vec2 uv = VERTEX / vec2(10.0, 010.0);
    float n = sin(uv.x * 3.7 + TIME * wave_speed) 
            * sin(uv.y * 2.9 + TIME * wave_speed * 0.6)
            * sin((uv.x + uv.y) * 1.3 + TIME * wave_speed * 0.4)
            * sin((uv.x - uv.y) * 2.1 - TIME * wave_speed * 0.8);
    n = n * 0.5 + 0.5;
    vec4 col = mix(water_color_deep, water_color_shallow, n * wave_scale + 0.3);
    COLOR = col;

}