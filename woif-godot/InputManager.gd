# scoring logic
extends Node

@onready var note_holder = $"../NoteHolder"
@onready var tap_notes = $"../NoteHolder/Notes/TapNotes".get_children()
@onready var hold_notes = $"../NoteHolder/Notes/HoldNotes".get_children()
@onready var circle_tap_notes_left = $"../NoteHolder/Notes/CircleTapNotesLeft"
@onready var circle_tap_notes_right = $"../NoteHolder/Notes/CircleTapNotesRight"
@onready var circle_hold_notes_left = $"../NoteHolder/Notes/CircleHoldNotesLeft"
@onready var circle_hold_notes_right = $"../NoteHolder/Notes/CircleHoldNotesRight"
@onready var circle_release_notes_left = $"../NoteHolder/Notes/CircleReleaseNotesLeft"
@onready var circle_release_notes_right = $"../NoteHolder/Notes/CircleReleaseNotesRight"
@onready var radial_indicator_l = $"../NoteHolder/RingLeft/RadialIndicator"
@onready var radial_indicator_r = $"../NoteHolder/RingRight/RadialIndicator"
@onready var indicators = $"../NoteHolder/Indicators"
@onready var scoring_manager = $"../ScoringManager"
@onready var editor = $"../Editor"
@onready var fader = $"../Fader"

# input buttons and their corresponding lanes
const inputs = [
	"note_r_1", "note_r_2",
	"note_u_1", "note_u_2",
	"note_l_1", "note_l_2",
	"note_d_1", "note_d_2",
	"note_bumper_l", "note_bumper_r"
]
const input_lane_mask = [
	3, 3,
	2, 2,
	0, 0,
	1, 1,
	4, 5
]

# historical values for reference, but these were modified in woif
#const tap_windows = [
	#.000, #abs
	#.034, #pure
	#.067, #impure
	#.134,
#]
const tap_windows = [
	.000, #abs
	.034, #pure
	.084, #impure
	.134, #miss. reminder you can't "miss" early, the input is just dropped.
	# this is also the min time before a hold starts scoring
]
# these are always abs if you hit them at all
const circle_tap_window = .150

#  nudge scoring window when you get a pure to improve scores a tiny bit.
# also lessens desync from slightly innacurate bpm or runtime hangs. not
# doing it on impue or miss because im assuming thats far enough away to be user
# error
## zeroed out! does nothing
var pure_nudge = 0.0 #0.001
var runtime_offset = 0.0

# offset for note logic
var to = [0,0,0,0,0,0]
var ho = [0,0,0,0,0,0]
var ctol = 0
var ctor = 0
var crol = 0
var cror = 0
var chol = 0
var chor = 0

var active

func _ready():
	note_holder.connect("beat_passed", check_holds)

#  moved input code here because we dont want it being intercepted.
# idk why but if we add a button to be a uiaction we cant hold
# it here anymore using Input's just_released as a toggle
func _input(event):
	for i in inputs.size():
		if event.is_action_pressed(inputs[i]):
			indicators.get_child(input_lane_mask[i]).report_press()
			_note_pressed(input_lane_mask[i], i%2)
		if event.is_action_released(inputs[i]):
			indicators.get_child(input_lane_mask[i]).report_release()
	

