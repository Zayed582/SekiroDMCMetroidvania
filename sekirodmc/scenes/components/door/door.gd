extends Area2D


var level_completed = true




func _on_body_entered(body):
	if level_completed:
		GameManager.current_level += 1
		body.stop_process = true
		body.set_process(false)
		body.set_physics_process(false)
		body.velocity = Vector2.ZERO
		GameManager.move_to_next_level()
	pass # Replace with function body.
