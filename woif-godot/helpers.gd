extends Resource
class_name hlp

# shoutout freya holmer
static func exdc(a, b, decay, delta):
	return b+(a-b)*exp(-decay*delta)

static func angle_to_angle(from, to):
	return fposmod(to-from + PI, PI*2) - PI

# ensure positivity
static func gcd(a: int, b: int) -> int:
	return _gcd(absi(a), absi(b))
# https://forum.godotengine.org/t/how-to-make-fraction-simplification/13728
static func _gcd(a: int, b: int) -> int:
	return a if b == 0 else gcd(b, a % b)
