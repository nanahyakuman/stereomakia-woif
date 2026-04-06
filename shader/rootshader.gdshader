shader_type canvas_item;

uniform sampler2D view: hint_screen_texture;

uniform float offset = 1.0;

const vec2 red_dir = vec2(cos(PI/12.), sin(PI/12.));
const vec2 grn_dir = vec2(cos(PI*5.0/12.), sin(PI*5.0/12.));
const vec2 blu_dir = vec2(cos(PI*9.0/12.), sin(PI*9.0/12.));

void fragment() {
	vec4 tex = texture(view, SCREEN_UV + red_dir * SCREEN_PIXEL_SIZE * offset);
	tex.g = texture(view, SCREEN_UV + grn_dir * SCREEN_PIXEL_SIZE * offset).g;
	tex.b = texture(view, SCREEN_UV + blu_dir * SCREEN_PIXEL_SIZE * offset).b;
	COLOR = tex;
}

