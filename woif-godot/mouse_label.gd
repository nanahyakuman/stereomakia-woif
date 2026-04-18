## a text box that hovers on the mouse.
extends Node2D

@onready var label: Label = $Node2D/PanelContainer/Label

class TextSetPair:
	var text: String
	var who: Node
	
	func _init(_text, _who):
		text = _text
		who = _who

var texts: Array[TextSetPair] = []

func _process(_delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		visible = false
		return
	
	position = get_viewport().get_mouse_position()
	
	if texts.size() > 0:
		label.text = texts.back().text
		visible = true
	else:
		visible = false

func set_text(msg: String, by: Node):
	texts.append(TextSetPair.new(msg, by))

func release_text(by: Node):
	for t in texts:
		if t.who == by:
			texts.erase(t)
