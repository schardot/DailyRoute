shader_type canvas_item;

uniform sampler2D mask_texture : filter_nearest;

uniform vec4 roof_color : source_color;
uniform vec4 wall_color : source_color;
uniform vec4 door_color : source_color;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec4 mask = texture(mask_texture, UV);

    // 🔥 intensidade mais fiel (igual ao shader novo)
    float intensity = tex.r;

    vec3 final_color = tex.rgb;

    // 🔴 Roof (vermelho na máscara)
    if (mask.r > mask.g && mask.r > mask.b) {
        final_color = roof_color.rgb * intensity;
    }
    // 🟢 Wall (verde)
    else if (mask.g > mask.r && mask.g > mask.b) {
        final_color = wall_color.rgb * intensity;
    }
    // 🔵 Door (azul)
    else if (mask.b > mask.r && mask.b > mask.g) {
        final_color = door_color.rgb * intensity;
    }

    COLOR = vec4(final_color, tex.a);
}