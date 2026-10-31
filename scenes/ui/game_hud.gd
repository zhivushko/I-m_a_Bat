extends Control

@onready var pause_panel: Control = $PausePanel
@onready var resume_button: Button = $PausePanel/Center/Panel/Margin/Buttons/Resume
@onready var restart_button: Button = $PausePanel/Center/Panel/Margin/Buttons/Restart
@onready var levels_button: Button = $PausePanel/Center/Panel/Margin/Buttons/Levels
@onready var settings_button: Button = $PausePanel/Center/Panel/Margin/Buttons/Settings
@onready var main_menu_button: Button = $PausePanel/Center/Panel/Margin/Buttons/MainMenu
@onready var pause_button: Button = $PauseButton
@onready var charge_bar: PanelContainer = $SonarChargeBar

var owns_pause: bool = false
var player: CharacterBody2D

func _ready() -> void:
	resized.connect(_update_layout)
	resume_button.pressed.connect(_resume)
	restart_button.pressed.connect(_restart)
	levels_button.pressed.connect(_open_levels)
	settings_button.pressed.connect(_open_settings)
	main_menu_button.pressed.connect(_open_main_menu)
	pause_button.pressed.connect(_open_pause)
	_update_layout()

func bind_player(target: CharacterBody2D) -> void:
	player = target
	player.sonar_charges_changed.connect(charge_bar.set_charges)
	player.sonar_blocked.connect(charge_bar.flash_empty)
	charge_bar.set_charges(player.sonar_charges, player.get_sonar_recharge_progress())

func _process(_delta: float) -> void:
	var blocked: bool = not is_instance_valid(player) or player.get("is_dead") == true
	blocked = blocked or (get_tree().paused and not owns_pause)
	visible = not blocked
	pause_button.disabled = blocked or owns_pause

func _update_layout() -> void:
	var ui_scale := clampf(minf(size.x, size.y) / 720.0, 0.8, 1.15)
	charge_bar.scale = Vector2.ONE * ui_scale
	charge_bar.position = Vector2((size.x - charge_bar.size.x * ui_scale) * 0.5, 28.0 * ui_scale)
	pause_button.size = Vector2.ONE * 48.0 * ui_scale
	pause_button.position = Vector2(size.x - 78.0 * ui_scale, 30.0 * ui_scale)
	pause_button.add_theme_font_size_override("font_size", roundi(24.0 * ui_scale))

func _open_pause() -> void:
	owns_pause = true
	pause_panel.show()
	get_tree().paused = true
	resume_button.grab_focus()

func _resume() -> void:
	pause_panel.hide()
	owns_pause = false
	get_tree().paused = false

func _restart() -> void:
	_resume()
	MenuNavigation.go_to_scene(get_tree().current_scene.scene_file_path)

func _open_levels() -> void:
	_resume()
	MenuNavigation.open_level_select()

func _open_main_menu() -> void:
	_resume()
	MenuNavigation.open_main_menu()

func _open_settings() -> void:
	pause_panel.hide()
	MenuNavigation.open_pause_settings(self)

func restore_pause_menu() -> void:
	pause_panel.show()
	settings_button.grab_focus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(player) and not get_tree().paused and not player.get("is_dead"):
		_open_pause()

func _exit_tree() -> void:
	if owns_pause:
		get_tree().paused = false
