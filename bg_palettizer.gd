##  assigns this node's modulate per the global palettizer (if extant)
extends Control

var ph: PaletteHolder

func _ready() -> void:
	ph = get_tree().get_first_node_in_group("palette_holder")
	if ph:
		ph.colorsChanged.connect(_get_color)
		_get_color()

func _get_color():
	material.set_shader_parameter("colA", ph.colors[PaletteHolder.WHICH_COLOR.BG_A])
	material.set_shader_parameter("colB", ph.colors[PaletteHolder.WHICH_COLOR.BG_B])
