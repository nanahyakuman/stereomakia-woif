extends Node2D

# just position the indicators
func _ready():
	for i in 4:
		get_child(i).position.x = TapNoteLinear.x_dist * (i-2 + .5)
	get_child(4).position.x = -TapNoteLinear.x_dist * 2.5
	get_child(5).position.x = TapNoteLinear.x_dist * 2.5
