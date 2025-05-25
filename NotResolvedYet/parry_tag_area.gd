extends Area2D
class_name ParryTagArea

@export var is_parryable := false

func _process(delta):
	if Engine.is_editor_hint():
		return
	if is_parryable:
		modulate = Color(1, 1, 1, 1)  # Full white
	else:
		modulate = Color(1, 1, 1, 0.2)  # Dimmed when inactive
