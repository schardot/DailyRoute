shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(0.2, 0.6, 1.0, 1.0); // change this
uniform float threshold = 0.4;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Detect "red-ish" pixels
    float red_strength = tex.r - max(tex.g, tex.b);

    if (red_strength > threshold) {
        // Preserve brightness (shading)
        float brightness = tex.r;

        vec3 new_color = target_color.rgb * brightness;

        COLOR = vec4(new_color, tex.a);
    } else {
        COLOR = tex;
    }
}