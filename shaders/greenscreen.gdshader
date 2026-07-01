shader_type canvas_item;

uniform vec4 transparent_color: source_color = vec4(1.0);
uniform float pickup_range: hint_range(0.0, 1.0, 0.001) = 0.3;
uniform float fade_amount: hint_range(0.0, 1.0, 0.1) = 0.5;

float compare_rbg_values(vec3 orig_c, vec3 transparent_c) {
	float r = abs(orig_c.r - transparent_c.r);
	float g = abs(orig_c.g - transparent_c.g);
	float b = abs(orig_c.b - transparent_c.b);
	return smoothstep(pickup_range * fade_amount, pickup_range, (r+g+b)/3.0);
}

void fragment() {
	vec4 orig_color = texture(TEXTURE,UV);
	float comparison = compare_rbg_values(orig_color.rgb, transparent_color.rgb);
	COLOR = vec4(orig_color.rgb,comparison);
}