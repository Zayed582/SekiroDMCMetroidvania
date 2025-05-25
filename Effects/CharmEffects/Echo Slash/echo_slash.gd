extends Area2D

@export var lifetime := 0.3

func _ready():
	$AnimatedSprite2D.play("slash")  # Replace with your animation name
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(1)
		if body.has_method("apply_posture_damage"):
			body.apply_posture_damage(1)
