extends Area2D

@export var current_level_index: int = 1
@export var complete_screen_scene: PackedScene = preload("res://scenes/ui/LevelCompleteScreen.tscn")

@onready var sprite: Sprite2D = $Sprite

var is_activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_activated or body.get("is_dead") == true:
		return

	if body.is_in_group("player") or body is CharacterBody2D or body.name == "Player":
		is_activated = true

		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if sprite:
			tween.tween_property(sprite, "color", Color(2.0, 2.0, 2.0, 1.0), 0.3)

		tween.chain().tween_callback(func():
			trigger_level_complete()
		)

func trigger_level_complete() -> void:
	GameManager.unlock_next_level(current_level_index)

	var elapsed_time: float = 0.0
	var root_scene = get_tree().current_scene
	if root_scene and "level_time" in root_scene:
		elapsed_time = root_scene.level_time

	if complete_screen_scene:
		var screen = complete_screen_scene.instantiate()
		get_tree().root.add_child(screen)
		if screen.has_method("setup_screen"):
			screen.setup_screen(current_level_index, elapsed_time)

	get_tree().paused = true
