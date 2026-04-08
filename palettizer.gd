##  assigns this node's modulate per the global palettizer (if extant)
extends Node2D
class_name Palettizer

@export var whichColor: PaletteHolder.WHICH_COLOR

var ph: PaletteHolder

func _ready() -> void:
	ph = get_tree().get_first_node_in_group("palette_holder")
	if ph:
		ph.colorsChanged.connect(_get_color)
		_get_color()

func _get_color():
	modulate = ph.colors[whichColor]

# so that taps can force their holds to be abs colored. its a pipe tho
func force_get_color():
	_get_color()
