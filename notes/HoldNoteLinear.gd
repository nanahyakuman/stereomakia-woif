extends Palettizer
class_name HoldNoteLinear

# dont set the underscored directly
var _dir = TapNoteLinear.DIRS.L
var frac = Fraction.new(0,0,1,false)
var time = 3.0
var calculated_offset = 3.0
var len_frac = Fraction.new(1,0,1,false)
var _calculated_len = 1.0

var base_pos = Vector2.ZERO

@onready var nine_patch_rect_outline: NinePatchRect = $NinePatchRectOutline
@onready var nine_patch_rect_base: NinePatchRect = $NinePatchRectBase


func update(calculated_timer):
	position = base_pos + (calculated_offset - calculated_timer) * PlayerSettings.get_speed() * Vector2.UP
	
	visible = true
	if position.y > 0.0:
		var in_calc_len = (_calculated_len - (calculated_timer-calculated_offset)) * PlayerSettings.get_speed()
		var voffset = (calculated_timer-calculated_offset) * PlayerSettings.get_speed()
		for npr in [nine_patch_rect_base, nine_patch_rect_outline]:
			npr.size.y = 64 + in_calc_len
			npr.position.y = -32 - in_calc_len - voffset
		visible = in_calc_len >= 0.0
	else:
		#  this every frame might be a little slow but it allows
		# speed mods at runtime + is neccessary for our editor
		# to draw right
		set_len(_calculated_len, len_frac)

# cast a note by its type
func set_cast(val):
	_dir = val
	if _dir < 4:
		base_pos.x = (-3+_dir + 1.5) * TapNoteLinear.x_dist
	else:
		base_pos.x = 2.5 * TapNoteLinear.x_dist * (-1 if _dir == 4 else 1)

func set_len(val: float, _frac: Fraction):
	_calculated_len = val
	len_frac = _frac
	var calc_len = _calculated_len * PlayerSettings.get_speed()
	for npr in [nine_patch_rect_base, nine_patch_rect_outline]:
		npr.size.y = 64 + calc_len
		npr.position.y = -32 - calc_len

# like tapnotelinear, a little decroded but fully functional
func _get_color():
	nine_patch_rect_base.modulate = ph.colors[whichColor]
	nine_patch_rect_outline.modulate = ph.colors[PaletteHolder.WHICH_COLOR.NOTE_OUTLINE]
