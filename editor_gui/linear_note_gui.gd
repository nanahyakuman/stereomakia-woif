extends PanelContainer

@onready var exists_button: Button = $VBoxContainer/ExistsButton
@onready var hold_toggle: CheckBox = $VBoxContainer/Specifics/HoldToggle
@onready var specifics: VBoxContainer = $VBoxContainer/Specifics
@onready var frac_editor: HBoxContainer = $VBoxContainer/Specifics/FracEditor
@onready var absolute_button: CheckBox = $VBoxContainer/Specifics/HBoxContainer/AbsoluteButton
@onready var doubled_button: CheckBox = $VBoxContainer/Specifics/HBoxContainer/DoubledButton

@onready var frac_edits = [
	$VBoxContainer/Specifics/FracEditor/SpinBox,
	$VBoxContainer/Specifics/FracEditor/VBoxContainer/SpinBox2,
	$VBoxContainer/Specifics/FracEditor/VBoxContainer/SpinBox3
]

var note: TapNoteLinear

func _ready() -> void:
	# hide
	exists_button.button_pressed = false
	_on_exists_button_toggled(false)
	hold_toggle.button_pressed = false
	_on_hold_toggle_toggled(false)

# just renames the button to make sense at runtime
func rename(str: String):
	exists_button.text = str


func assign_note(_n: TapNoteLinear):
	exists_button.button_pressed = true
	
	# assign all buttons
	absolute_button.button_pressed = _n._absolute
	doubled_button.button_pressed = _n._doubled
	
	note = _n

func clear():
	exists_button.button_pressed = false
	note = null
	
	# deassign all buttons
	absolute_button.button_pressed = false
	doubled_button.button_pressed = false


func _on_exists_button_toggled(toggled_on: bool) -> void:
	specifics.visible = toggled_on

func _on_hold_toggle_toggled(toggled_on: bool) -> void:
	for f in frac_edits:
		f.editable = toggled_on

func _on_absolute_button_toggled(toggled_on: bool) -> void:
	if note:
		note.set_absolute(toggled_on)

func _on_doubled_button_toggled(toggled_on: bool) -> void:
	if note:
		note.set_doubled(toggled_on)
