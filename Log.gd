extends Label

var decay = .01

var timer = 0.0
var time = 3.0

func set_msg(msg: String):
	text = msg
	timer = time

func _process(delta):
	timer -= delta
	modulate.a = clamp(timer, 0.0, 1.0)
	if modulate.a < 0.0:
		queue_free()
