extends Control

@onready var play_button: Button = $Center/Panel/Margin/Content/PlayButton
@onready var settings_button: Button = $Center/Panel/Margin/Content/SettingsButton
@onready var quit_button: Button = $Center/Panel/Margin/Content/QuitButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	play_button.grab_focus()

func _on_play_button_pressed() -> void:
	MenuNavigation.open_level_select()

func _on_settings_button_pressed() -> void:
	MenuNavigation.open_settings(MenuNavigation.MAIN_MENU)

func _on_quit_button_pressed() -> void:
	MenuNavigation.request_quit()

func navigate_back() -> void:
	MenuNavigation.request_quit()
