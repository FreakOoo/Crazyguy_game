shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float contrast : hint_range(0.0, 4.0) = 1.4;
uniform float gamma : hint_range(0.1, 4.0) = 0.9;

uniform float dither_strength : hint_range(0.0, 1.0) = 0.35;

uniform float edge_threshold : hint_range(0.0, 1.0) = 0.22;
uniform float edge_strength : hint_range(0.0, 1.0) = 1.0;
uniform float edge_sensitivity : hint_range(0.1, 8.0) = 5.0;

uniform float invert : hint_range(0.0, 1.0) = 0.0;

float luminance(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

float bayer4(vec2 p) {
	ivec2 q = ivec2(mod(floor(p), 4.0));

	if (q.y == 0) {
		if (q.x == 0) return 0.0;
		if (q.x == 1) return 8.0;
		if (q.x == 2) return 2.0;
		return 10.0;
	}
	if (q.y == 1) {
		if (q.x == 0) return 12.0;
		if (q.x == 1) return 4.0;
		if (q.x == 2) return 14.0;
		return 6.0;
	}
	if (q.y == 2) {
		if (q.x == 0) return 3.0;
		if (q.x == 1) return 11.0;
		if (q.x == 2) return 1.0;
		return 9.0;
	}
	if (q.x == 0) return 15.0;
	if (q.x == 1) return 7.0;
	if (q.x == 2) return 13.0;
	return 5.0;
}

float sample_luma(vec2 uv) {
	return luminance(texture(screen_texture, uv).rgb);
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 pixel_pos = SCREEN_UV / px;

	vec4 tex = texture(screen_texture, SCREEN_UV);

	float lum = luminance(tex.rgb);
	lum = pow(clamp(lum, 0.0, 1.0), gamma);
	lum = (lum - 0.5) * contrast + 0.5;
	lum = clamp(lum, 0.0, 1.0);

	float d = (bayer4(pixel_pos) / 16.0) - 0.5;
	lum = clamp(lum + d * dither_strength, 0.0, 1.0);

	float bw = step(threshold, lum);

	float tl = sample_luma(SCREEN_UV + px * vec2(-1.0, -1.0));
	float tc = sample_luma(SCREEN_UV + px * vec2( 0.0, -1.0));
	float tr = sample_luma(SCREEN_UV + px * vec2( 1.0, -1.0));
	float ml = sample_luma(SCREEN_UV + px * vec2(-1.0,  0.0));
	float mr = sample_luma(SCREEN_UV + px * vec2( 1.0,  0.0));
	float bl = sample_luma(SCREEN_UV + px * vec2(-1.0,  1.0));
	float bc = sample_luma(SCREEN_UV + px * vec2( 0.0,  1.0));
	float br = sample_luma(SCREEN_UV + px * vec2( 1.0,  1.0));

	float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
	float gy = -tl - 2.0 * tc - tr + bl + 2.0 * bc + br;

	float edge = clamp(length(vec2(gx, gy)) * edge_sensitivity, 0.0, 1.0);
	float edge_mask = step(edge_threshold, edge);

	float final_bw = mix(bw, 0.0, edge_mask * edge_strength);
	final_bw = mix(final_bw, 1.0 - final_bw, invert);

	COLOR = vec4(vec3(final_bw), tex.a);
}