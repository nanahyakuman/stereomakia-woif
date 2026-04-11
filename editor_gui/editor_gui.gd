extends Control

@onready var linear_notes: HBoxContainer = $VBoxContainer/LinearNotes

@onready var circle_note_l: CircleNoteGUI = $CircleNoteL
@onready var circle_note_r: CircleNoteGUI = $CircleNoteR


var LINEAR_KEYS = [
	TapNoteLinear.DIRS.LB,
	TapNoteLinear.DIRS.L,
	TapNoteLinear.DIRS.D,
	TapNoteLinear.DIRS.U,
	TapNoteLinear.DIRS.R,
	TapNoteLinear.DIRS.RB,
]

func _ready() -> void:
	for c in 6:
		var nam = LINEAR_KEYS[c]
		linear_notes.get_child(c).assign_dir(nam)
	
	circle_note_l.is_right = false
	circle_note_r.is_right = true

#  called every time we seek w the notes that we're hovering over.
# often empty tbf
func update_hovered_notes(notes: Array):
	# clear old notes
	for c in 6:
		linear_notes.get_child(c).clear()
	
	circle_note_l.clear()
	circle_note_r.clear()
	
	# decode note type and send it to the appropriate ui element
	for n in notes:
		if n is TapNoteLinear:
			linear_notes.get_child(LINEAR_KEYS.find(n._dir)).assign_note(n)
		
		if n is TapNoteCircular:
			if !n.is_right:
				circle_note_l.assign_note(n)
			else:
				circle_note_r.assign_note(n)
		
		if n is HoldNoteCircular:
			if !n.is_right:
				circle_note_l.assign_hold(n)
			else:
				circle_note_r.assign_hold(n)

# the editor needs these to connect off their signals
func get_linear_notes():
	return linear_notes.get_children()
