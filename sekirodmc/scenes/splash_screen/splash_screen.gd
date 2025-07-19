extends Control

@export var next_scene: PackedScene


func navigate_to_next_scene():
	if next_scene: 
		TransitionScene.navigate_to_scene("res://scenes/main_menu/main_menu.tscn")
		#get_tree().change_scene_to_packed(next_scene)
	pass
