## just loops the song preview every time the timer runs out
extends Node

@onready var timer = $Timer

var offs: float

func _ready():
	timer.connect("timeout", _loop)
	

func start(offset: float):
	offs = offset
	_loop()

func _loop():
	MusicPlayerShinobu.play(offs)
	timer.start()
