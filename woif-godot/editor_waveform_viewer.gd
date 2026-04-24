# pass an update call onto children
extends Node2D

@onready var note_holder: Control = $"../.."
@onready var sprite_2d: Sprite2D = $Sprite2D

func update(timer):
	sprite_2d.scale.x = PlayerSettings.get_speed() / 64.
	sprite_2d.scale.y = 6.0
	
	position = -TapNoteLinear.get_vertical_offset(timer + note_holder.chart_play_offset)
