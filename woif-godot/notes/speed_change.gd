##  these are sorta like really stripped down normal notes.
extends Palettizer

@onready var sprite_2d_bg: Sprite2D = $Sprite2DBG
@onready var sprite_2d_base: Sprite2D = $Sprite2DBase

var calculated_offset: float = 3.0

func update(calculated_timer):
	position = TapNoteLinear.get_vertical_offset(calculated_offset - calculated_timer)

#  overrides the base assign. kinda decroded to do it like this but
# it worked for the tapnote
func _get_color():
	sprite_2d_base.modulate = ph.colors[whichColor]
	sprite_2d_bg.modulate = ph.colors[PaletteHolder.WHICH_COLOR.NOTE_OUTLINE]
