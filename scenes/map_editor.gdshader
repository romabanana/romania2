shader_type canvas_item;

uniform float hue_shift : hint_range(-180.0, 180.0) = 40.0;
uniform float green_bias : hint_range(0.0, 1.0) = 0.3;
uniform float saturation : hint_range(0.0, 2.0) = 1.2;

vec3 rgb2hsl(vec3 c) {
    float mx = max(c.r, max(c.g, c.b));
    float mn = min(c.r, min(c.g, c.b));
    float delta = mx - mn;
    float l = (mx + mn) * 0.5;
    float s = 0.0;
    float h = 0.0;

    if (delta > 0.0001) {
        s = delta / (1.0 - abs(2.0 * l - 1.0));

        if (mx == c.r) h = mod((c.g - c.b) / delta, 6.0);
        else if (mx == c.g) h = (c.b - c.r) / delta + 2.0;
        else h = (c.r - c.g) / delta + 4.0;

        h *= 60.0;
        if (h < 0.0) h += 360.0;
    }

    return vec3(h, s, l);
}

vec3 hsl2rgb(vec3 c) {
    float h = c.x;
    float s = c.y;
    float l = c.z;
    float a = s * min(l, 1.0 - l);

    float kr = mod(0.0 + h / 30.0, 12.0);
    float kg = mod(8.0 + h / 30.0, 12.0);
    float kb = mod(4.0 + h / 30.0, 12.0);

    float r = l - a * max(-1.0, min(min(kr - 3.0, 9.0 - kr), 1.0));
    float g = l - a * max(-1.0, min(min(kg - 3.0, 9.0 - kg), 1.0));
    float b = l - a * max(-1.0, min(min(kb - 3.0, 9.0 - kb), 1.0));

    return vec3(r, g, b);
}

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    vec3 hsl = rgb2hsl(original.rgb);

    // Shift hue
    hsl.x = mod(hsl.x + hue_shift, 360.0);

    // Nudge hue toward green (120 degrees)
    float green_hue = 120.0;
    float diff = green_hue - hsl.x;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    hsl.x = hsl.x + diff * green_bias;

    // Boost saturation
    hsl.y = clamp(hsl.y * saturation, 0.0, 1.0);

    COLOR = vec4(hsl2rgb(hsl), original.a);
}