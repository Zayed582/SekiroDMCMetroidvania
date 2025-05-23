extends Node2D

func _on_exit_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var player = body as CharacterBody2D
		player.queue_free()
		
	await get_tree().create_timer(2.0).timeout
	print("scene transition")
		
