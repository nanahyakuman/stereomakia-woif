extends Node

var port = 0

const weak_mult = .6

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		port = event.device

# this doesn't catch godot killing the game sadly
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Input.stop_joy_vibration(port)

func drop_combo():
	Input.start_joy_vibration(port, 1, 1, .25)

func absolute():
	Input.start_joy_vibration(port, weak_mult, 1, .05)

func circle_tap(is_right: bool):
	if is_right:
		Input.start_joy_vibration(port,weak_mult,0,.07)
	else:
		Input.start_joy_vibration(port,0,1,.07)

func circle_release(is_right: bool):
	if is_right:
		Input.start_joy_vibration(port,weak_mult,0,.07)
	else:
		Input.start_joy_vibration(port,0,1,.07)
