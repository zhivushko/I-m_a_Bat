extends CanvasLayer

@onready var bg_overlay: ColorRect = $BgOverlay
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var time_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TimeLabel
@onready var next_level_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NextLevelButton
@onready var restart_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var menu_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MenuButton

var current_level_index: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if next_level_button:
		next_level_button.pressed.connect(_on_next_level_button_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)

func setup_screen(level_index: int, elapsed_time: float) -> void:
	current_level_index = level_index

	if time_label:
		time_label.text = "Время: " + format_time(elapsed_time)

	var is_final_level = (level_index >= GameManager.max_levels)

	if title_label:
		if is_final_level:
			title_label.text = "🏆 Поздравляем!\nИгра пройдена!"
		else:
			title_label.text = "Уровень " + str(level_index) + " пройден!"

	if next_level_button:
		if is_final_level:
			next_level_button.text = "В главное меню"
		else:
			next_level_button.text = "Следующий уровень"

	animate_appearance()

func animate_appearance() -> void:
	if bg_overlay:
		bg_overlay.color = Color(0, 0, 0, 0)
		var bg_tween = create_tween()
		bg_tween.tween_property(bg_overlay, "color", Color(0, 0, 0, 0.75), 0.4)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if panel_container:
		panel_container.scale = Vector2(0.7, 0.7)
		panel_container.pivot_offset = panel_container.size / 2.0
		panel_container.modulate.a = 0.0
		var panel_tween = create_tween().set_parallel(true)
		panel_tween.tween_property(panel_container, "scale", Vector2.ONE, 0.4)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		panel_tween.tween_property(panel_container, "modulate:a", 1.0, 0.3)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	var msecs = int((seconds - int(seconds)) * 100)
	return "%02d:%02d.%02d" % [mins, secs, msecs]

func _on_next_level_button_pressed() -> void:
	get_tree().paused = false
	if current_level_index >= GameManager.max_levels:
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	else:
		GameManager.complete_level(current_level_index)
	queue_free()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	GameManager.load_level(current_level_index)
	queue_free()

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")
	queue_free()
