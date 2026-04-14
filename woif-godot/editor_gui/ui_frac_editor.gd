extends HBoxContainer
class_name FracEditor

#  these have godot's "allow_greater" and "allow_lesser" for display reasons
# ticked but are overriden w/ code if you actually try to do that
@onready var base_box: SpinBox = $BaseBox
@onready var numerator_box: SpinBox = $VBoxContainer/NumeratorBox
@onready var denominator_box: SpinBox = $VBoxContainer/DenominatorBox

@export var assert_nonzero_positive: bool = true

var fraction: Fraction = Fraction.new(1)

signal value_changed

func _ready() -> void:
	for box: SpinBox in [base_box, numerator_box, denominator_box]:
		box.connect("value_changed", _update)
		box.get_line_edit().focus_mode = Control.FOCUS_NONE
	reset()

func assign(frac: Fraction):
	fraction = frac
	base_box.set_value_no_signal(fraction.base)
	numerator_box.set_value_no_signal(fraction.numerator)
	denominator_box.set_value_no_signal(fraction.denominator)

func _update(_ignored: float):
	denominator_box.set_value_no_signal(max(1, denominator_box.value))
	fraction = Fraction.new(base_box.value, numerator_box.value, denominator_box.value)
	
	# dont touch zero
	if assert_nonzero_positive and fraction.as_float() <= 0.0:
		fraction = Fraction.new(0, 1, denominator_box.value)
	
	# allow for denominators to not get reduced all the time
	var den_scale = denominator_box.value / fraction.denominator
	
	base_box.set_value_no_signal(fraction.base)
	numerator_box.set_value_no_signal(fraction.numerator*den_scale)
	denominator_box.set_value_no_signal(fraction.denominator*den_scale)
	
	emit_signal("value_changed", fraction)

func set_enabled(val: bool):
	for box: SpinBox in [base_box, numerator_box, denominator_box]:
		box.editable = val
	reset()

func reset():
	base_box.set_value_no_signal(1)
	numerator_box.set_value_no_signal(0)
	denominator_box.set_value_no_signal(1)
