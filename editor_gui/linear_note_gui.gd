extends PanelContainer
class_name LinearNoteGUI

@onready var exists_button: Button = $VBoxContainer/ExistsButton
@onready var hold_toggle: CheckBox = $VBoxContainer/Specifics/HoldToggle
@onready var specifics: VBoxContainer = $VBoxContainer/Specifics
@onready var frac_editor: FracEditor = $VBoxContainer/Specifics/FracEditor
@onready var absolute_button: CheckBox = $VBoxContainer/Specifics/HBoxContainer/AbsoluteButton
@onready var doubled_button: CheckBox = $VBoxContainer/Specifics/HBoxContainer/DoubledButton

@onready var note_holder: Control = $"../../../../../../NoteHolder"


#  emitted on clicking the exists button, as appropriate. interpreted by
# the editor
signal ui_erase_request
signal ui_add_tap_request
signal ui_add_hold_request

var note: TapNoteLinear
var dir_index: TapNoteLinear.DIRS

func _ready() -> void:
	# hide
	exists_button.set_pressed_no_signal(false)
	_on_exists_button_toggled(false)
	
	hold_toggle.set_pressed_no_signal(false)
	frac_editor.set_enabled(false)

#  just renames the button to make sense at runtime &
# remembers the index
func assign_dir(index: TapNoteLinear.DIRS):
	exists_button.text = TapNoteLinear.DIRS.keys()[index]
	dir_index = index

func assign_note(_n: TapNoteLinear):
	exists_button.set_pressed_no_signal(true)
	specifics.visible = true
	
	# assign all buttons
	absolute_button.button_pressed = _n._absolute
	doubled_button.button_pressed = _n._doubled
	
	if _n.associated_hold != null:
		hold_toggle.set_pressed_no_signal(true)
		frac_editor.set_enabled(true)
		frac_editor.assign(_n.associated_hold.len_frac)
	
	note = _n

func clear():
	exists_button.set_pressed_no_signal(false)
	specifics.visible = false
	
	note = null
	
	# deassign all buttons
	absolute_button.button_pressed = false
	doubled_button.button_pressed = false

#  when pressed manually, emit signals for the editor to process.
# this isn't meant to be a serious editing mode but is nice for
# consistencey and people editing w/o a controller ig
func _on_exists_button_toggled(toggled_on: bool) -> void:
	specifics.visible = toggled_on
	if !toggled_on:
		emit_signal("ui_erase_request", note)
	else:
		emit_signal("ui_add_tap_request", dir_index)

func _on_hold_toggle_toggled(toggled_on: bool) -> void:
	frac_editor.set_enabled(toggled_on)
	if toggled_on:
		emit_signal("ui_add_hold_request", dir_index, note, frac_editor.fraction)
	else:
		emit_signal("ui_erase_request", note.associated_hold)
		note.associated_hold = null
	assign_note(note)
	# not rlly sure why we have to do this but we do
	hold_toggle.set_pressed_no_signal(toggled_on)

#  the reference to the note holder feels dangly but it's easiest like this
func _on_hold_frac_changed(len: Fraction) -> void:
	var len_s = note_holder.calculate_offset_at(note.frac.added(len)) - (note_holder.calculate_offset_at(note.frac))
	note.associated_hold.set_len(len_s, len)

func _on_absolute_button_toggled(toggled_on: bool) -> void:
	if note:
		note.set_absolute(toggled_on)

func _on_doubled_button_toggled(toggled_on: bool) -> void:
	if note:
		note.set_doubled(toggled_on)
