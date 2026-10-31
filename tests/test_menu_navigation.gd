# Run: Godot --headless --path . --fixed-fps 60 --audio-driver Dummy --script res://tests/test_menu_navigation.gd
extends SceneTree

const THEME: Theme = preload("res://scenes/ui/menu_theme.tres")
var failed: bool = false
var navigation: Node

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failed = true
		push_error(message)

func settle() -> void:
	for frame in range(5):
		await process_frame

func tap(button: Button) -> void:
	var point := root.get_final_transform() * button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 20
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await settle()

func escape() -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.physical_keycode = KEY_ESCAPE
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await settle()

func uses_shared_theme(button: Button) -> bool:
	return button.get_theme_stylebox("normal") == THEME.get_stylebox("normal", "Button")

func completion_screen() -> Node:
	for child in root.get_children():
		if child.has_method("setup_screen"):
			return child
	return null

func show_completion(level: int) -> Node:
	root.get_node("GameManager").load_level(level)
	await settle()
	current_scene.get_node("Player").set_physics_process(false)
	current_scene.get_node("LevelExit").trigger_level_complete()
	await settle()
	return completion_screen()

func run() -> void:
	root.size = Vector2i(1280, 720)
	navigation = root.get_node("MenuNavigation")
	root.get_node("GameManager").unlocked_levels = 1
	navigation.open_main_menu()
	await settle()
	check(uses_shared_theme(current_scene.play_button), "Main menu adopts the dark outlined theme")
	await tap(current_scene.settings_button)
	check(current_scene.scene_file_path.ends_with("SettingsMenu.tscn"), "Main menu opens Settings by touch")
	current_scene.volume_slider.value = 0.0
	check(AudioServer.is_bus_mute(0) and current_scene.volume_value.text == "0%", "Volume zero reliably mutes the game")
	current_scene.volume_slider.value = 0.37
	check(not AudioServer.is_bus_mute(0) and current_scene.volume_value.text == "37%", "Settings update the audio and percentage together")
	await tap(current_scene.back_button)
	check(current_scene.scene_file_path.ends_with("MainMenu.tscn"), "Settings opened from Main return to Main")
	await tap(current_scene.settings_button)
	check(is_equal_approx(current_scene.volume_slider.value, 0.37), "The selected volume survives screen changes")
	await escape()
	check(current_scene.scene_file_path.ends_with("MainMenu.tscn"), "Escape follows the same Settings back route")
	await tap(current_scene.play_button)
	check(current_scene.scene_file_path.ends_with("LevelSelect.tscn"), "Play opens the level list")
	check(current_scene.level_list.get_node("Level2").disabled, "Locked levels remain inaccessible")
	check(uses_shared_theme(current_scene.level_list.get_node("Level1")), "Generated level buttons share the menu theme")
	await tap(current_scene.level_list.get_node("Level2"))
	check(current_scene.scene_file_path.ends_with("LevelSelect.tscn"), "Touching a locked level does not enter it")
	await tap(current_scene.settings_button)
	navigation.notification(navigation.NOTIFICATION_WM_GO_BACK_REQUEST)
	await settle()
	check(current_scene.scene_file_path.ends_with("LevelSelect.tscn"), "System Back returns Settings to the originating level list")
	await escape()
	check(current_scene.scene_file_path.ends_with("MainMenu.tscn"), "Level list Back returns to Main")
	await tap(current_scene.quit_button)
	check(is_instance_valid(navigation.quit_overlay), "Quit opens a styled confirmation instead of closing immediately")
	await escape()
	check(not is_instance_valid(navigation.quit_overlay), "Back cancels the exit confirmation")
	await tap(current_scene.quit_button)
	await tap(navigation.quit_overlay.get_child(0).get_node("Center/Panel/Margin/Buttons/Cancel"))
	check(not is_instance_valid(navigation.quit_overlay), "The confirmation Cancel button also returns to Main")
	await tap(current_scene.play_button)
	await tap(current_scene.level_list.get_node("Level1"))
	check(current_scene.scene_file_path.ends_with("level_1.tscn") and not paused, "Selecting an unlocked level starts gameplay")
	await escape()
	var controls = current_scene.get_node("UI/MobileControls")
	check(paused and controls.owns_pause, "Escape opens the same pause menu as the touch button")
	check(uses_shared_theme(controls.resume_button) and uses_shared_theme(controls.settings_button), "Pause uses the same theme as every full-screen menu")
	var scene_id: int = current_scene.get_instance_id()
	var position_before: Vector2 = current_scene.get_node("Player").position
	var time_before: float = current_scene.level_time
	await tap(controls.settings_button)
	check(is_instance_valid(navigation.settings_overlay) and paused and not controls.pause_panel.visible, "Pause opens Settings over the frozen game")
	var settings = navigation.settings_overlay.get_child(0)
	settings.volume_slider.value = 0.62
	await tap(settings.back_button)
	check(current_scene.get_instance_id() == scene_id and current_scene.get_node("Player").position == position_before and current_scene.level_time == time_before, "Returning from Settings preserves the level, position, and timer")
	check(paused and controls.pause_panel.visible and not is_instance_valid(navigation.settings_overlay), "Settings Back restores Pause without resuming automatically")
	await escape()
	check(not paused, "Back from Pause resumes gameplay")
	await escape()
	controls = current_scene.get_node("UI/MobileControls")
	await tap(controls.main_menu_button)
	check(current_scene.scene_file_path.ends_with("MainMenu.tscn") and not paused, "Pause can return to Main without leaving the tree paused")
	navigation.open_level_select()
	navigation.open_settings()
	await settle()
	check(current_scene.scene_file_path.ends_with("LevelSelect.tscn"), "Overlapping navigation requests cannot replace the first transition")
	root.get_node("GameManager").unlocked_levels = 3
	var screen = await show_completion(1)
	check(screen != null and uses_shared_theme(screen.next_level_button), "Completion adopts the shared theme")
	await tap(screen.next_level_button)
	check(current_scene.scene_file_path.ends_with("level_2.tscn") and not paused and completion_screen() == null, "Next level closes completion and resumes the game")
	screen = await show_completion(2)
	var old_level: int = current_scene.get_instance_id()
	await tap(screen.restart_button)
	check(current_scene.scene_file_path.ends_with("level_2.tscn") and current_scene.get_instance_id() != old_level and not paused, "Completion Restart reloads the correct level")
	screen = await show_completion(2)
	await escape()
	check(current_scene.scene_file_path.ends_with("LevelSelect.tscn") and not paused, "Completion Back returns to the level list")
	screen = await show_completion(2)
	await tap(screen.main_menu_button)
	check(current_scene.scene_file_path.ends_with("MainMenu.tscn") and not paused, "Completion has a direct working Main Menu action")
	screen = await show_completion(3)
	check(not screen.main_menu_button.visible, "Final completion avoids duplicate Main Menu actions")
	await tap(screen.next_level_button)
	check(current_scene.scene_file_path.ends_with("MainMenu.tscn") and not paused, "The final screen returns to Main")
	for path in [navigation.MAIN_MENU, navigation.LEVEL_SELECT, navigation.SETTINGS]:
		navigation.go_to_scene(path)
		await settle()
		for dimensions in [Vector2i(960, 540), Vector2i(2340, 1080), Vector2i(720, 960)]:
			root.size = dimensions
			await settle()
			var panel: Control = current_scene.get_node("Center/Panel")
			var bounds := panel.get_global_rect()
			check(Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(bounds), "Menu panel fits " + path.get_file() + " at " + str(dimensions))
	navigation.open_main_menu()
	await settle()
	current_scene.queue_free()
	await process_frame
	if not failed:
		print("ALL MENU NAVIGATION CHECKS PASSED")
	quit(1 if failed else 0)
