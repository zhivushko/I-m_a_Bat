extends Control

@onready var back_button: Button = $Center/Panel/Margin/Content/BackButton
@onready var volume_slider: HSlider = $Center/Panel/Margin/Content/VolumeSlider
@onready var volume_value: Label = $Center/Panel/Margin/Content/VolumeHeader/VolumeValue
@onready var fullscreen_toggle: Button = $Center/Panel/Margin/Content/FullscreenToggle

var is_pause_overlay: bool = false
var master_bus_index: int = 0

func _ready() -> void:
	master_bus_index = AudioServer.get_bus_index("Master")
	back_button.pressed.connect(navigate_back)
	volume_slider.value = 0.0 if AudioServer.is_bus_mute(master_bus_index) else db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	_update_volume_label(volume_slider.value)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_toggle.visible = not OS.has_feature("mobile")
	var mode := DisplayServer.window_get_mode()
	fullscreen_toggle.button_pressed = mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	_update_fullscreen_label()
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	if is_pause_overlay:
		$Background.color = Color(0, 0, 0, 0.86)
		$BackgroundArt.hide()
		back_button.text = "Назад к паузе"
	resized.connect(_update_background)
	_update_background()
	back_button.grab_focus()

func _update_background() -> void:
	$BackgroundArt.offset_left = -size.y

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_mute(master_bus_index, value <= 0.001)
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(maxf(value, 0.0001)))
	_update_volume_label(value)

func _update_volume_label(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value * 100.0)

func _on_fullscreen_toggled(enabled: bool) -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	_update_fullscreen_label()

func _update_fullscreen_label() -> void:
	fullscreen_toggle.text = "Полный экран: " + ("вкл." if fullscreen_toggle.button_pressed else "выкл.")

func navigate_back() -> void:
	MenuNavigation.close_settings()
