# pass an update call onto children
extends Node2D

@onready var note_holder: Control = $"../.."
@onready var sprite_2d: Sprite2D = $Sprite2D

func update(timer):
	#  seems to diverge over time depending on the song, idk why.
	# rn it's accurate for blue bayou
	var wavscale = .02206 * .5 
	wavscale *= MusicPlayerShinobu.get_length() / 141.217
	sprite_2d.scale.x = PlayerSettings.get_speed() * wavscale
	sprite_2d.scale.y = 6.0
	
	position = -TapNoteLinear.get_vertical_offset(timer + note_holder.chart_play_offset)
