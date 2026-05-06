shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0);
uniform float outline_luminance_max : hint_range(0.0, 0.35) = 0.12;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 rgb = lum <= outline_luminance_max ? tex.rgb : tint.rgb * lum;
	COLOR = vec4(rgb, tex.a);
}