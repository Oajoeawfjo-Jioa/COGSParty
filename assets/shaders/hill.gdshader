shader_type canvas_item;

uniform float divisions = 8.0; // increase for more stripe density
uniform float stripe_bias = 2.5; // 1.0 means no stripes; 2.0 means stripes and gaps are equal size
uniform float speed = 0.1;
uniform float angle = 0.7854; // in radians
uniform float radius = 64;
uniform float outline_width = 8;
uniform float capture_width = 16;
uniform float capture_amount: hint_range(0.0, 1.0) = 0.5;
uniform float start_deg: hint_range(-180.0, 180.0) = 90.0;
uniform bool capture_flip = false;

void fragment() {
	vec4 modulate = COLOR;
	float dist = length(UV.xy - vec2(0.5, 0.5)) / TEXTURE_PIXEL_SIZE.x;
	bool draw_stripes = false;
	if (dist < radius - capture_width) {
		draw_stripes = true;
	} else if (dist < radius) {
		float capture_direction = 1.0;
		if (capture_flip) {
			capture_direction = -1.0;
		}
		float curr_angle = mod(atan(UV.y - 0.5, (UV.x - 0.5) * capture_direction) + PI + start_deg * PI / 180.0, 2.0 * PI);
		if (curr_angle < 2.0 * PI * capture_amount) {
			COLOR = modulate;
		} else {
			draw_stripes = true;
		}
	} else if (dist < radius + outline_width) {
		COLOR = modulate;
	} else {
		COLOR.a = 0.0;
	}
	
	// Draw stripes
	if (draw_stripes) {
		float w = cos(angle) * UV.x + sin(angle) * UV.y - speed * TIME * TEXTURE_PIXEL_SIZE.x;
		if (floor(mod(w * divisions, stripe_bias)) < 0.0001) {
			COLOR.a = 0.0;
		} else {
			COLOR = modulate;
			COLOR.a *= 0.25;
		}
	}
}