extends Area2D

func _ready():
	$CollisionShape2D.disabled = false
	$AnimatedSprite2D.play("explode")  # Make sure the animation is named correctly
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _on_body_entered(body):
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage()

func _on_animation_finished():
	queue_free()
