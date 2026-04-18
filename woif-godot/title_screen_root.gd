extends Node
class_name TitleScreenRoot

@onready var file_dialog: FileDialog = $FileDialog
@onready var level_select_button: Button = $Control/MarginContainer/VBoxContainer/LevelSelectButton

signal level_select_pressed
signal sync_pressed
signal settings_pressed
signal editor_open

func _ready() -> void:
	level_select_button.grab_focus(true)

func _on_level_select_button_pressed() -> void:
	emit_signal("level_select_pressed")

func _on_sync_button_pressed() -> void:
	emit_signal("sync_pressed")

func _on_settings_button_pressed() -> void:
	emit_signal("settings_pressed")

func _on_quit_button_pressed() -> void:
	get_tree().quit()



func _on_editor_button_pressed() -> void:
	file_dialog.popup_centered_ratio()


func _on_file_dialog_file_selected(path: String) -> void:
	var last_slash = path.rfind("/")
	var ext = path.rfind(".")
	var lvlpath = path.substr(0, last_slash)
	var chartname = path.substr(last_slash+1, ext-last_slash-1)
	
	#print(lvlpath)
	#print(chartname)
	
	emit_signal("editor_open", lvlpath, chartname, true)
