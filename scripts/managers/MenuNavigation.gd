extends Node

const MAIN_MENU := "res://scenes/ui/MainMenu.tscn"
const LEVEL_SELECT := "res://scenes/ui/LevelSelect.tscn"
const SETTINGS := "res://scenes/ui/SettingsMenu.tscn"
const QUIT_DIALOG: PackedScene = preload("res://scenes/ui/QuitConfirmation.tscn")

var busy: bool = false
var settings_return_path: String = MAIN_MENU
var settings_overlay: CanvasLayer
var settings_owner: WeakRef
var quit_overlay: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().quit_on_go_back = false

func go_to_scene(path: String) -> void:
	if busy:
		return
	busy = true
	_clear_overlays()
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		busy = false
		push_error("Could not open menu or level: ", path, " (", error, ")")
		return
	await get_tree().scene_changed
	busy = false

func open_main_menu() -> void:
	go_to_scene(MAIN_MENU)

func open_level_select() -> void:
	go_to_scene(LEVEL_SELECT)

func open_settings(return_path: String = MAIN_MENU) -> void:
	settings_return_path = return_path
	go_to_scene(SETTINGS)

func open_pause_settings(owner: Control) -> void:
	if is_instance_valid(settings_overlay) or busy:
		return
	settings_owner = weakref(owner)
	settings_overlay = CanvasLayer.new()
	settings_overlay.layer = 30
	settings_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(settings_overlay)
	var screen = load(SETTINGS).instantiate()
	screen.is_pause_overlay = true
	settings_overlay.add_child(screen)

func close_settings() -> void:
	if is_instance_valid(settings_overlay):
		settings_overlay.queue_free()
		settings_overlay = null
		var owner = settings_owner.get_ref() if settings_owner else null
		settings_owner = null
		if is_instance_valid(owner):
			owner.restore_pause_menu()
		else:
			open_level_select()
	else:
		go_to_scene(settings_return_path)

func request_quit() -> void:
	if is_instance_valid(quit_overlay) or busy:
		return
	quit_overlay = CanvasLayer.new()
	quit_overlay.layer = 50
	quit_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(quit_overlay)
	var dialog := QUIT_DIALOG.instantiate()
	quit_overlay.add_child(dialog)
	dialog.get_node("Center/Panel/Margin/Buttons/Cancel").pressed.connect(cancel_quit)
	dialog.get_node("Center/Panel/Margin/Buttons/Confirm").pressed.connect(get_tree().quit)
	dialog.get_node("Center/Panel/Margin/Buttons/Cancel").grab_focus()

func cancel_quit() -> void:
	if is_instance_valid(quit_overlay):
		quit_overlay.queue_free()
		quit_overlay = null

func back() -> void:
	if busy:
		return
	if is_instance_valid(quit_overlay):
		cancel_quit()
		return
	if is_instance_valid(settings_overlay):
		close_settings()
		return
	var scene := get_tree().current_scene
	if not scene:
		return
	if scene.has_method("navigate_back"):
		scene.navigate_back()
		return
	var player := scene.get_node_or_null("Player")
	if player and player.get("is_dead") == true:
		return
	var hud := scene.get_node_or_null("UI/GameHUD")
	if hud and hud.get("owns_pause") == true:
		hud._resume()
		return
	if get_tree().paused:
		for child in get_tree().root.get_children():
			if child.has_method("navigate_back"):
				child.navigate_back()
				return
	elif hud:
		hud._open_pause()

func _clear_overlays() -> void:
	if is_instance_valid(settings_overlay):
		settings_overlay.queue_free()
	settings_overlay = null
	settings_owner = null
	cancel_quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		back()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()
