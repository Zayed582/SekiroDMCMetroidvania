extends Camera2D

@export var shake_intensity: float = 5.0
@export var shake_duration: float = 0.3

var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	original_offset = offset
	GameManager.connect("shake_camera", start_shake)

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		offset = original_offset + shake_offset
	else:
		offset = original_offset  # Reset position when done

func start_shake(duration: float = 0.3, intensity: float = 5.0):
	shake_duration = duration
	shake_intensity = intensity
	shake_timer = duration
