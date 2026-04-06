shader_type canvas_item;

uniform float vertical_count = 10.;
uniform float amount = .015;
uniform vec2 speed = vec2(0, -.015);

void fragment() {
	// .5 used to center the effect
	vec2 coords = (SCREEN_UV + vec2(-.5)) * vertical_count;
	coords.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	coords += speed * TIME * vertical_count;
	bool light = (mod(coords.x, 2.0) > 1.0) != (mod(coords.y, 2.0) > 1.0);
	COLOR.rgb *= 1.0 - vec3(amount) * float(light);
}

