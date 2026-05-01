shader_type canvas_item;

uniform sampler2D mask_texture : filter_nearest;

uniform vec4 roof_color : source_color;
uniform vec4 wall_color : source_color;   // parede + chaminé
uniform vec4 door_color : source_color;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec4 mask = texture(mask_texture, UV);
	
    vec3 final_color = tex.rgb;

   float intensity = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

	if (mask.r > mask.g && mask.r > mask.b) {
	    final_color = roof_color.rgb * intensity;
	} else if (mask.g > mask.r && mask.g > mask.b) {
	    final_color = wall_color.rgb * intensity;
	} else if (mask.b > mask.r && mask.b > mask.g) {
	    final_color = door_color.rgb * intensity;
	}
	
	float edge = step(0.5, tex.a);
	vec3 result = mix(tex.rgb, final_color, edge);
    COLOR = vec4(final_color, tex.a);
}