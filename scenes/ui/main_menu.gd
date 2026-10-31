extends Control

@onready var play_button: Button = $MarginContainer/VBoxContainer/MenuContainer/PlayButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/MenuContainer/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/MenuContainer/QuitButton

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_button_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/SettingsMenu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
