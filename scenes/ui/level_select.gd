extends Control

const LEVEL_NAMES := {1: "Пещера", 2: "Каменные иглы", 3: "Змеиные своды"}

@onready var level_list: VBoxContainer = $Center/Panel/Margin/Content/LevelList
@onready var back_button: Button = $Center/Panel/Margin/Content/Footer/BackButton
@onready var settings_button: Button = $Center/Panel/Margin/Content/Footer/SettingsButton

func _ready() -> void:
	back_button.pressed.connect(navigate_back)
	settings_button.pressed.connect(func(): MenuNavigation.open_settings(MenuNavigation.LEVEL_SELECT))
	setup_level_buttons()

func setup_level_buttons() -> void:
	for child in level_list.get_children():
		child.queue_free()
	for index in range(1, GameManager.max_levels + 1):
		var button := Button.new()
		button.name = "Level%d" % index
		button.custom_minimum_size = Vector2(0, 72)
		button.text = "%02d · %s" % [index, LEVEL_NAMES.get(index, "Уровень")]
		button.disabled = index > GameManager.unlocked_levels
		if button.disabled:
			button.text += " — закрыт"
		else:
			button.pressed.connect(_on_level_button_pressed.bind(index))
		level_list.add_child(button)
	level_list.get_child(0).grab_focus()

func _on_level_button_pressed(level_index: int) -> void:
	GameManager.load_level(level_index)

func navigate_back() -> void:
	MenuNavigation.open_main_menu()
