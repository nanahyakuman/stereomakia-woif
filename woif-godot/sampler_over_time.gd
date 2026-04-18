extends Resource
class_name SamplerOverTime

#  the frac isn't used right now but it could be eventually maybe
# so im just copying it over anyway
var vals: Array[FractionPair] = [
	#FractionPair.new(Fraction.new(0), 1.0, 0.0),
	#FractionPair.new(Fraction.new(0), 0.5, 3.0, 1),
	#FractionPair.new(Fraction.new(0), .8, 6.0),
]

## get the calculated value at the indicated time
func at(time: float) -> float:
	if vals.size() == 0:
		return 0.0
	# find the first thing we're less than
	var index = 1
	while index < vals.size() and time >= vals[index].calc_time:
		index += 1
	index -= 1
	# try to interpolate 
	if index == vals.size()- 1 \
	or vals[index+1].interpolationMode == FractionPair.InterpolationMode.HOLD:
		return vals[index].val
	else:
		return remap(time, vals[index].calc_time, vals[index+1].calc_time, vals[index].val, vals[index+1].val)
