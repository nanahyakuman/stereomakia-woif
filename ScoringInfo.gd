extends Resource
class_name ScoringInfo

const target_score = 7000000
#  make it a little easier even w/o absolutes to pad
const mult = 1.02

var song_name = ""
var chart_diff = ""

var theoretical_max_score: int = 0
var accumulated_score: int = 0

var is_full_combo: bool = true
var is_pfc: bool = true
var combo: Fraction = Fraction.new(0)

# the 4 normal ratings and then hold ok/ng
var eval_counts = [0,0,0,0, 0,0]
# pure impure early/late count. (misses are always late)
var early_eval_count = [0,0]
var late_eval_count = [0,0]

func get_displayed_score() -> int:
	if theoretical_max_score == 0:
		return 0
	return accumulated_score * target_score * mult / theoretical_max_score

func calculate_grade() -> String:
	# s if above 7tk. plus is awarded for full combo regardless of base score
	if accumulated_score * mult > theoretical_max_score:
		if is_full_combo:
			if is_pfc:
				return "S*"
			return "S+"
		return "S"
	
	# A and onwards
	var base = 65
	var decrement = (target_score - get_displayed_score()) / 500000
	var c = char(base + decrement)
	if is_full_combo:
		return c + "+"
	else:
		return c

