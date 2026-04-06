##  multiplies all the node's alphas every beat
extends Node

@onready var note_holder = $".."

@export var nodes: Array[Node2D]
@export var cnodes: Array[Control]

const min = .8
const decay = 25

var mod = 1.0

func _ready():
	note_holder.connect("beat_passed", _pulse)

func _process(delta):
	mod = hlp.exdc(mod, min, decay, delta)
	for n in nodes:
		n.self_modulate.a = mod
	for n in cnodes:
		n.self_modulate.a = mod

func _pulse(_timer):
	mod = 1.0
