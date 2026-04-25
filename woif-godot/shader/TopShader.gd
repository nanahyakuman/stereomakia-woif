extends ColorRect
class_name Filterer

@onready var scoring_manager = $"../ScoringManager"

# the damage aberration
var min = 0.75
var max = 6.0
var val = 0.0
var decay = 7

var glitch_sampler: SamplerOverTime = SamplerOverTime.new()
var invert_sampler: SamplerOverTime = SamplerOverTime.new()

func _ready():
	scoring_manager.connect("note_missed", _ping)
	val = min
	

func _process(delta):
	material.set_shader_parameter("offset", val)
	val = hlp.exdc(val, min, decay, delta)

func update(calc_time: float):
	material.set_shader_parameter("glitch_amount", glitch_sampler.at(calc_time))
	material.set_shader_parameter("invert_amount", invert_sampler.at(calc_time))

func _ping():
	val = max
