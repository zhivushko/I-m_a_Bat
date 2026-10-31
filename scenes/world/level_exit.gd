extends Area2D

@export var current_level_index: int = 1

@onready var color_rect: ColorRect = $ColorRect

var is_activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_activated:
		return

	if body.is_in_group("player") or body is CharacterBody2D or body.name == "Player":
		is_activated = true

		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if color_rect:
			tween.tween_property(color_rect, "color", Color(2.0, 2.0, 2.0, 1.0), 0.3)

		tween.chain().tween_callback(func():
			GameManager.complete_level(current_level_index)
		)
