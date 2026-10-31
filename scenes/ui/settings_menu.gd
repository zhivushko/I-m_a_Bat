extends Control

@onready var back_button: Button = $MarginContainer/VBoxContainer/Header/BackButton
@onready var volume_slider: HSlider = $MarginContainer/VBoxContainer/SettingsList/VolumeContainer/VolumeSlider
@onready var fullscreen_toggle: CheckButton = $MarginContainer/VBoxContainer/SettingsList/FullscreenContainer/FullscreenToggle

var master_bus_index: int = 0

func _ready() -> void:
	master_bus_index = AudioServer.get_bus_index("Master")

	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

	if volume_slider:
		var current_db = AudioServer.get_bus_volume_db(master_bus_index)
		volume_slider.value = db_to_linear(current_db)
		volume_slider.value_changed.connect(_on_volume_changed)

	if fullscreen_toggle:
		var mode = DisplayServer.window_get_mode()
		fullscreen_toggle.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

func _on_volume_changed(value: float) -> void:
	var db_val = linear_to_db(value)
	AudioServer.set_bus_volume_db(master_bus_index, db_val)

func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
