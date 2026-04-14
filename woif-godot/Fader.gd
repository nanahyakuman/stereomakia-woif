extends ColorRect

@onready var end_timer = $EndTimer

func _ready():
	#music_player.connect("finished", _fade)
	self_modulate.a = 0.0

func fade():
	if end_timer.is_stopped():
		end_timer.start()

func _process(delta):
	if !end_timer.is_stopped():
		self_modulate.a = 1.0 - end_timer.time_left / end_timer.wait_time
