## mixed fraction representation.
#  the fraction is always fully simplified, this makes it a lot 
# slower than it theoretically could be but prevents potential redundancy issues.
#  negative fractions are represented floored, so -1 1/3 in human speech is
# -2 + 2 / 3 internally
extends Resource
class_name Fraction

var base: int = 0
var numerator: int = 0
var denominator: int = 1
var forced_denominator: int = 0

func _init(b, n = 0, d = 1, skip_checks = false):
	base = b
	numerator = n
	denominator = d
	if !skip_checks:
		simplify()
		rebound()

func as_float():
	return float(base) + float(numerator) / float(denominator)

#  str(as_float()) will have ugly trailing innacuracy a lot,
# these ensure prettier fractions
func as_string():
	return "%d+%d/%d" % [base, numerator, denominator]
#  will be ugly on odder bases but should look fine on
# easier ones. fixes awkward 255.50000000000001 type strings,
# you should prob be using format strings anyway though
func as_string_decimal():
	return str(base) + str(float(numerator)/float(denominator)).substr(1)

func added(b: Fraction):
	if !forced_denominator:
		var ret = Fraction.new(base, numerator, denominator, true)
		ret.base += b.base
		ret.numerator *= b.denominator
		ret.denominator *= b.denominator
		ret.numerator += b.numerator * denominator
		ret.simplify()
		ret.rebound()
		return ret
	# quicker code if the denominator is known
	else:
		assert(denominator == b.denominator)
		var ret = Fraction.new(base, numerator, denominator, true)
		ret.numerator += b.numerator
		ret.rebound()
		return ret

func subtracted(b: Fraction):
	return added(Fraction.new(-b.base-1, b.denominator - b.numerator, b.denominator))

# there's not real operator overloads in godot rip
func less_than(b: Fraction):
	if base != b.base:
		return base < b.base
	else:
		return numerator * b.denominator < denominator * b.numerator

func equals(b: Fraction):
	return (base == b.base) and (numerator == b.numerator) and (denominator == b.denominator)

# from a string to a frac
static func from_string(str: String):
	var plus = str.find("+")
	var slash = str.find("/")
	var base = str.substr(0, plus).to_int()
	var num = str.substr(plus+1, slash-plus-1).to_int()
	var den = str.substr(slash+1).to_int()
	return Fraction.new(base, num, den)

static func from_float(val: float, den: int):
	var base = floor(val)
	var num = fposmod(val, 1.0) * den
	return Fraction.new(base, num, den)

func simplify():
	var gcd = hlp.gcd(numerator, denominator)
	numerator /= gcd
	denominator /= gcd
func rebound():
	base += floori(float(numerator) / float(denominator))
	numerator = posmod(numerator, denominator)
