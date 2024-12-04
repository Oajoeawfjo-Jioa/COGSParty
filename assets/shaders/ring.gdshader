shader_type canvas_item;

uniform vec4 ring_color: source_color = vec4(1.0, 0.75, 0.0, 1.0);
uniform float ring_fill_width = 4;
uniform float ring_outline_width = 2;
uniform float radius = 16;
uniform float fill_amount: hint_range(0.0, 1.0) = 0.5;
uniform float start_deg: hint_range(-180.0, 180.0) = 90.0;
uniform bool flip = false;

void fragment() {
	vec4 modulate = COLOR;
	float dist = length(UV.xy - vec2(0.5, 0.5)) / TEXTURE_PIXEL_SIZE.x;
	if (dist < radius - ring_fill_width) {
		COLOR.a = 0.0;
	} else if (dist < radius) {
		float direction = 1.0;
		if (flip) {
			direction = -1.0;
		}
		float curr_angle = mod(atan(UV.y - 0.5, (UV.x - 0.5) * direction) + PI + start_deg * PI / 180.0, 2.0 * PI);
		if (curr_angle < 2.0 * PI * fill_amount) {
			COLOR = ring_color;
		} else {
			COLOR = ring_color;
			COLOR.a = 0.25;
		}
	} else if (dist < radius + ring_outline_width) {
		COLOR = ring_color;
	} else {
		COLOR.a = 0.0;
	}
	
	COLOR *= modulate;
}