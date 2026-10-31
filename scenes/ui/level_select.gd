extends Control

@onready var level_grid: GridContainer = $MarginContainer/VBoxContainer/GridContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/Header/BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	setup_level_buttons()

func setup_level_buttons() -> void:
	var unlocked = GameManager.unlocked_levels
	var total_levels = GameManager.max_levels

	for child in level_grid.get_children():
		child.queue_free()

	for lvl in range(1, total_levels + 1):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 120)
		btn.add_theme_font_size_override("font_size", 28)

		if lvl <= unlocked:
			btn.text = "Уровень " + str(lvl)
			btn.disabled = false
			btn.modulate = Color.WHITE
			btn.pressed.connect(func(): _on_level_button_pressed(lvl))
		else:
			btn.text = "🔒 " + str(lvl)
			btn.disabled = true
			btn.modulate = Color(1.0, 1.0, 1.0, 0.4)

		level_grid.add_child(btn)

func _on_level_button_pressed(level_index: int) -> void:
	GameManager.load_level(level_index)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
