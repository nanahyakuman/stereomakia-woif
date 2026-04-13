extends Node
class_name TitleScreenRoot

signal level_select_pressed
signal sync_pressed
signal settings_pressed
signal editor_pressed

func _on_level_select_button_pressed() -> void:
	emit_signal("level_select_pressed")

func _on_sync_button_pressed() -> void:
	emit_signal("sync_pressed")

func _on_settings_button_pressed() -> void:
	emit_signal("settings_pressed")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_editor_button_pressed() -> void:
	emit_signal("editor_pressed")
