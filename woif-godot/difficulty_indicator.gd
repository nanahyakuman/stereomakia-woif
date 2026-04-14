extends Control

@onready var label = $Label
@onready var selected = $Control/Sprite2D2

func set_difficulty(diff: String):
	label.text = diff

func get_difficulty():
	return label.text

func set_selected(val: bool):
	selected.self_modulate.a = 1.0 if val else 0.0
