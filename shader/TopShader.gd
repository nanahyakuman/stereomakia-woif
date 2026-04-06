extends ColorRect

@onready var scoring_manager = $"../ScoringManager"

var min = 0.75
var max = 6.0
var val = 0.0
var decay = 7

func _ready():
	scoring_manager.connect("note_missed", _ping)
	val = min

func _process(delta):
	material.set_shader_parameter("offset", val);
	val = hlp.exdc(val, min, decay, delta);

func _ping():
	val = max
