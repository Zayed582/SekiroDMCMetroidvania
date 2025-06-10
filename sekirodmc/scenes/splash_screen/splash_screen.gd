extends Control

@export var next_scene: PackedScene


func navigate_to_next_scene():
	if next_scene: get_tree().change_scene_to_packed(next_scene)
	pass
