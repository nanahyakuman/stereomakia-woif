## indicator class
#  these handle their own logic about being pressed or not,
# and displaying that to the screen. they don't actually score though,
# that's handled by the input manager
extends Palettizer

@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var hold_asp = $HoldASP

const LIGHT_TAP = preload("res://audio/sfx/1/tap.wav")
const HEAVY_TAP = preload("res://audio/sfx/1/crit tap.wav")

const pressed_vis = .8
const double_held_vis = .6
const half_held_vis = .4
const decay = 15
const release_time = .100 # grace release

var pressed: int = 0
var just_pressed = false
var release_timer = 0.0

#  tracks whether there's currently a hold on this lane, so we can
# play the hold sound. only ever modified by the `InputManager`
var requested = -1.0

func _ready():
	modulate.a = 0.0
	super()

func _process(delta):
	var target = 0.0
	if just_pressed:
		modulate.a = pressed_vis
		target = pressed_vis
		just_pressed = false
	elif pressed >= 2:
		target = double_held_vis
	elif pressed == 1:
		target = half_held_vis
	modulate.a = hlp.exdc(modulate.a, target, decay, delta)
	
	# hold logic, allow notes to be let go for a sec
	if pressed > 0:
		release_timer = release_time
	else:
		release_timer -= delta
	
	#  audio. requested is set to a hold's length every time a hold
	# is started
	_play_hold(pressed > 0 and requested > 0.0)
	requested -= delta

func report_press():
	pressed += 1
	just_pressed = true
func report_release():
	pressed -= 1

# use this to check if the note is held, adds a safe release window
func is_held():
	return release_timer > 0.0

#  play a hitsound. doing this thorough the indicator makes the
# panning responsive
func play_sound(is_absolute: bool):
	audio_stream_player_2d.stream = HEAVY_TAP if is_absolute else LIGHT_TAP
	audio_stream_player_2d.play()
	

func _play_hold(val: bool):
	hold_asp.volume_db = -12.0 if val else -80.0
