extends Sprite2D

var time = 1.0

func update(timer):
	position = TapNoteLinear.get_vertical_offset(time - timer)
