//  this is going to become pretty monolithic but multipasses don't work well in Godot ime
// so sorry. every shader is just a [0,1.0] value
shader_type canvas_item;

uniform sampler2D view: hint_screen_texture;

uniform float glitch_amount = 0.0;

uniform float offset = 1.0;

const vec2 red_dir = vec2(cos(PI/12.), sin(PI/12.));
const vec2 grn_dir = vec2(cos(PI*5.0/12.), sin(PI*5.0/12.));
const vec2 blu_dir = vec2(cos(PI*9.0/12.), sin(PI*9.0/12.));

void fragment() {
	//// glitch ////
	uint seed = uint(SCREEN_UV.y / SCREEN_PIXEL_SIZE.y);
	seed += uint(floor(TIME*6.)*5462.1); // on really long tracks this runs into the uintmax
	seed *= seed;
	seed ^= seed << 13u;
	seed ^= seed >> 17u;
	seed ^= seed << 5u;
	float fseed = float(seed) / 4294967295.0; // uint max
	
	// cube it for a more natural mix
	float gmix = mix(0.0, 1.0, glitch_amount * glitch_amount * glitch_amount);
	vec2 glitch_offset = vec2(fseed * gmix, 0.0);
	
	//// rgb ////
	vec4 tex = texture(view, SCREEN_UV + red_dir * SCREEN_PIXEL_SIZE * offset + glitch_offset);
	tex.g = texture(view, SCREEN_UV + grn_dir * SCREEN_PIXEL_SIZE * offset + glitch_offset).g;
	tex.b = texture(view, SCREEN_UV + blu_dir * SCREEN_PIXEL_SIZE * offset + glitch_offset).b;
	COLOR = tex;
}

