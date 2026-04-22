extends Resource
class_name SamplerOverTime

var _vals: Array[FractionPair] = []
var _dirty: bool = false

## get the calculated value at the indicated time
func at(time: float) -> float:
	if _vals.size() == 0:
		return 0.0
	if _dirty:
		_vals.sort_custom(FractionPair.compare)
		_dirty = false
	# find the first thing we're less than
	var index = 1
	while index < _vals.size() and time >= _vals[index].calc_time:
		index += 1
	index -= 1
	# try to interpolate 
	if index == _vals.size() - 1 \
	or _vals[index+1].interpolationMode == FractionPair.InterpolationMode.HOLD:
		return _vals[index].val
	else:
		return remap(clamp(time, _vals[index].calc_time, _vals[index+1].calc_time), _vals[index].calc_time, _vals[index+1].calc_time, _vals[index].val, _vals[index+1].val)

func add_val(v: FractionPair):
	_vals.append(v)
	_dirty = true

func set_vals(vs: Array[FractionPair]):
	_vals = vs
	_dirty = true

func get_vals() -> Array[FractionPair]:
	return _vals