func _process(delta):
	#  disable self if the editor is active. this will toggle 0 or 1 time
	# but editor activation is delayed so we need to wait for it
	active = !editor.active
	
	if !active:
		return
	
	# scroll past old tap notes. 
	for dir in 6:
		while to[dir] < tap_notes[dir].get_child_count() and tap_notes[dir].get_child(to[dir]).realtime_offset - _calc_time() < -tap_windows[-1]:
			scoring_manager.score_note(99, 1)
			to[dir] += 1
	
	#  quadding code is lame but it resists refactoring sorz
	# scroll past old circle notes
	while ctol < circle_tap_notes_left.get_child_count() and circle_tap_notes_left.get_child(ctol).realtime_offset - _calc_time() < -circle_tap_window:
		scoring_manager.score_note(99, 1)
		ctol += 1
	while ctor < circle_tap_notes_right.get_child_count() and circle_tap_notes_right.get_child(ctor).realtime_offset - _calc_time() < -circle_tap_window:
		scoring_manager.score_note(99, 1)
		ctor += 1
	
	# scroll past old circle releases
	while crol < circle_release_notes_left.get_child_count() and circle_release_notes_left.get_child(crol).realtime_offset - _calc_time() < -circle_tap_window:
		scoring_manager.score_note(99, 1)
		crol += 1
	while cror < circle_release_notes_right.get_child_count() and circle_release_notes_right.get_child(cror).realtime_offset - _calc_time() < -circle_tap_window:
		scoring_manager.score_note(99, 1)
		cror += 1
	
	if _check_if_end():
		fader.fade()

func _check_if_end():
	for i in 6:
		if tap_notes[i].get_child_count() > to[i]:
			return false
		if hold_notes[i].get_child_count() > ho[i]:
			return false
	for pair in [
		[ctol, circle_tap_notes_left],
		[ctor, circle_tap_notes_right],
		[crol, circle_release_notes_left],
		[cror, circle_release_notes_right],
		[chol, circle_hold_notes_left],
		[chor, circle_hold_notes_right]
	]:
		if pair[0] < pair[1].get_child_count():
			return false
		if pair[1].get_child_count() < 0:
			var final = pair[1].get_child(pair[1].get_child_count()-1)
			if final is HoldNoteCircular and final.realtime_offset + final.realtime_len > _calc_time():
				return false
	return true

# dirs are as in tapnotelinear { R, U, L, D, LB, RB }
func _note_pressed(dir: int, is_right: bool):
	if !active:
		return
	var track_node = tap_notes[dir]
	for n in range(to[dir], track_node.get_child_count()):
		var note = track_node.get_child(n)
		# tap notes on udlr+lb/rb
		var abs_offset = abs(_calc_time() - note.realtime_offset)
		# don't read too far into future.
		if abs_offset < tap_windows[-1]:
			# double notes need both sides
			if note._doubled:
				note.double_mask[int(is_right)] = true
				if !note.double_mask[0] or !note.double_mask[1]:
					return
			
			# calc score
			var score = 0
			# absolute notes are alway perfect if hit
			while score < tap_windows.size()-2:
				if abs_offset > tap_windows[score+1]:
					score += 1
				else:
					break
			note.visible = false
			to[dir] += 1
			scoring_manager.score_note(score, _calc_time() - note.realtime_offset, note._absolute)
			# only play the nice hitsound if you abs an abs note
			var indicator = indicators.get_child(dir)
			indicator.play_sound(note._absolute and score == 0)
			if note._absolute and score < 3:
				if note._doubled:
					Vibrator.double_absolute()
				else:
					Vibrator.absolute()
			# start hold sound if we're a hold
			if note.associated_hold != null:
				indicator.requested = note.associated_hold.realtime_len / MusicPlayerShinobu.pitch_scale
			
			# internal offset adjust on pure
			if score == 1:
				runtime_offset -= pure_nudge * sign(_calc_time() - note.realtime_offset)
			#print(runtime_offset)
			
			return
			
		# break if we're too far into the future
		else:
			return


