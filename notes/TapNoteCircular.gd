extends Node2D
class_name TapNoteCircular

var _dir = 0.0 # may want to store this in degrees somehow, and convert at runtime
var is_right = false
var frac = Fraction.new(0)
var calculated_offset: float = 3.0

var next_hold: HoldNoteCircular = null

@onready var sprite_2d = $Node2D/Sprite2D
@onready var sprite_2d_2 = $Node2D/Sprite2D2

func update(calculated_timer):
	var scal = ((calculated_timer - calculated_offset) / PlayerSettings.get_circ_time() + 1.0)
	
	#  called on the sprite so that the whole note
	# can also be force hidden by the scorer
	sprite_2d.visible = scal > 0.0 and scal < 1.1
	sprite_2d_2.visible = sprite_2d.visible
	
	#modulate.a = lerp(0.5, 1.0, scal)
	scal = distance_curve(scal)
	scale = Vector2(scal, scal)
	
	rotation = _dir
	position = Vector2(200 * (1.0 if is_right else -1.0), -200)


# idk this might be too much math but its pretty legible this way
static func distance_curve(val: float):
	var base_scale = pow(val, 3.0)
	# editor gets goopy otherwise
	if base_scale > 1.0:
		return (1.0 + (base_scale - 1.0) * .5) * .95
	var cos_scale = (cos(base_scale * PI)) * -.5 + .5
	# .97 is to fit to the graphical circles
	return lerp(base_scale, cos_scale, .5) * .95
