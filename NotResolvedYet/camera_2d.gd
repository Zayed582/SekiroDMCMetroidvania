class_name MyCamera2D
extends Camera2D

@export var current: bool:
	get: return is_current()
	set(value):
		if value:
			make_current()

@export var target: Node2D
var shake_amount = 0.0
var original_offset = Vector2.ZERO

func _ready():
	original_offset = offset

func _process(delta):
	if target:
		global_position = target.global_position

	if shake_amount > 0:
		offset = original_offset + Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount = lerp(shake_amount, 0.0, delta * 10)
	else:
		offset = original_offset

func shake(amount: float = 5.0):
	shake_amount = amount

func set_camera_limits(room_x: int, room_y: int, room_width: int, room_height: int) -> void:
	limit_left = room_x
	limit_right = room_x + room_width
	limit_top = room_y
	limit_bottom = room_y + room_height
