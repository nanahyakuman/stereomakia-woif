# pass an update call onto children
extends Node2D

@onready var note_holder: Control = $"../.."

func update(timer):
	position = -TapNoteLinear.get_vertical_offset(timer + note_holder.chart_play_offset)
