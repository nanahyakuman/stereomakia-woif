extends ColorPickerButton

var ph: PaletteHolder
@export var which: PaletteHolder.WHICH_COLOR

func _ready() -> void:
	ph = get_tree().get_first_node_in_group("palette_holder")
	
	call_deferred("_get_col")

# this needs to be delayed a frame for instantiation order
func _get_col() -> void:
	color = ph.colors[which]

func _on_color_changed(color: Color) -> void:
	ph.assign_single_color(which, color)
