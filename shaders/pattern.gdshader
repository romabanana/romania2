shader_type canvas_item;

uniform float line_spacing : hint_range(2.0, 200.0) = 50.0;
uniform float line_width   : hint_range(0.1, 1.0)   = 0.3;
void fragment() {
    // UV goes 0-1 across the sprite which maps to world space
    // scale up to get world-like coordinates for the pattern
    vec2 world_pos = UV * vec2(65536.0, 32768.0);
    
    float pattern = fract((world_pos.x + world_pos.y) / line_spacing);
    float line    = step(1.0 - line_width, pattern);

    COLOR = vec4(1.0, 0.0, 0.0, line * 0.8);
}