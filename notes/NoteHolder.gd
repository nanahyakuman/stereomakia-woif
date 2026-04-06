extends Control

@onready var notes = $Notes
@onready var metronome = $Metronome

@onready var root = get_parent().get_parent()

var timer = -2.0
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

# all the song's bpms
var bpms = [
	# bar, bpm starting at that bar
	[0, 100.0]
]

func _ready():
	hard_play_offset = PlayerSettings.player_set_game_offset

func _process(delta):
	# static increment
	timer += delta * MusicPlayerShinobu.pitch_scale 
	
	#  lerp back to "true" offset. using a lerp here bc it's really jittery
	# unfiltered & it messes w/ graphics. the actual offset rarely exceeds
	# a millisecond, so i don't think the theoretical innacuraccy this
	# introduces is really an issue
	if MusicPlayerShinobu.is_playing():
		var shinobu_timer = MusicPlayerShinobu.get_playback_position()
		shinobu_timer -= hard_play_offset + chart_play_offset
		timer = hlp.exdc(timer, shinobu_timer, 20.0, delta)
		
	
	# hold scoring
	while timer > prev_beat_div * holds_tick_every:
		prev_beat_div += 1.0
		emit_signal("beat_passed", timer)
		metronome.play()
	
	# start song at beginning
	if calc_time() > 0.0 and !MusicPlayerShinobu.is_playing():
		# dont requeue at end. need a bit of a safety window bc of buffers
		if calc_time() + 1.0 < MusicPlayerShinobu.get_length():
			MusicPlayerShinobu.play(calc_time())
	
	update_notes()

# also called by the editor
func update_notes():
	# update all the notes (recursive)
	for nh in notes.get_children():
		nh.update(timer)


#  do bpm and soflan math. mostly called by the editor at initialize time
# but probably still belongs here
func calculate_offset_at(frac_time: Fraction):
	#return frac_time.as_float() * 60.0 / bpms[0][1]
	var offset = 0.0
	var bpmi = 0
	
	# add bpm chunks
	while bpmi + 1 < bpms.size() and bpms[bpmi + 1][0] <= frac_time.base:
		offset += (bpms[bpmi+1][0] - bpms[bpmi][0]) * 60.0 / bpms[bpmi][1]
		bpmi += 1
	offset += frac_time.subtracted(Fraction.new(bpms[bpmi][0])).as_float() * 60.0 / bpms[bpmi][1]
	
	return offset

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


func calc_time():
	return timer + (hard_play_offset + chart_play_offset)
