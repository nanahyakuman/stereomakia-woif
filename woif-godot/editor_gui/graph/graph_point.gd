extends Node2D
class_name GraphPoint

signal dirtied

var pair: FractionPair
var hovered: bool = false


func _on_area_mouse_entered() -> void:
	MouseLabel.set_text("%s: %.2f" % [pair.frac.as_string(), pair.val], self)
	hovered = true

func _on_area_mouse_exited() -> void:
	MouseLabel.release_text(self)
	hovered = false

func _on_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			# switch interpolation
			if event.button_index == MouseButton.MOUSE_BUTTON_MIDDLE:
				pair.interpolationMode = (pair.interpolationMode+1)%FractionPair.InterpolationMode.INTERPOLATION_MAX
				emit_signal("dirtied")
