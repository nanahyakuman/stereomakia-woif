extends Control
class_name NoteHolder

@onready var notes = $Notes
@onready var metronome = $Metronome
@onready var samplers: Node2D = $Samplers

@onready var root = get_parent().get_parent()

# song timer is in real time seconds, calc_timer is in offset time 'seconds'.
# so if there's 1 second of 0 scroll speed at the beginning of a chart
# calc time == song time - 1.0 for the rest of the chart
var song_timer = -2.0
var calc_timer = -2.0

var prev_beat_div = 0.0
var prev_beat_half_div = 0.0

# emit a signal every beat so holds can be scored
signal beat_passed

#  tempo info. written to by the editor.
# this should be pulled soon
#var quarter = 60.0 / 100.0

#  how often holds are scored. note this not synced to tempo,
# so rn there may be small discrepancies between a chart's theoretical
# max score and the max score actually achievable on it. it should overshoot
# about as often as it undershoots afaik though and the variance is hold-to-hold
var holds_tick_every = .1

# set audio offset. should load from a file in future
var hard_play_offset = 0.0 #-.03

# varies chart to chart
var chart_play_offset = 0.0

##  scroll data.
#  all the song's bpms.
var bpms = [
	# bar, bpm starting at that bar
	[0, 100.0]
]:
	set(val):
		bpms = val
		offsets_dirty = true

# scroll speeds, bar: speed as well.
var scroll_speeds: Array[FractionPair] = []:
	set(val):
		scroll_speeds = val
		offsets_dirty = true


#  baked actual timing data. dirtied every time there's an update,
# but only rebaked once info is requested. first is calc time,
# second is real time. we need both to 'performantly' convert from song to
# calc every frame.
var calculated_offsets = [[0.0, 0.0, 1.0]]
var offsets_dirty: bool = true


func _ready():
	hard_play_offset = PlayerSettings.player_set_game_offset

func _process(delta):
	# frame-time increment
	song_timer += delta * MusicPlayerShinobu.pitch_scale
	
	#  lerp back to "true" offset. using a lerp here bc shiobu sample is
	# really jittery & it messes w/ graphics. the delta between shinobu &
	# frame-time rarely exceeds a millisecond, UNLESS you drop a frame or a few,
	# then it's unplayably bad. that's why we're using Shinobu at all, to correct drops ;p
	if MusicPlayerShinobu.is_playing():
		var shinobu_timer = MusicPlayerShinobu.get_playback_position()
		shinobu_timer -= hard_play_offset + chart_play_offset
		song_timer = hlp.exdc(song_timer, shinobu_timer, 20.0, delta)
		
	
	# hold scoring
	while song_timer > prev_beat_div * holds_tick_every:
		prev_beat_div += 1.0
		emit_signal("beat_passed", calc_timer)
		metronome.play()
	
	# start song at beginning
	if calc_time() > 0.0 and !MusicPlayerShinobu.is_playing():
		# dont requeue at end. need a bit of a safety window bc of buffers
		if calc_time() + 1.0 < MusicPlayerShinobu.get_length():
			MusicPlayerShinobu.play(calc_time())
	
	update_notes()

# also called by the editor
func update_notes():
	calc_timer = _calc_time_from_real_time(song_timer)
	
	# update all the notes (recursive)
	for nh in notes.get_children():
		nh.update(calc_timer)
	for s in samplers.get_children():
		s.update(calc_timer)


func _calc_time_from_real_time(rt: float) -> float:
	var index = 0
	while calculated_offsets[index+1][1] < rt:
		index += 1
		# carry forward
		_rebake_offsets(index+1)
	
	var base = calculated_offsets[index]
	var next = calculated_offsets[index+1]
	
	return remap(rt, base[1], next[1], base[0], next[0])

#  do bpm and soflan math. this returns in calc time, not song time
func calculate_offset_at(frac_time: Fraction) -> float:
	# overshoot by one so we can lerp to it
	_rebake_offsets(frac_time.base+1)
	var base = calculated_offsets[frac_time.base][0]
	var next = calculated_offsets[frac_time.base+1][0]
	return lerp(base, next, frac_time.remainder_as_float())

# just bpm math. returns the real time offset, for use in graphs
func calculate_realtime_at(frac_time: Fraction) -> float:
	# overshoot by one so we can lerp to it
	_rebake_offsets(frac_time.base+1)
	var base = calculated_offsets[frac_time.base][1]
	var next = calculated_offsets[frac_time.base+1][1]
	return lerp(base, next, frac_time.remainder_as_float())

# this will actually do nothing the theoretical majority of the time
func _rebake_offsets(up_to: int):
	# force rebuild everything if we're dirty
	if offsets_dirty:
		calculated_offsets = [[0.0, 0.0, bpms[0][1]]]
		offsets_dirty = false
	
	# only build up to the requested value
	var bpmi = 0
	var ssi = 0
	while calculated_offsets.size() <= up_to:
		var current_index = calculated_offsets.size()
		while bpmi < bpms.size()-1 and bpms[bpmi+1][0] < current_index:
			bpmi += 1
		while ssi < scroll_speeds.size()-1 and scroll_speeds[ssi+1].frac.base < current_index:
			ssi += 1
		var add = 60.0 / bpms[bpmi][1] 
		
		var mult = 1.0
		if scroll_speeds.size() > 0:
			mult = scroll_speeds[ssi].val
		var calc_add = add * mult
		
		var next = [calculated_offsets.back()[0]+calc_add, calculated_offsets.back()[1]+add]
		calculated_offsets.push_back(next)


func calculate_from_offset(offs: float, subdiv: int) -> Fraction:
	var frac = Fraction.new(0)
	var bpmi = 0
	var beat_len
	
	#  subtract bpms until we get to the one this one is contained by.
	# only necessary when multiple bpms are defined
	while bpmi + 1 < bpms.size():
		beat_len = 60.0 / bpms[bpmi][1]
		var total_time_this_bpm = beat_len * (bpms[bpmi+1][0] - bpms[bpmi][0])
		if  total_time_this_bpm < offs:
			offs -= total_time_this_bpm
			frac.base += bpms[bpmi+1][0] - bpms[bpmi][0]
			bpmi += 1
		else:
			#bpmi += 1
			break
	
	# the final bpm
	beat_len = 60.0 / bpms[bpmi][1]
	# fix snapping
	offs += beat_len / subdiv * .5
	# base
	var full_beats_remaining = floori(offs / beat_len)
	frac.base += full_beats_remaining
	# fraction portion
	var beat_remainder = fmod(offs, beat_len)
	var remainder_ratio = beat_remainder / beat_len
	frac.denominator = subdiv
	frac.numerator = remainder_ratio * subdiv
	
	return frac


# get the song tim w/ offset
func calc_time():
	return song_timer + (hard_play_offset + chart_play_offset)
