shader_type canvas_item;

uniform vec3 colA: source_color;
uniform vec3 colB: source_color;

uniform float vertical_count = 10.;
uniform vec2 speed = vec2(0, -.015);


void fragment() {
	// .5 used to center the effect
	vec2 coords = (SCREEN_UV + vec2(-.5)) * vertical_count;
	coords.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	coords += speed * TIME * vertical_count;
	float light = float((mod(coords.x, 2.0) > 1.0) != (mod(coords.y, 2.0) > 1.0));
	COLOR.rgb = mix(colA, colB, light);
}

