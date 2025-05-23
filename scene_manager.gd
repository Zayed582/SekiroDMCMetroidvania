extends Node

var scenes : Dictionary = { "Room1": "res://Room1.tscn",
							"Room2": "res://Room2.tscn" }




func transition_to_scene(level : String):
	var scene_path : String = scenes.get(level)
	
	if scene_path != null:
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file(scene_path)
