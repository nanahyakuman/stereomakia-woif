## handles score calculations, but not timing info
extends Node

@onready var combo_label = $"../NoteHolder/ComboLabel"
@onready var score_label = $"../NoteHolder/ScoreLabel"
@onready var true_score_label = $"../TrueScoreLabel"
@onready var scratcher = $Scratcher
# get the hold tick rate
@onready var note_holder = $"../NoteHolder"
@onready var input_manager: Node = $"../InputManager"

#  this is in flux but i basically want perfects and near perfects
# to be fine but anything else to be pretty punishing
const tap_values = [ # ongeki is 10 9 6 0
	10,
	9,
	0,
	-5 ]
# abs notes just play a different sound ( used to be worth more )
const abs_values = [
	10,
	9,
	0,
	-5 ]
const hold_value = 1
const circle_tap_value = 12
const circle_hold_value = 1

# level name is inserted into this by the editor
var scoring_info: ScoringInfo = ScoringInfo.new()

signal note_missed

# called by input manger
func score_note(val: int, offset: float, absolute: bool = false):
	val = score_label.change_rating(val, offset)
	if absolute:
		scoring_info.accumulated_score += abs_values[val]
	else:
		scoring_info.accumulated_score += tap_values[val]
	scoring_info.eval_counts[val] += 1
	# timing info
	if val > 0 and val < 3:
		if offset < 0.0:
			scoring_info.early_eval_count[val-1] += 1
		else:
			scoring_info.late_eval_count[val-1] += 1
	
	scoring_info.accumulated_score = max(scoring_info.accumulated_score, 0)
	true_score_label.set_score(scoring_info.get_displayed_score())
	# combo management
	if val < 2:
		_add_combo()
	else:
		_reset_combo()
	
	# break pfcs
	if val != 0:
		scoring_info.is_pfc = false

func score_hold(hit: bool, is_circle: bool):
	if hit:
		_add_combo(Fraction.new(0,1,10))
		scoring_info.accumulated_score += (circle_hold_value if is_circle else hold_value)
		scoring_info.eval_counts[4] += 1
	else:
		_reset_combo()
		scoring_info.eval_counts[5] += 1
		score_label.change_rating(99, 1)
	true_score_label.set_score(scoring_info.get_displayed_score())

func score_circle_note(hit: bool, offset: float):
	score_label.change_rating(0, offset)
	scoring_info.accumulated_score += circle_tap_value
	scoring_info.eval_counts[int(!hit)*3] += 1 # always abs or miss
	true_score_label.set_score(scoring_info.get_displayed_score())
	# combo management
	if hit:
		_add_combo()
	else:
		_reset_combo()

func _add_combo(amt: Fraction = Fraction.new(1,0,1)):
	scoring_info.combo = scoring_info.combo.added(amt)
	combo_label.assign(scoring_info.combo)
func _reset_combo():
	# scratch when you lose a combo
	if scoring_info.combo.base > 10: 
		scratcher.play()
	scoring_info.combo = Fraction.new(0,0,1)
	combo_label.assign(scoring_info.combo)
	scoring_info.is_full_combo = false
	scoring_info.is_pfc = false
	Vibrator.drop_combo()
	emit_signal("note_missed")

# called at generation to calc our theoretical max score
func register_tap():
	scoring_info.theoretical_max_score += tap_values[0]
#  holds don't start until after the drop window for their note
# concludes
func register_hold(len):
	scoring_info.theoretical_max_score += max(0.0, (len - input_manager.tap_windows.back())) * hold_value / note_holder.holds_tick_every
func register_circle_tap():
	scoring_info.theoretical_max_score += circle_tap_value
func register_circle_hold(len):
	scoring_info.theoretical_max_score += (len) * circle_hold_value / note_holder.holds_tick_every
func deregister_all():
	scoring_info.theoretical_max_score = 0
