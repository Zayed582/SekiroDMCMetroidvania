extends Control


func _on_exit_button_pressed():
	get_tree().quit()
	pass # Replace with function body.


func _on_play_game_button_pressed():
	GameManager.move_to_next_level()
	#get_tree().change_scene_to_file("res://scenes/world.tscn")
	pass # Replace with function body.
