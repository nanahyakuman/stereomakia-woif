##  Holds all a level's colors. Assigned by the editor on load, and then
## prompted to emit the update signal. Anything that needs the colors connects
## itself using global groups and listens & learns.
extends Node
class_name PaletteHolder

signal colorsChanged

enum WHICH_COLOR {
	BG_A,
	BG_B,
	
	LANE_LINEAR,
	LANE_CIRCULAR_LEFT,
	LANE_CIRCULAR_RIGHT,
	
	NOTE_BASE,
	NOTE_OUTLINE,
	NOTE_ABSOLUTE
}

static var DEF_COLS: Array[Color] = [
	Color("ffffff"),
	Color("fcfcfcff"),
	
	Color("b0b0b0"),
	Color("ff38c6"),
	Color("00ff8c"),
	
	Color("ffffff"),
	Color("000000"),
	Color("c9b7ed"),
]

var colors: Array[Color] = [
	Color("ffffff"),
	Color("fcfcfcff"),
	
	Color("b0b0b0"),
	Color("ff38c6"),
	Color("00ff8c"),
	
	Color("ffffff"),
	Color("000000"),
	Color("c9b7ed"),
]

func _ready() -> void:
	call_deferred("emit_signal", "colorsChanged")

func update():
	emit_signal("colorsChanged")
