extends VBoxContainer

const LOG_MESSAGE = preload("res://log_message.tscn")

# add them in the right position
@onready var dummy: Control = $Dummy

func new_msg(msg: String):
	var m = LOG_MESSAGE.instantiate()
	dummy.add_sibling(m)
	m.set_msg(msg)
