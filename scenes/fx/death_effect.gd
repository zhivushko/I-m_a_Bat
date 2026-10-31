extends CanvasLayer

const DEATH_DURATION: float = 2.0
const BLACKOUT_DURATION: float = 0.2

@onready var overlay: ColorRect = $Overlay
@onready var death_sound: AudioStreamPlayer = $DeathSound

func play(screen_origin: Vector2) -> void:
	var shader: ShaderMaterial = overlay.material
	shader.set_shader_parameter("origin", screen_origin.clamp(Vector2.ZERO, Vector2.ONE))
	get_tree().paused = true
	death_sound.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_method(_set_progress, 0.0, 1.0, DEATH_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_blackout, 0.0, 1.0, BLACKOUT_DURATION)\
		.set_delay(DEATH_DURATION - BLACKOUT_DURATION).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(_restart_level)

func _set_progress(value: float) -> void:
	overlay.material.set_shader_parameter("progress", value)

func _set_blackout(value: float) -> void:
	overlay.material.set_shader_parameter("blackout", value)

func _restart_level() -> void:
	var error := get_tree().reload_current_scene()
	get_tree().paused = false
	if error != OK:
		push_error("Could not restart the level after death: ", error)
		queue_free()
		return
	var tween := create_tween()
	tween.tween_interval(0.05)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free)
