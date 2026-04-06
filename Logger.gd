extends VBoxContainer

const LOG_MESSAGE = preload("res://log_message.tscn")

func new_msg(msg: String):
	var m = LOG_MESSAGE.instantiate()
	add_child(m)
	m.set_msg(msg)
