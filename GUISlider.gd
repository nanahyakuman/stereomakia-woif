extends HBoxContainer

@onready var h_slider = $HSlider
@onready var value_label = $ValueLabel

var value = 0
@export var format_string = "%+d"

signal value_changed

func _ready():
	h_slider.connect("value_changed", _changed)

func _changed(val):
	value = val
	value_label.text = format_string % value
	emit_signal("value_changed", value)

func set_value(val):
	h_slider.set_value(val)
