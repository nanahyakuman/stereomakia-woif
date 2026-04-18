extends Resource
class_name FractionPair

var frac: Fraction
var val: float
var calc_time: float

enum InterpolationMode {
	HOLD,
	LINEAR,
	INTERPOLATION_MAX
}
var interpolationMode: InterpolationMode

func _init(_frac: Fraction, _val: float, _calc_time: float, _interpolationMode: InterpolationMode = InterpolationMode.HOLD) -> void:
	frac = _frac
	val = _val
	calc_time = _calc_time
	interpolationMode = _interpolationMode
	

static func compare(a: FractionPair, b: FractionPair):
	return a.calc_time < b.calc_time
