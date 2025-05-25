extends Area2D

@export var damage := 1
@export var lifespan := 0.3

func _ready():
	$Timer.wait_time = lifespan
	$Timer.start()
	scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), lifespan)
	tween.tween_property(self, "modulate:a", 0.0, lifespan)

func _on_Timer_timeout():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
