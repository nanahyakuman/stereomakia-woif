extends PanelContainer
class_name CircleNoteGUI

@onready var angle_spin_box: SpinBox = $VBoxContainer/HBoxContainer/AngleSpinBox
@onready var angle_h_slider: HSlider = $VBoxContainer/AngleHSlider
@onready var tap_box: CheckBox = $VBoxContainer/HBoxContainer2/TapBox
@onready var release_box: CheckBox = $VBoxContainer/HBoxContainer2/ReleaseBox
@onready var prev_box: CheckBox = $VBoxContainer/PrevBox

signal ui_erase_request
signal ui_add_circle_tap_request
signal ui_add_circle_hold_request
signal ui_add_circle_release_request

@export var is_right: bool

var note: TapNoteCircular # ( or ReleaseNoteCircular, it's an inheriter)
var hold_note: HoldNoteCircular

func _ready() -> void:
	# ready has weird interactions often so manually force both
	clear()

func clear() -> void:
	note = null
	hold_note = null
	
	# clear the boxes
	tap_box.set_pressed_no_signal(false)
	release_box.set_pressed_no_signal(false)
	prev_box.set_pressed_no_signal(false)

# called by editor
func assign_note(n):
	note = n
	
	var is_release = note is ReleaseNoteCircular
	tap_box.set_pressed_no_signal(!is_release)
	release_box.set_pressed_no_signal(is_release)
	
	_on_angle_changed(rad_to_deg(note._dir), true)

func assign_hold(h):
	hold_note = h
	prev_box.set_pressed_no_signal(true)

# connected to by both the box and the slider
func _on_angle_changed(value: float, mute_update: bool = false) -> void:
	angle_spin_box.set_value_no_signal(value)
	angle_h_slider.set_value_no_signal(value)
	
	if !mute_update:
		if note:
			note._dir = deg_to_rad(value) # ugly access i nkow, idr why _dir is underlined
			note.update(note.calculated_offset)
			if note.next_hold:
				note.next_hold.start_dir = deg_to_rad(value)
				note.next_hold.update(note.next_hold.calculated_offset)
		if hold_note:
			hold_note.new_dir = deg_to_rad(value)
			hold_note.update(hold_note.calculated_offset+hold_note.calculated_len)
			if hold_note.next_hold:
				hold_note.next_hold.start_dir = deg_to_rad(value)
				hold_note.next_hold.update(hold_note.calculated_offset+hold_note.calculated_len)


func _on_tap_box_toggled(toggled_on: bool) -> void:
	_add_tap_or_release(toggled_on, true)

func _on_release_box_toggled(toggled_on: bool) -> void:
	_add_tap_or_release(toggled_on, false)

# these are actually the same thing with minorly diff logic
func _add_tap_or_release(toggled_on: bool, is_tap: bool):
	if toggled_on:
		#  figure out our dir. try to connect to existing things
		# first
		var dir = 0.0
		if note:
			dir = note._dir
		elif hold_note:
			dir = hold_note.new_dir
		else:
			dir = deg_to_rad(angle_spin_box.value)
		
		# kill the old note
		emit_signal("ui_erase_request", note)
		release_box.set_pressed_no_signal(false)
		
		# add new note
		var sig = "ui_add_circle_tap_request" if is_tap else "ui_add_circle_release_request"
		emit_signal(sig, is_right, dir)
		#  this will work because the new note is assigned to us
		# as part of the above signal
		note.update(note.calculated_offset)
	
	# if we're toggling off, just kill our note
	else:
		emit_signal("ui_erase_request", note)


func _on_prev_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		emit_signal("ui_add_circle_hold_request", is_right, deg_to_rad(angle_spin_box.value))
	else:
		#  the signal attached to this will simulate having pressed the button
		# in editor, and as such will intelligently delete instead of adding.
		#  it will also forward-delete holds (since they're linked lists
		# it's nontrivial) without requiring me to refactor the deleter code
		emit_signal("ui_add_circle_hold_request", is_right, deg_to_rad(angle_spin_box.value))
