shader_type canvas_item;

uniform float cloud_speed  : hint_range(0.0, 1.0) = 0.05;
uniform float cloud_scale  : hint_range(0.0, 1.0) = 0.003;
uniform float cloud_density : hint_range(0.0, 1.0) = 0.5;
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 0.15);

void fragment() {
    vec2 uv = VERTEX * cloud_scale;
    
    // drift over time
    uv.x += TIME * cloud_speed;
    uv.y += TIME * cloud_speed * 0.4;

    // layered sine waves to fake noise
    float n  = sin(uv.x * 3.1 + uv.y * 2.3) 
             * cos(uv.x * 1.7 - uv.y * 3.7)
             + sin(uv.x * 5.3 + uv.y * 1.1 + TIME * cloud_speed)
             * cos(uv.x * 2.1 + uv.y * 4.3);

    n = n * 0.25 + 0.5;  // normalize to 0-1

    // threshold — only show where density is high enough
    float cloud = smoothstep(cloud_density, cloud_density + 0.2, n);

    COLOR = vec4(cloud_color.rgb, cloud_color.a * cloud);
}