# only 1 hit window. called only on flicks, not just slides
func circle_pressed(is_right: bool, dir: float):
	if !active:
		return
	var holder = circle_tap_notes_right if is_right else circle_tap_notes_left
	
	for n in range(ctor if is_right else ctol, holder.get_child_count()):
		var note = holder.get_child(n)
		# angle match
		if abs(hlp.angle_to_angle(dir, note._dir)) > PI * .28:
			continue
		# actually try the note
		var abs_offset = abs(_calc_time() - note.realtime_offset)
		# don't read too far into future.
		if abs_offset < circle_tap_window:
			note.visible = false
			if is_right:
				ctor += 1
			else:
				ctol += 1
			scoring_manager.score_circle_note(1, _calc_time() - note.realtime_offset)
			
			Vibrator.circle_tap(is_right)
			
			# sound
			if is_right:
				radial_indicator_r.play_sound(true)
				 #  will be overwritten on the first hold with the accurate value
				if note.next_hold != null:
					radial_indicator_r.requested = 999.0
					radial_indicator_r.current_hold = note.next_hold
			else:
				radial_indicator_l.play_sound(true)
				if note.next_hold != null:
					radial_indicator_l.requested = 999.0
					radial_indicator_l.current_hold = note.next_hold
			return # don't return here to allow you to chart multinotes. idk if i like that tho
		# break if we're too far into the future
		else:
			return

func circle_released(is_right: bool, dir: float): 
	if !active:
		return
	var holder = circle_release_notes_right if is_right else circle_release_notes_left
	
	for n in range(cror if is_right else crol, holder.get_child_count()):
		var note = holder.get_child(n)
		# dont bother with angle match
		#if abs(hlp.angle_to_angle(dir, note._dir)) > PI * .28:
			#continue
		# actually try the note
		var abs_offset = abs(_calc_time() - note.realtime_offset)
		# don't read too far into future.
		if abs_offset < circle_tap_window:
			note.visible = false
			if is_right:
				cror += 1
			else:
				crol += 1
			scoring_manager.score_circle_note(1, _calc_time() - note.realtime_offset)
			
			Vibrator.circle_release(is_right)
			
			# sound
			if is_right:
				radial_indicator_r.play_sound(false)
			else:
				radial_indicator_l.play_sound(false)
			#return # don't return to allow you to chart multinotes
		# break if we're too far into the future
		else:
			return

# called bny noteholder every so often to check all holds
func check_holds(timer):
	if !active:
		return
	# adjust timer to internal offset
	timer += runtime_offset
	
	for dir in 6:
		var track_node = hold_notes[dir]
		for n in range(ho[dir], track_node.get_child_count()):
			var note = track_node.get_child(n)
			#  if we're over this note basically. doesn't start until the end of the safety window
			if timer > note.realtime_offset + tap_windows.back():
				var indicator = indicators.get_child(note._dir)
				if timer < note.realtime_offset + note.realtime_len - .05:
					scoring_manager.score_hold(indicator.is_held(), false)
				# offset past completed notes
				else:
					ho[dir] += 1
	
	for is_right in [false, true]:
		var track_node = circle_hold_notes_left if !is_right else circle_hold_notes_right
		for n in range((chol if !is_right else chor), track_node.get_child_count()):
			var note = track_node.get_child(n)
			var indicator = radial_indicator_l if !is_right else radial_indicator_r
			if timer > note.realtime_offset:
				if timer < note.realtime_offset + note.realtime_len:
					# scoring only triggers when we're safely within a note
					if (!note.is_onset or timer > note.realtime_offset + circle_tap_window) and \
						timer < note.realtime_offset + note.realtime_len:
						var active = indicator.is_active()
						var angled_correctly = true
						if abs(hlp.angle_to_angle(indicator.rotation, note.calc_dir(timer))) > PI * .28:
							angled_correctly = false
						scoring_manager.score_hold(active and angled_correctly, true)
					# holds audio triggers are more juvenile
					indicator.requested = note.realtime_offset + note.realtime_len - timer
					indicator.current_hold = note
					# stitch in next hold
					if note.next_hold:
						indicator.requested += 999.0
				else:
					# offset past completed notes
					if is_right:
						chor += 1
					else:
						chol += 1
					
					# kill indicator knowledge of this. messes with chained hold playback
					indicator.current_hold = null
					indicator.requested = 0.0


func _calc_time():
	return note_holder.song_timer + runtime_offset
