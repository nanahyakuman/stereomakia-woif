## illuminate these lanes when notes are incoming
extends Sprite2D

@onready var circle_tap_notes_left = $"../../Notes/CircleTapNotesLeft"
@onready var circle_tap_notes_right = $"../../Notes/CircleTapNotesRight"
@onready var note_holder = $"../.."

@export var is_right = false

const decay = 1.5

var offs = -1
var next_node = null

func _ready():
	self_modulate.a = 0.0

func _process(delta):
	var target = 0.0
	var which = circle_tap_notes_right if is_right else circle_tap_notes_left
	# use self as a break case for end of notes
	if next_node == self:
		target = 0.0
	else:
		while next_node != self and (next_node == null or next_node.is_right != is_right or next_node.calculated_offset < note_holder.calc_timer):
			offs += 1
			if offs >= which.get_child_count():
				next_node = self
				target = 0.0
			else:
				next_node = which.get_child(offs)
		
		if next_node != self and next_node.calculated_offset - 3.0 < note_holder.calc_timer:
			target = 1.0
	
	self_modulate.a = hlp.exdc(self_modulate.a, target, decay, delta)
