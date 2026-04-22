extends Node

var port = 0
const weak_mult = .65

class HapticInfo:
	var timer: float = -1.0
	var strength: float = 1.0

# `is_right` indexed
var haptics: Array[HapticInfo] = [HapticInfo.new(), HapticInfo.new()]

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		port = event.device


func _process(delta: float) -> void:
	var strengths = []
	for h in haptics:
		if h.timer > 0.0:
			h.timer -= delta
			strengths.append(h.strength)
		else:
			strengths.append(0.0)
	
	Input.start_joy_vibration(port, strengths[1], strengths[0])

#  queue a vibration that WONT be interrupted! so if you start a strong 3s vibe
# and a second later start a weak 3s vibe, there'll be 1s strong 2s both 1s weak,
# instead of the latter overriding the former.
#  has an unfortunate side effect of limiting the vibe poll rate to the frame
#  rate but what can you do
func _queue_vibration(weak_mag: float, strong_mag: float, duration: float):
	var strengths = [strong_mag, weak_mag]
	for i in 2:
		var h = haptics[i]
		var strength = strengths[i]
		if h.timer < 0.0 or strength > h.strength:
			h.strength = strength
			h.timer = duration

# called externally by various
func drop_combo():
	_queue_vibration(1, 1, .25)
func absolute():
	_queue_vibration(weak_mult, 1, .06)
func double_absolute():
	_queue_vibration(weak_mult, 1, .09)
func circle_tap(is_right: bool):
	if is_right:
		_queue_vibration(weak_mult,.7,.07)
	else:
		_queue_vibration(weak_mult*.7,1,.07)
func circle_release(is_right: bool):
	circle_tap(is_right)
func circle_hold(is_right: bool): # the two circle indicators call this one. weird
	if is_right:
		_queue_vibration(.3,0,.1)
	else:
		_queue_vibration(0,.2,.1)

# this doesn't catch godot killing the game sadly
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Input.stop_joy_vibration(port)
		set_process(false)
