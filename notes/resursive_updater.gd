# pass an update call onto children
extends Node2D

func update(timer):
	for c in get_children():
		c.update(timer)
