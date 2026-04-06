extends Sprite2D
class_name TapNoteLinear

# dont set the underscored directly
enum DIRS { L, D, U, R, LB, RB }
var _dir = DIRS.L
# frac this occurs
var frac: Fraction = Fraction.new(0,0,1,false)
# calculated visual offset, for bpm changes and soflan. in "time" units
var calculated_offset: float = 3.0
var _doubled: bool = false # require both buttons (only for ruld)
var _absolute: bool = false

var base_pos: Vector2 = Vector2.ZERO

var double_mask = [false, false]

const rots = [2, 1, 3, 0] #which way to rot the note
const x_dist = 120.0

# hold that this is paired with
var associated_hold: HoldNoteLinear = null

func update(calculated_timer):
	#position = base_pos + get_vertical_offset(time - timer)
	position = base_pos + get_vertical_offset(calculated_offset - calculated_timer)

# cast a note by its type
func set_cast(val):
	if 0 <= val and val < 4:
		set_directional(val)
	elif val < 6:
		set_bumper(val)

# make a note directional
func set_directional(val):
	_dir = val
	frame_coords.x = 0
	rotation = PI/2 * rots[_dir]
	base_pos.x = (-DIRS.size()/2+_dir + 1.5) * x_dist

func set_bumper(val):
	_dir = val
	frame_coords.x = 1
	rotation = 0
	base_pos.x = x_dist * (-1 if _dir == DIRS.LB else 1) * 2.5

func set_doubled(val):
	_doubled = val
	frame_coords.y = int(val)

func set_absolute(val: bool):
	_absolute = val
	if _absolute:
		self_modulate = Color.MEDIUM_PURPLE.lightened(.5)
	else:
		self_modulate = Color.WHITE


static func get_vertical_offset(_when):
	return (_when) * PlayerSettings.get_speed() * Vector2.UP

static func order(a, b):
	return a.frac.less_than(b.frac)
