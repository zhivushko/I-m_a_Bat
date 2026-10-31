extends Control

@onready var play_button: Button = $MarginContainer/VBoxContainer/MenuContainer/PlayButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/MenuContainer/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/MenuContainer/QuitButton
@onready var title: Label = $MarginContainer/VBoxContainer/LogoTexture/TitleLabel

func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	resized.connect(_update_layout)
	_update_layout()
	play_button.grab_focus()

func _update_layout() -> void:
	$Background.offset_left = -size.y
	var margin := mini(66, int(size.x * 0.052))
	$MarginContainer.add_theme_constant_override("margin_left", margin)
	$MarginContainer.add_theme_constant_override("margin_right", margin)
	var available := maxf(1.0, size.x - margin * 2.0)
	$MarginContainer/VBoxContainer/MenuContainer.custom_minimum_size.x = minf(312.0, available)
	var font := title.get_theme_font("font")
	var text_width := font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54).x
	title.add_theme_font_size_override("font_size", clampi(floori(54.0 * available / maxf(1.0, text_width)), 12, 54))

func _on_play_button_pressed() -> void:
	MenuNavigation.open_level_select()

func _on_settings_button_pressed() -> void:
	MenuNavigation.open_settings(MenuNavigation.MAIN_MENU)

func _on_quit_button_pressed() -> void:
	MenuNavigation.request_quit()

func navigate_back() -> void:
	MenuNavigation.request_quit()
