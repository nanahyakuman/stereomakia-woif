extends Node2D

@onready var input_manager = $"../../../InputManager"
@onready var editor = $"../../../Editor"
@onready var asp = $AudioStreamPlayer2D
@onready var hold_asp = $AudioStreamPlayer2D2
@onready var hold_asp_2 = $AudioStreamPlayer2D3
@onready var note_holder = $"../.."

const pressed_vis = .6
const vis = .4
const decay = 15

const logical_active_release = .150
var active_timer = 0.0

const DOWN_TAP = preload("res://audio/sfx/1/circ off.wav")
const UP_TAP = preload("res://audio/sfx/1/circ on.wav")

# there is no decay on this when you release rn
var active: bool = false

@export var is_right = false

# whether to play the sound.
#  this is only updated every beat and half beat so theoretically
# really short holds arent updated accurately but idk if it needs to be 
# addressed rn 
var requested = -1.0
var current_hold: HoldNoteCircular = null

func _ready():
	modulate.a = 0

func _process(delta):
	var inp
	if !is_right:
		inp = Input.get_vector("stick_l_l", "stick_l_r", "stick_l_u", "stick_l_d")
	else:
		inp = Input.get_vector("stick_r_l", "stick_r_r", "stick_r_u", "stick_r_d")
	
	# modulate anims
	var prev_active = active
	active = inp.length_squared() > .5
	if !prev_active and active:
		modulate.a = pressed_vis
		rotation = inp.angle()
		input_manager.circle_pressed(is_right, rotation)
		editor.circle_pressed(is_right, rotation)
	
	if !active and prev_active:
		input_manager.circle_released(is_right, rotation)
		
	
	var target_vis = vis if active else 0.0
	modulate.a = hlp.exdc(modulate.a, target_vis, decay, delta)
	
	if active:
		# rotate
		rotation = lerp_angle(rotation, inp.angle(), min(1.0, delta * 30))
		
		# activity
		active_timer = logical_active_release
		
	
	active_timer -= delta
	
	# audio playing
	if active and requested > 0.0:
		#  this code has a weird ticking every time you cross over the 0 point,
		# i think it's an internal inconsistencey between when godot applies pitch and
		# volume settings but im not sure
		
		#  pitch is a mix of the true intended angle and the palyers input bc i wasnt
		# happy with either on its own
		var intended_angle = current_hold.calc_dir(note_holder.timer)
		var angle = lerp_angle(intended_angle, rotation, .5)
		var mix = fposmod(angle + PI * .5, TAU) / TAU 	# [0, 1)
		if is_right:
			mix = 1.0 - mix
		hold_asp.pitch_scale = 0.3 + pow((mix) * 1, 3)
		hold_asp_2.pitch_scale = 0.3 + pow((mix + 1.0) * 1, 3)
		
		# numbers made up but feel pretty good
		hold_asp.volume_db = -6 + log(mix) * 10
		hold_asp_2.volume_db = -6 + log(1.0-mix) * 10
	else:
		hold_asp.volume_db = -80.0
		hold_asp_2.volume_db = -80.0
	requested -= delta


func is_active():
	return active_timer > 0.0


# again indicators play the sound for responsive panning
func play_sound(is_down):
	asp.stream = DOWN_TAP if is_down else UP_TAP
	asp.play()
